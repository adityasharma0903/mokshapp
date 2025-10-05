const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
// Updated to include sendPasswordChangeNotification
const { sendWelcomeEmail, sendPasswordChangeNotification } = require('../services/emailService');

// Endpoint to add a new student from the admin panel
router.post('/add', async (req, res) => {
    const {
        email, password_hash, user_type,
        name, roll_number, dob, gender, nationality, religion, blood_group,
        contact_number, permanent_address, current_address, father_name, mother_name,
        father_email, transport_acquired, has_sibling, photograph_url, class_id, class_teacher_id
    } = req.body;

    // Basic validation
    if (!email || !password_hash || !name || !roll_number || !class_id) {
        return res.status(400).send({ error: 'Required fields are missing.' });
    }

    // IMPORTANT SECURITY NOTE: In a real application, you must HASH the password_hash
    // before saving it to the database, but you should use the RAW password (password_hash)
    // for the welcome email.

    const connection = await req.db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Insert into users table
        const user_id = uuidv4();
        await connection.query(
            'INSERT INTO users (user_id, email, password_hash, user_type) VALUES (?, ?, ?, ?)',
            [user_id, email, password_hash, user_type] // Use HASHED password here in production!
        );

        // 2. Insert into students table
        const student_id = uuidv4();
        await connection.query(
            'INSERT INTO students (student_id, user_id, roll_number, name, dob, gender, nationality, religion, blood_group, contact_number, email, permanent_address, current_address, photograph_url, transport_acquired, has_sibling) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [student_id, user_id, roll_number, name, dob, gender, nationality, religion, blood_group, contact_number, email, permanent_address, current_address, photograph_url, transport_acquired, has_sibling]
        );

        // 3. Insert into student_parents table
        await connection.query(
            'INSERT INTO student_parents (student_id, father_name, mother_name, father_email) VALUES (?, ?, ?, ?)',
            [student_id, father_name, mother_name, father_email]
        );

        // 4. Insert into student_enrollments table
        const enrollment_id = uuidv4();
        await connection.query(
            'INSERT INTO student_enrollments (enrollment_id, student_id, class_id, enrollment_date) VALUES (?, ?, ?, NOW())',
            [enrollment_id, student_id, class_id]
        );

        // 5. Update the classes table to set the class teacher
        if (class_teacher_id) {
            await connection.query(
                'UPDATE classes SET class_teacher_id = ? WHERE class_id = ?',
                [class_teacher_id, class_id]
            );
        }

        await connection.commit();

        // --- 6. Send Welcome Email AFTER successful commit ---
        // Pass the required credentials for the email
        const emailSent = await sendWelcomeEmail(
            father_email || email, // Prioritize father's email, fallback to student's login email
            name,
            email,                // Student's login email/username
            password_hash         // Raw password for the initial welcome email
        );
        // ------------------------------------------------------

        const emailMessage = emailSent ? ' and welcome email sent.' : ' but email sending failed.';

        res.status(201).send({
            message: 'Student and user created successfully.' + emailMessage,
            student_id,
            user_id
        });

    } catch (err) {
        await connection.rollback();
        console.error('Transaction error:', err);
        res.status(500).send({ error: 'Failed to add student. Transaction rolled back.' });
    } finally {
        connection.release();
    }
});


router.get('/attendance/:studentId', async (req, res) => {
    const studentId = req.params.studentId;
    try {
        const query = `
            SELECT
                record_date, is_present
            FROM attendance
            WHERE student_id = ?
            ORDER BY record_date DESC;
        `;
        const [rows] = await req.db.query(query, [studentId]);
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching student attendance:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


// Endpoint to get all students for the admin panel
router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT * FROM students');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching students:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

// Endpoint to get a single student by ID
router.get('/:id', async (req, res) => {
    const student_id = req.params.id;
    try {
        const [rows] = await req.db.query('SELECT * FROM students WHERE student_id = ?', [student_id]);
        if (rows.length > 0) {
            res.status(200).send(rows[0]);
        } else {
            res.status(404).send({ error: 'Student not found.' });
        }
    } catch (err) {
        console.error('Error fetching student:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

// Endpoint to get a complete student profile by their user_id
router.get('/profile/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
        const query = `
            SELECT
                s.student_id, s.name, s.roll_number, s.email, s.gender, s.dob, s.nationality,
                s.religion, s.blood_group, sp.father_name, sp.mother_name, sp.father_email,
                s.contact_number, s.permanent_address AS address, s.photograph_url,
                s.transport_acquired, s.has_sibling,
                c.class_name, c.section, t.name AS class_teacher_name,
                c.class_teacher_id
            FROM students s
            LEFT JOIN student_parents sp ON s.student_id = sp.student_id
            LEFT JOIN student_enrollments se ON s.student_id = se.student_id
            LEFT JOIN classes c ON se.class_id = c.class_id
            LEFT JOIN teachers t ON c.class_teacher_id = t.teacher_id
            WHERE s.user_id = ?
        `;
        const [rows] = await req.db.query(query, [userId]);

        if (rows.length > 0) {
            res.status(200).send(rows[0]);
        } else {
            res.status(404).send({ error: 'Student profile not found.' });
        }
    } catch (err) {
        console.error('Error fetching student profile:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


// students.js ke file mein, existing code ke neeche yeh add karein

router.get('/leave-history/:studentId', async (req, res) => {
    const studentId = req.params.studentId;
    try {
        const [rows] = await req.db.query(
            `SELECT
                leave_id, reason, start_date, end_date, status
            FROM leave_requests
            WHERE student_id = ?
            ORDER BY start_date DESC`,
            [studentId]
        );
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching student leave history:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

router.get('/marks/:studentId', async (req, res) => {
    const studentId = req.params.studentId;
    try {
        const query = `
            SELECT subject_id, assessment_title, marks_obtained, total_marks
            FROM marks
            WHERE student_id = ?
            ORDER BY uploaded_at DESC;
        `;
        const [rows] = await req.db.query(query, [studentId]);

        // To get subject names, we need to join with the subjects table
        const marksWithSubjects = await Promise.all(rows.map(async (mark) => {
            const [subjectRows] = await req.db.query('SELECT subject_name FROM subjects WHERE subject_id = ?', [mark.subject_id]);
            return {
                ...mark,
                subject_name: subjectRows.length > 0 ? subjectRows[0].subject_name : 'Unknown Subject'
            };
        }));

        res.status(200).send(marksWithSubjects);
    } catch (err) {
        console.error('Error fetching student marks:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


router.get('/class/:classId', async (req, res) => {
    const classId = req.params.classId;
    try {
        const query = `
            SELECT
                s.student_id AS id, s.name, s.roll_number, s.email, s.photograph_url
            FROM students s
            JOIN student_enrollments se ON s.student_id = se.student_id
            WHERE se.class_id = ?
        `;
        const [rows] = await req.db.query(query, [classId]);
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching students by class:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


// Endpoint to edit an existing student
router.put('/edit/:id', async (req, res) => {
    const student_id = req.params.id;
    const updateData = req.body;

    if (Object.keys(updateData).length === 0) {
        return res.status(400).send({ error: 'No data provided for update.' });
    }

    try {
        const [result] = await req.db.query('UPDATE students SET ? WHERE student_id = ?', [updateData, student_id]);

        if (result.affectedRows > 0) {
            res.status(200).send({ message: 'Student updated successfully.' });
        } else {
            res.status(404).send({ error: 'Student not found or no changes made.' });
        }
    } catch (err) {
        console.error('Error updating student:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


module.exports = router;