// my_app_backend/routes/vehicles.js
const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// Endpoint to get a vehicle ID by driver ID
router.get('/by-driver/:driverId', async (req, res) => {
    const driverId = req.params.driverId;
    try {
        const [rows] = await req.db.query('SELECT vehicle_id FROM vehicles WHERE driver_id = ?', [driverId]);
        if (rows.length > 0) {
            res.status(200).send(rows[0]);
        } else {
            res.status(404).send({ error: 'Vehicle not found for this driver.' });
        }
    } catch (err) {
        console.error('Error fetching vehicle ID:', err);
        res.status(500).send({ error: 'Internal server error.' });
    }
});

module.exports = router;