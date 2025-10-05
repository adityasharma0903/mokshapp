const express = require("express")
const router = express.Router()
const { v4: uuidv4 } = require("uuid");
// NOTE: bcrypt is necessary for secure password hashing
const bcrypt = require('bcryptjs');
const { sendDriverWelcomeEmail } = require('../services/emailService'); // Adjust path as needed


const isValidEmail = (email) => {
    // Simple regex for email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
};

router.post("/", async (req, res) => {
    const {
        email,
        password, // The password will be stored as-is (plaintext)
        vehicle_number,
        vehicle_type,
        capacity,
    } = req.body;

    // 1. Basic Validation
    if (!email || !password || !vehicle_number) {
        return res.status(400).json({ error: "Missing required fields: email, password, and vehicle number are mandatory." });
    }
    if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Invalid email format." });
    }
    if (password.length < 6) {
        return res.status(400).json({ error: "Password must be at least 6 characters long." });
    }

    const driverId = uuidv4();
    const vehicleId = uuidv4();
    let connection;
    let plaintextPassword; // Declare outside try block for email access

    try {
        // 2. *** MODIFICATION: NO PASSWORD HASHING ***
        plaintextPassword = password; // Assign here
        // The security warning about plaintext passwords remains!

        // 3. Start a Transaction for atomicity
        connection = await req.db.getConnection();
        await connection.beginTransaction();

        // Check if user already exists
        const [existingUsers] = await connection.query('SELECT user_id FROM users WHERE email = ?', [email]);
        if (existingUsers.length > 0) {
            await connection.rollback();
            return res.status(409).json({ error: "A user with this email already exists." });
        }

        // 4. Insert into users table (as 'driver')
        // WARNING: password_hash field is now storing the plaintext password!
        const userQuery = `
            INSERT INTO users (user_id, email, password_hash, user_type)
            VALUES (?, ?, ?, 'driver')
        `;
        await connection.query(userQuery, [driverId, email, plaintextPassword]);

        // 5. Insert into vehicles table
        const vehicleQuery = `
            INSERT INTO vehicles (vehicle_id, vehicle_number, vehicle_type, driver_id, capacity, status)
            VALUES (?, ?, ?, ?, ?, 'inactive')
        `;
        await connection.query(vehicleQuery, [
            vehicleId,
            vehicle_number,
            vehicle_type || 'bus',
            driverId,
            capacity || 50,
        ]);

        // 6. Commit the transaction
        await connection.commit();

        // --- 7. Send Welcome Email AFTER successful commit ---
        const emailSent = await sendDriverWelcomeEmail(
            email,             // Recipient's email
            email,             // Login email
            plaintextPassword, // Raw password
            vehicle_number     // Vehicle number for context
        );
        // ---------------------------------------------------

        const emailMessage = emailSent ? ' and welcome email sent.' : ' but email sending failed.';


        res.status(201).json({
            message: "Driver and vehicle created successfully with plaintext password." + emailMessage,
            driver_id: driverId,
            vehicle_id: vehicleId,
        });

    } catch (err) {
        console.error("Error creating new driver (Transaction rolled back):", err);
        if (connection) {
            await connection.rollback();
        }
        if (err.code === 'ER_DUP_ENTRY' && err.sqlMessage.includes('vehicle_number')) {
             return res.status(409).json({ error: "A vehicle with this number already exists." });
        }
        res.status(500).json({
            error: "Failed to create driver due to an internal server error.",
            details: err.message,
        });
    } finally {
        if (connection) {
            connection.release();
        }
    }
});

// Get all drivers with their vehicle information and location status
router.get("/all", async (req, res) => {
  try {
    const query = `
            SELECT
                u.user_id,
                u.email,
                v.vehicle_id,
                v.vehicle_number,
                v.vehicle_type,
                v.capacity,
                v.status as vehicle_status,
                ll.latitude,
                ll.longitude,
                ll.timestamp as last_update,
                CASE
                    WHEN ll.vehicle_id IS NOT NULL THEN true
                    ELSE false
                END as has_location
            FROM users u
            LEFT JOIN vehicles v ON u.user_id = v.driver_id
            LEFT JOIN live_locations ll ON v.vehicle_id = ll.vehicle_id
            WHERE u.user_type = 'driver'
            ORDER BY u.email ASC
        `

    const [rows] = await req.db.query(query)

    // Format the response
    const drivers = rows.map((row) => ({
      user_id: row.user_id,
      email: row.email,
      vehicle_id: row.vehicle_id,
      vehicle_number: row.vehicle_number || "Not Assigned",
      vehicle_type: row.vehicle_type,
      capacity: row.capacity,
      vehicle_status: row.vehicle_status,
      latitude: row.latitude,
      longitude: row.longitude,
      last_update: row.last_update ? new Date(row.last_update).toLocaleString() : null,
      has_location: row.has_location,
    }))

    res.status(200).json(drivers)
  } catch (err) {
    console.error("Error fetching drivers:", err)
    res.status(500).json({
      error: "Failed to fetch drivers",
      details: err.message,
    })
  }
})

// Get specific driver by ID
router.get("/:driverId", async (req, res) => {
  const driverId = req.params.driverId
  try {
    const query = `
            SELECT
                u.user_id,
                u.email,
                v.vehicle_id,
                v.vehicle_number,
                v.vehicle_type,
                v.capacity,
                v.status as vehicle_status,
                ll.latitude,
                ll.longitude,
                ll.timestamp as last_update,
                CASE
                    WHEN ll.vehicle_id IS NOT NULL THEN true
                    ELSE false
                END as has_location
            FROM users u
            LEFT JOIN vehicles v ON u.user_id = v.driver_id
            LEFT JOIN live_locations ll ON v.vehicle_id = ll.vehicle_id
            WHERE u.user_type = 'driver' AND u.user_id = ?
        `

    const [rows] = await req.db.query(query, [driverId])

    if (rows.length === 0) {
      return res.status(404).json({ error: "Driver not found" })
    }

    const driver = {
      user_id: rows[0].user_id,
      email: rows[0].email,
      vehicle_id: rows[0].vehicle_id,
      vehicle_number: rows[0].vehicle_number || "Not Assigned",
      vehicle_type: rows[0].vehicle_type,
      capacity: rows[0].capacity,
      vehicle_status: rows[0].vehicle_status,
      latitude: rows[0].latitude,
      longitude: rows[0].longitude,
      last_update: rows[0].last_update ? new Date(rows[0].last_update).toLocaleString() : null,
      has_location: rows[0].has_location,
    }

    res.status(200).json(driver)
  } catch (err) {
    console.error("Error fetching driver:", err)
    res.status(500).json({
      error: "Failed to fetch driver",
      details: err.message,
    })
  }
})

module.exports = router
