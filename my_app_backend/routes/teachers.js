// my_app_backend/routes/teachers.js

const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// Endpoint to get all teachers for the admin panel
router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT * FROM teachers');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching teachers:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

// Endpoint to add a new teacher from the admin panel
router.post('/add', async (req, res) => {
    const {
        email, password_hash,
        name, dob, gender, marital_status, nationality, blood_group,
        contact_number, permanent_address, current_address, spouse_name,
        designation, photograph_url
    } = req.body;

    // Basic validation
    if (!email || !password_hash || !name || !designation) {
        return res.status(400).send({ error: 'Required fields are missing.' });
    }

    const connection = await req.db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Insert into users table
        const user_id = uuidv4();
        await connection.query(
            'INSERT INTO users (user_id, email, password_hash, user_type) VALUES (?, ?, ?, ?)',
            [user_id, email, password_hash, 'teacher']
        );

        // 2. Insert into teachers table
        const teacher_id = uuidv4();
        await connection.query(
            'INSERT INTO teachers (teacher_id, user_id, name, dob, gender, marital_status, nationality, blood_group, contact_number, email, permanent_address, current_address, spouse_name, designation, photograph_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [teacher_id, user_id, name, dob, gender, marital_status, nationality, blood_group, contact_number, email, permanent_address, current_address, spouse_name, designation, photograph_url]
        );

        await connection.commit();
        res.status(201).send({ message: 'Teacher and user created successfully.', teacher_id, user_id });

    } catch (err) {
        await connection.rollback();
        console.error('Transaction error:', err);
        res.status(500).send({ error: 'Failed to add teacher. Transaction rolled back.' });
    } finally {
        connection.release();
    }
});


router.get('/profile/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
        const query = `
            SELECT
                t.teacher_id, t.name, t.email, t.designation, t.gender, t.dob, t.marital_status,
                t.nationality, t.blood_group, t.contact_number, t.permanent_address,
                t.current_address, t.spouse_name, t.photograph_url, t.father_name, t.mother_name,
                t.academic_docs_url, t.professional_docs_url
            FROM teachers t
            WHERE t.user_id = ?
        `;
        const [rows] = await req.db.query(query, [userId]);

        if (rows.length > 0) {
            res.status(200).send(rows[0]);
        } else {
            res.status(404).send({ error: 'Teacher profile not found.' });
        }
    } catch (err) {
        console.error('Error fetching teacher profile:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


router.post('/assign-class', async (req, res) => {
    const { teacher_id, class_id, subject_id } = req.body;
    if (!teacher_id || !class_id || !subject_id) {
        return res.status(400).send({ error: 'All fields are required.' });
    }

    try {
        const assignment_id = uuidv4();
        await req.db.query(
            'INSERT INTO class_subject_assignments (assignment_id, teacher_id, class_id, subject_id) VALUES (?, ?, ?, ?)',
            [assignment_id, teacher_id, class_id, subject_id]
        );
        res.status(201).send({ message: 'Class assigned successfully.' });
    } catch (err) {
        console.error('Error assigning class:', err);
        res.status(500).send({ error: 'Failed to assign class.' });
    }
});

router.get('/classes/:teacherId', async (req, res) => {
    const teacherId = req.params.teacherId;
    try {
        const query = `
            SELECT
                c.class_id, c.class_name, c.section, s.subject_name
            FROM teachers t
            JOIN class_subject_assignments csa ON t.teacher_id = csa.teacher_id
            JOIN classes c ON csa.class_id = c.class_id
            JOIN subjects s ON csa.subject_id = s.subject_id
            WHERE t.teacher_id = ?
            ORDER BY c.class_name, c.section, s.subject_name;
        `;
        const [rows] = await req.db.query(query, [teacherId]);

        // This query can return multiple rows for the same class-section, one for each subject.
        // We'll group them for easier use in the Flutter app.
        const groupedClasses = rows.reduce((acc, current) => {
            const classKey = `${current.class_name} - ${current.section}`;
            if (!acc[classKey]) {
                acc[classKey] = {
                    class_id: current.class_id,
                    class_name: current.class_name,
                    section: current.section,
                    subjects: []
                };
            }
            acc[classKey].subjects.push(current.subject_name);
            return acc;
        }, {});

        res.status(200).send(Object.values(groupedClasses));

    } catch (err) {
        console.error('Error fetching teacher classes:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT teacher_id, name FROM teachers');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching teachers:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

router.post('/save-attendance', async (req, res) => {
    const { class_id, record_date, attendance_data, teacher_id } = req.body;

    if (!class_id || !record_date || !attendance_data || !teacher_id) {
        return res.status(400).send({ error: 'Missing required data.' });
    }

    const connection = await req.db.getConnection();
    try {
        await connection.beginTransaction();

        // Loop through the attendance data and insert/update records
        for (const studentId in attendance_data) {
            const isPresent = attendance_data[studentId];
            const attendance_id = uuidv4();
            await connection.query(
                `INSERT INTO attendance (attendance_id, student_id, class_id, record_date, is_present, taken_by_teacher_id) VALUES (?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE is_present = ?`,
                [attendance_id, studentId, class_id, record_date, isPresent, teacher_id, isPresent]
            );
        }

        await connection.commit();
        res.status(201).send({ message: 'Attendance saved successfully.' });

    } catch (err) {
        await connection.rollback();
        console.error('Attendance save error:', err);
        res.status(500).send({ error: 'Failed to save attendance.' });
    } finally {
        connection.release();
    }
});



// Endpoint to get all leave requests for a specific teacher
router.get('/leaves/:teacherId', async (req, res) => {
    const teacherId = req.params.teacherId;
    try {
        const query = `
            SELECT
                lr.*, s.name AS student_name, s.roll_number
            FROM leave_requests lr
            JOIN students s ON lr.student_id = s.student_id
            WHERE lr.class_teacher_id = ?
            ORDER BY lr.created_at DESC;
        `;
        const [rows] = await req.db.query(query, [teacherId]);
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching teacher leaves:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

// Endpoint to approve/reject a leave request
router.put('/leaves/update/:leaveId', async (req, res) => {
    const leaveId = req.params.leaveId;
    const { status } = req.body;
    if (!status) {
        return res.status(400).send({ error: 'Status is required.' });
    }
    try {
        const [result] = await req.db.query('UPDATE leave_requests SET status = ? WHERE leave_id = ?', [status, leaveId]);
        if (result.affectedRows > 0) {
            res.status(200).send({ message: `Leave request ${status.toLowerCase()}d.` });
        } else {
            res.status(404).send({ error: 'Leave request not found.' });
        }
    } catch (err) {
        console.error('Error updating leave status:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


// Endpoint to submit a leave request
router.post('/submit-leave', async (req, res) => {
    const { student_id, reason, start_date, end_date, class_teacher_id } = req.body;

    if (!student_id || !reason || !start_date || !end_date || !class_teacher_id) {
        return res.status(400).send({ error: 'Missing required fields.' });
    }

    try {
        const leave_id = uuidv4();
        await req.db.query(
            'INSERT INTO leave_requests (leave_id, student_id, reason, start_date, end_date, class_teacher_id, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [leave_id, student_id, reason, start_date, end_date, class_teacher_id, 'Pending']
        );
        res.status(201).send({ message: 'Leave request submitted successfully.' });
    } catch (err) {
        console.error('Error submitting leave:', err);
        res.status(500).send({ error: 'Failed to submit leave request.' });
    }
});


// teachers.js ke file mein, existing code ke neeche yeh add karein

router.get('/leave-history/:teacherId', async (req, res) => {
    const teacherId = req.params.teacherId;
    try {
        const [rows] = await req.db.query(
            `SELECT
                lr.leave_id, lr.student_id, lr.reason, lr.start_date, lr.end_date, lr.status,
                s.name AS student_name, s.roll_number
            FROM leave_requests lr
            JOIN students s ON lr.student_id = s.student_id
            WHERE lr.class_teacher_id = ? AND lr.status IN ('Approved', 'Rejected')
            ORDER BY lr.start_date DESC`,
            [teacherId]
        );
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching teacher leave history:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


// my_app_backend/routes/teachers.js

// ... existing routes ...

router.get('/assigned-classes/:teacherId', async (req, res) => {
    const teacherId = req.params.teacherId;
    try {
        const query = `
            SELECT DISTINCT c.class_id, c.class_name, c.section, s.subject_id, s.subject_name
            FROM classes c
            JOIN class_subject_assignments csa ON c.class_id = csa.class_id
            JOIN subjects s ON csa.subject_id = s.subject_id
            WHERE csa.teacher_id = ?
            ORDER BY c.class_name, c.section, s.subject_name;
        `;
        const [rows] = await req.db.query(query, [teacherId]);
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching assigned classes:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

router.post('/upload-marks', async (req, res) => {
    const { student_id, class_id, subject_id, assessment_title, marks_obtained, total_marks, uploaded_by_teacher_id } = req.body;
    if (!student_id || !class_id || !subject_id || !assessment_title || !uploaded_by_teacher_id) {
        return res.status(400).send({ error: 'Missing required data.' });
    }

    try {
        const mark_id = uuidv4();
        await req.db.query(
            'INSERT INTO marks (mark_id, student_id, class_id, subject_id, assessment_title, marks_obtained, total_marks, uploaded_by_teacher_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [mark_id, student_id, class_id, subject_id, assessment_title, marks_obtained, total_marks, uploaded_by_teacher_id]
        );
        res.status(201).send({ message: 'Marks uploaded successfully.' });
    } catch (err) {
        console.error('Error uploading marks:', err);
        res.status(500).send({ error: 'Failed to upload marks.' });
    }
});

// ... your existing module.exports = router;




module.exports = router;