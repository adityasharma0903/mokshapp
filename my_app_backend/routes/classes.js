// my_app_backend/routes/classes.js

const express = require('express');
const router = express.Router();

// Get all classes
router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT * FROM classes');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching classes:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT class_id, class_name, section FROM classes');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching classes:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});


router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT class_id, class_name, section FROM classes');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching classes:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

module.exports = router;