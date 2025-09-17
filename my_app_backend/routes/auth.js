// my_app_backend/routes/auth.js

const express = require('express');
const router = express.Router();

// Login endpoint
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).send({ error: 'Email and password are required.' });
    }

    try {
        const query = `
            SELECT
                u.user_id, u.email, u.user_type, s.name AS student_name, t.name AS teacher_name
            FROM users u
            LEFT JOIN students s ON u.user_id = s.user_id
            LEFT JOIN teachers t ON u.user_id = t.user_id
            WHERE u.email = ? AND u.password_hash = ?
        `;

        const [rows] = await req.db.query(query, [email, password]);

        if (rows.length > 0) {
            const user = rows[0];
            const name = user.user_type === 'student' ? user.student_name : (user.user_type === 'teacher' ? user.teacher_name : 'Admin');

            const userData = {
                user_id: user.user_id,
                email: user.email,
                user_type: user.user_type,
                name: name
            };

            res.status(200).send(userData);
        } else {
            res.status(401).send({ error: 'Invalid email or password.' });
        }
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

module.exports = router;