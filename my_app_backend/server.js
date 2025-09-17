// my_app_backend/server.js

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const port = 3000;

// Enable CORS for all origins to allow your Flutter app to connect
app.use(cors());
// Enable Express to parse JSON bodies from incoming requests
app.use(express.json());

// --- MySQL Database Connection Pool ---
// Using a connection pool is more efficient for managing multiple connections
const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',      // <--- Replace with your MySQL username
    password: 'Aditya@0903',  // <--- Replace with your MySQL password
    database: 'moksh', // <--- Replace with your database name
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Test the database connection
pool.getConnection()
    .then(connection => {
        console.log('Successfully connected to the database!');
        connection.release();
    })
    .catch(err => {
        console.error('Database connection failed:', err.stack);
        process.exit(1); // Exit the process if connection fails
    });

// Make the database pool available to all routes
app.use((req, res, next) => {
    req.db = pool;
    next();
});

// --- Import Route Files ---
const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/students');
 const teacherRoutes = require('./routes/teachers'); // You'll create these later
// const announcementRoutes = require('./routes/announcements'); // And these
const classRoutes = require('./routes/classes'); // New
const subjectRoutes = require('./routes/subjects'); // New

// --- Use Routes ---
app.use('/api', authRoutes);
app.use('/api/students', studentRoutes);
 app.use('/api/teachers', teacherRoutes);
// app.use('/api/announcements', announcementRoutes);
app.use('/api/classes', classRoutes); // New
app.use('/api/subjects', subjectRoutes); // New

// A simple welcome route
app.get('/', (req, res) => {
    res.send('Welcome to the College App API!');
});

// Start the server
app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});