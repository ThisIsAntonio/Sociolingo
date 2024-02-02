const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json());

// Database connection configuration
const db = mysql.createConnection({
    host: 'localhost', // Adjust as necessary
    user: 'root', // Adjust as necessary
    password: 'root', // Adjust as necessary
    database: 'chat_app_db'
});

// Connect to the database
db.connect((err) => {
    if (err) {
        console.error('Error connecting to the MySQL database', err);
        return;
    }
    console.log('Connected to the MySQL database');
});

// Login endpoint
app.post('/login', (req, res) => {
    const { email, password } = req.body;
    const query = 'SELECT * FROM users WHERE email = ?';

    db.execute(query, [email], async (err, result) => {
        if (err) {
            res.status(500).send('Error logging in');
            return;
        }

        if (result.length > 0) {
            // Comparing hashed password with the one provided by user
            const comparison = await bcrypt.compare(password, result[0].password);
            if (comparison) {
                res.status(200).send('Login successful');
            } else {
                res.status(401).send('Incorrect password');
            }
        } else {
            res.status(404).send('User not found');
        }
    });
});

// Register endpoint
app.post('/register', async (req, res) => {
    const { username, email, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10); // Hashing password
    const query = 'INSERT INTO users (username, email, password) VALUES (?, ?, ?)';

    db.execute(query, [username, email, hashedPassword], (err, result) => {
        if (err) {
            console.error('Error registering the user', err);
            res.status(500).send('Error registering the user');
            return;
        }
        res.status(201).send('User registered successfully');
    });
});

// Start the server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
