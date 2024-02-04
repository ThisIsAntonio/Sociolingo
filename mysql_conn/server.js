const express = require('express');
const mysql = require('mysql2');    //Please install 'npm install mysql2'
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');   //Please install 'npm install bcrypt'
const multer = require('multer');   //Please install 'npm install multer'
const upload = multer();            // Initialize multer, adjust configurations as needed
const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json({limit: '50mb'}));

// Database connection configuration
const db = mysql.createConnection({
    host: '162.241.61.253', // Adjust as necessary, if you use your local dba use 'localhost'
    user: 'thisisa2_root', // Adjust as necessary, if you use your local dba use your local user, example 'root'
    password: 'eng4002010', // Adjust as necessary, you use your local dba use your local password, example: 'root'
    database: 'thisisa2_chat_app_sql' // Adjust as necessary, you can use your local dba use this how to example:'chat_app_db'
});

// Connect to the database
db.connect((err) => {
    if (err) {
        console.error('Error connecting to the MySQL database', err);
        return;
    }
    console.log('Connected to the MySQL database');
    console.log('')
    // Suponiendo que 'db' es tu conexión a la base de datos
    db.query('SELECT * FROM User', (error, results, fields) => {
    if (error) {
        // Si hay un error en la consulta, lo imprime en la consola
        return console.error(error.message);
    }
    // Imprime los resultados en la consola
    console.log(results);
    });

});

// Login endpoint
app.post('/login', (req, res) => {
    const { email, password } = req.body;
    const query = 'SELECT * FROM User WHERE email = ?';

    db.execute(query, [email], async (err, result) => {
        if (err) {
            res.status(500).send('Error logging in');
            return;
        }

        if (result.length > 0) {
            // Comparing hashed password with the one provided by user
            const comparison = await bcrypt.compare(password, result[0].password);
            if (comparison) {
                res.status(200).json({messaje: 'Login successful', email: result[0].email, userId: result[0].id});
            } else {
                res.status(401).send('Incorrect password');
            }
        } else {
            res.status(404).send('User not found');
        }
    });
});

// Endpoint for user info
app.get('/userInfo', (req, res) => {
    const { email } = req.query;
    const userQuery = `
        SELECT 
            User.first_name, 
            User.last_name, 
            User.email, 
            User.phone_number, 
            User.birthday, 
            User.country, 
            User.bio, 
            Image.user_img 
        FROM User 
        LEFT JOIN Image ON User.user_id = Image.User_user_id 
        WHERE User.email = ?
    `;

    db.execute(userQuery, [email], (err, results) => {
        if (err) {
            console.error('Server error', err);
            return res.status(500).send('Server error');
        }

        if (results.length > 0) {
            const user = results[0];
            const imageBase64 = user.user_img ? Buffer.from(user.user_img).toString('base64') : '';
            const userInfo = {
                ...user,
                imageBase64: imageBase64,
                // Convert birthday to string or provide a default value
                birthday: user.birthday ? user.birthday.toISOString().split('T')[0] : '',
            };
            delete userInfo.user_img; // Remove the BLOB field

            console.log('User Info:', userInfo);
            res.status(200).json(userInfo);
        } else {
            res.status(404).send('User not found');
        }
    });
});


// Endpoint for update user info
app.put('/updateUserInfo', async (req, res) => {
    const {
        email,
        first_name,
        last_name,
        phone_number,
        birthday,
        country,
        bio,
        password,
        profile_picture_base64
    } = req.body;

    // Hash the new password if it's provided
    let hashedPassword = null;
    if (password) {
        hashedPassword = await bcrypt.hash(password, 10);
    }

    // Prepare SQL query to update user info
    const userUpdateQuery = `
        UPDATE User
        SET 
            first_name = ?, 
            last_name = ?, 
            phone_number = ?, 
            birthday = ?, 
            country = ?, 
            bio = ?
            ${hashedPassword ? ', password = ?' : ''}
        WHERE email = ?
    `;

    const userUpdateParams = [
        first_name, 
        last_name, 
        phone_number, 
        birthday, 
        country, 
        bio,
        ...(hashedPassword ? [hashedPassword] : []),
        email
    ];

    // Execute the user info update query
    db.execute(userUpdateQuery, userUpdateParams, async (err, result) => {
        if (err) {
            console.error('Error updating user info', err);
            return res.status(500).send('Error updating user info');
        }

        // Handle profile picture update separately if provided
        if (profile_picture_base64) {
            const imageBuffer = Buffer.from(profile_picture_base64, 'base64');
            const imageUpdateQuery = `
                INSERT INTO Image (user_img, User_user_id) 
                VALUES (?, (SELECT user_id FROM User WHERE email = ?))
                ON DUPLICATE KEY UPDATE user_img = VALUES(user_img)
            `;

            db.execute(imageUpdateQuery, [imageBuffer, email], (imageErr, imageResult) => {
                if (imageErr) {
                    console.error('Error saving user image', imageErr);
                    return res.status(500).send('Error saving user image');
                }
            });
        }

        res.status(200).send('User info updated successfully');
    });
});

    // Register endpoint
    app.post('/register', upload.any(), async (req, res) => {
    const { first_name, last_name, email, password, birthday, country, profile_picture_base64 } = req.body;
    
    try {
        console.log('Received fields:', req.body);
        if (req.files) console.log('Received files:', req.files);
        console.log('Password to hash:', req.body.password);
        
        const hashedPassword = await bcrypt.hash(password, 10); // Hash the password
        const join_date = new Date(); // Current date and time
        const is_active = 1; // Assuming '1' means active

        // Insert the user into the database
        const userQuery = `
        INSERT INTO User (first_name, last_name, email, password, birthday, country, join_date, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        db.execute(userQuery, [first_name, last_name, email, hashedPassword, birthday, country, join_date, is_active],
        (err, userResult) => {
            if (err) {
            console.error('Error registering the user', err);
            res.status(500).send('Error registering the user');
            return;
            }

            // If an image is provided, insert it into the images table
            if (profile_picture_base64) {
            const userId = userResult.insertId; // Get the inserted user's ID
            const imageBuffer = Buffer.from(profile_picture_base64, 'base64');
            const imageQuery = 'INSERT INTO Image (user_img, User_user_id) VALUES (?, ?)';
            db.execute(imageQuery, [imageBuffer, userId], (imageErr) => {
                if (imageErr) {
                console.error('Error saving user image', imageErr);
                res.status(500).send('Error saving user image');
                return;
                }
                res.status(201).send('User registered successfully with image');
            });
            } else {
            // If no image is provided, respond successfully
            res.status(201).send('User registered successfully without an image');
            }
        });
    } catch (err) {
        console.error('Server error', err);
        res.status(500).send('Server error');
    }
    });

// Start the server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
