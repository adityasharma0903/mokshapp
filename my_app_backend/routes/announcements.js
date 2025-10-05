// my_app_backend/routes/announcements.js

const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const multer = require('multer'); // Import multer

// ----------------------------------------------------------------------
// 1. Multer Configuration (Example: Local Storage)
// NOTE: Production apps should use S3/GCP/Azure for file storage.
// ----------------------------------------------------------------------
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // Specify the directory where files should be saved (e.g., in a 'public/uploads' folder)
        cb(null, 'public/uploads/');
    },
    filename: (req, file, cb) => {
        // Create a unique filename (e.g., uuid + original extension)
        const ext = file.originalname.split('.').pop();
        cb(null, `${uuidv4()}.${ext}`);
    }
});

const upload = multer({ storage: storage });

// ----------------------------------------------------------------------
// 2. File Upload Utility (Conceptual - Replace with your S3/Storage logic)
// ----------------------------------------------------------------------
function getPublicUrl(fileName) {
    // IMPORTANT: Replace 'http://yourdomain.com' with your actual server base URL
    // or your S3 bucket's public URL path.
    return `https://mokshapp.onrender.com/uploads/${fileName}`;
}


// Endpoint to post a new announcement
// Use upload.single('file') middleware to handle the file upload
router.post('/add', upload.single('file'), async (req, res) => {
    // req.body now contains text fields
    // req.file contains the uploaded file info if using multer
    const { title, message, posted_by } = req.body;

    // --- New Logic to get/generate the downloadable URL ---
let attachment_url = null;

if (req.file) {
    // File uploaded → generate full public URL
    attachment_url = getPublicUrl(req.file.filename);
} else if (req.body.attachment_url) {
    // Only fallback if no file uploaded
    attachment_url = req.body.attachment_url;
}

    // --- End New Logic ---

    if (!title || !message || !posted_by) {
        // If file is optional, we don't check for attachment_url here
        return res.status(400).send({ error: 'Missing required fields (title, message, posted_by).' });
    }

    const connection = await req.db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Insert into announcements table with the generated attachment_url
        const announcement_id = uuidv4();
        await connection.query(
            'INSERT INTO announcements (announcement_id, title, message, attachment_url, posted_by) VALUES (?, ?, ?, ?, ?)',
            [announcement_id, title, message, attachment_url, posted_by] // <--- Now saving the full public URL
        );

        // 2. Get all user IDs (students and teachers)
        const [userRows] = await connection.query('SELECT user_id FROM users WHERE user_type IN (?, ?)', ['student', 'teacher']);

        // 3. Insert a record for each user into user_announcements table
        for (const user of userRows) {
            const user_announcement_id = uuidv4();
            await connection.query(
                'INSERT INTO user_announcements (user_announcement_id, user_id, announcement_id) VALUES (?, ?, ?)',
                [user_announcement_id, user.user_id, announcement_id]
            );
        }

        await connection.commit();
        res.status(201).send({ message: 'Announcement posted successfully.', attachment_url: attachment_url });
    } catch (err) {
        await connection.rollback();
        console.error('Error posting announcement:', err);
        res.status(500).send({ error: 'Failed to post announcement. Transaction rolled back.' });
    } finally {
        connection.release();
    }
});


// Endpoint to get the count of unread announcements for a specific user
router.get('/unread-count/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
        const [rows] = await req.db.query(
            'SELECT COUNT(*) AS unread_count FROM user_announcements WHERE user_id = ? AND is_read = FALSE',
            [userId]
        );
        res.status(200).send(rows[0]);
    } catch (err) {
        console.error('Error fetching unread count:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

// Endpoint to mark all announcements as read for a specific user
router.put('/mark-as-read/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
        await req.db.query('UPDATE user_announcements SET is_read = TRUE WHERE user_id = ?', [userId]);
        res.status(200).send({ message: 'All announcements marked as read.' });
    } catch (err) {
        console.error('Error marking as read:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

// Endpoint to get all announcements for a user, including their read status
router.get('/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
        const query = `
            SELECT a.*, ua.is_read
            FROM announcements a
            JOIN user_announcements ua ON a.announcement_id = ua.announcement_id
            WHERE ua.user_id = ?
            ORDER BY a.created_at DESC;
        `;
        const [rows] = await req.db.query(query, [userId]);
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching announcements:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT * FROM announcements ORDER BY created_at DESC');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching announcements:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

module.exports = router;