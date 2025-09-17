// my_app_backend/routes/subjects.js

const express = require('express');
const router = express.Router();

// Get all subjects
router.get('/', async (req, res) => {
    try {
        const [rows] = await req.db.query('SELECT * FROM subjects');
        res.status(200).send(rows);
    } catch (err) {
        console.error('Error fetching subjects:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

module.exports = router;