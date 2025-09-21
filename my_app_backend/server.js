// server.js (Updated Version)
const express = require("express")
require('dotenv').config();

const mysql = require("mysql2/promise")
const cors = require("cors")
const http = require("http")
const socketIo = require("socket.io")
const { Server } = require('socket.io'); // <-- this works now


const app = express()
const port = 3000

app.use(cors())
app.use(express.json())
app.use(express.urlencoded({ extended: true }))

const server = http.createServer(app)
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
})

// MySQL pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

;(async () => {
  try {
    const connection = await pool.getConnection()
    console.log("✅ Connected to DB!")
    connection.release()
  } catch (err) {
    console.error("❌ DB Connection Failed:", err.message)
    process.exit(1)
  }
})()

app.use((req, res, next) => {
  req.db = pool
  next()
})

// Existing routes
const authRoutes = require("./routes/auth")
const studentRoutes = require("./routes/students")
const teacherRoutes = require("./routes/teachers")
const announcementRoutes = require("./routes/announcements")
const classRoutes = require("./routes/classes")
const subjectRoutes = require("./routes/subjects")

app.use("/api", authRoutes)
app.use("/api/students", studentRoutes)
app.use("/api/teachers", teacherRoutes)
app.use("/api/announcements", announcementRoutes)
app.use("/api/classes", classRoutes)
app.use("/api/subjects", subjectRoutes)

// ---- Consolidated Location Handling ----

/**
 * Updates location in the database and broadcasts to all relevant clients.
 * @param {object} data - The location data containing vehicle_id, latitude, and longitude.
 */
const updateAndBroadcastLocation = async (data) => {
  const { vehicle_id, latitude, longitude } = data
  if (!vehicle_id || latitude === undefined || longitude === undefined) {
    console.error("Missing location data for broadcast:", data)
    return
  }

  // Sanitize and validate numeric values
  const parsedLat = parseFloat(latitude)
  const parsedLng = parseFloat(longitude)

  if (isNaN(parsedLat) || isNaN(parsedLng)) {
    console.error("Invalid numeric location data:", data)
    return
  }

  const query = `
    INSERT INTO live_locations (vehicle_id, latitude, longitude, timestamp)
    VALUES (?, ?, ?, NOW())
    ON DUPLICATE KEY UPDATE
      latitude = VALUES(latitude),
      longitude = VALUES(longitude),
      timestamp = NOW()
  `
  await pool.query(query, [vehicle_id, parsedLat, parsedLng])

  const roomName = `vehicle_${vehicle_id}`
  const locationData = {
    vehicle_id,
    latitude: parsedLat,
    longitude: parsedLng,
    timestamp: new Date().toISOString(),
  }

  // Use the global 'io' object to broadcast to all clients in the room
  io.to(roomName).emit("location_update", locationData)
  console.log(`📍 Location update broadcast to room ${roomName}:`, locationData)
}

// HTTP POST endpoint to receive location updates
app.post("/api/vehicles/location", async (req, res) => {
  try {
    await updateAndBroadcastLocation(req.body)
    res.status(200).json({
      message: "Location updated successfully via HTTP",
      timestamp: new Date().toISOString()
    })
  } catch (err) {
    console.error("HTTP location update error:", err)
    res.status(500).json({
      error: "Failed to update location",
      details: err.message
    })
  }
})

// GET last known location (no change)
app.get("/api/vehicles/:vehicleId/location", async (req, res) => {
  const vehicleId = req.params.vehicleId
  try {
    const [rows] = await pool.query(
      "SELECT * FROM live_locations WHERE vehicle_id = ? ORDER BY timestamp DESC LIMIT 1",
      [vehicleId],
    )
    if (rows.length > 0) {
      res.json(rows[0])
    } else {
      res.status(404).json({ message: "No location data found for this vehicle" })
    }
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: "Failed to fetch location" })
  }
})

// Socket handling
io.on("connection", (socket) => {
  console.log("✅ Client connected:", socket.id)

  socket.on("join_room", (roomId) => {
    console.log(`Client ${socket.id} joined room ${roomId}`)
    socket.join(roomId)
    socket.emit("room_joined", { room: roomId, success: true })
  })

  socket.on("leave_room", (roomId) => {
    console.log(`Client ${socket.id} left room ${roomId}`)
    socket.leave(roomId)
  })

  // Driver location updates from the socket directly use the consolidated function
  socket.on("driver_location_update", (data) => {
    updateAndBroadcastLocation(data)
  })

  socket.on("driver_stop_sharing", (data) => {
    const { vehicle_id } = data
    if (vehicle_id) {
      const roomName = `vehicle_${vehicle_id}`
      // Use 'io' to broadcast to all clients in the room
      io.to(roomName).emit("vehicle_offline", { vehicle_id })
      console.log(`🔴 Vehicle ${vehicle_id} went offline`)
    }
  })

  socket.on("disconnect", () => {
    console.log("❌ Client disconnected:", socket.id)
  })
})

// Existing GET routes
app.get("/api/vehicles/by-driver/:driverId", async (req, res) => {
  const driverId = req.params.driverId
  try {
    const [rows] = await pool.query("SELECT vehicle_id FROM vehicles WHERE driver_id = ?", [driverId])
    if (rows.length > 0) {
      res.json({ vehicle_id: rows[0].vehicle_id })
    } else {
      res.status(404).json({ message: "Vehicle not found for driver" })
    }
  } catch (err) {
    res.status(500).json({ message: err.message })
  }
})

app.get("/api/vehicles/by-student/:userId", async (req, res) => {
  const userId = req.params.userId
  try {
    const [rows] = await pool.query(
      `
       SELECT
          v.vehicle_id,
          v.vehicle_number,
          sva.route_id
       FROM students s
       JOIN student_vehicle_assignments sva ON s.student_id = sva.student_id
       JOIN vehicles v ON sva.vehicle_id = v.vehicle_id
       WHERE s.user_id = ? AND sva.status = 'active'
       ORDER BY sva.assigned_date DESC
       LIMIT 1
      `,
      [userId],
    )
    if (rows.length > 0) {
      res.json({
        vehicle_id: rows[0].vehicle_id,
        vehicle_number: rows[0].vehicle_number,
        route_id: rows[0].route_id,
      })
    } else {
      res.status(404).json({ message: "No vehicle assigned to this student" })
    }
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: "Failed to fetch vehicle for student" })
  }
})
server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`)
})