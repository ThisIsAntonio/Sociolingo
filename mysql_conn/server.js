

const express = require('express');
const mysql = require('mysql2');    //Please install 'npm install mysql2'
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');   //Please install 'npm install bcrypt'
const multer = require('multer');   //Please install 'npm install multer'
const upload = multer();            // Initialize multer, adjust configurations as needed
const admin = require('firebase-admin');
const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json({limit: '50mb'}));

// Initialize Firebase App
var serviceAccount = require("./project1-a9af7-firebase-adminsdk-8ebm6-7f99a39016.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});


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
    // Assuming 'db' is your database connection
    db.query('SELECT * FROM User', (error, results, fields) => {
    if (error) {
        // If there is an error in the query, print it to the console
        return console.error(error.message);
    }
    // Print the results on console
    //console.log(results);
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
                // Check if account is active or not
                if (result[0].is_active !== 1) {
                    res.status(403).send('Account is not active');
                    return;
                }
                // Check if it's the first time the user logs in
                if (result[0].first_time) {
                    // It's the first time, update first_time to false
                    const updateFirstTimeQuery = 'UPDATE User SET first_time = FALSE WHERE email = ?';
                    db.execute(updateFirstTimeQuery, [email], (updateErr, updateResult) => {
                        if (updateErr) {
                            console.error('Error updating first_time', updateErr);
                            // You might choose to still login the user but log this error
                        }
                        // Proceed to login the user
                        res.status(200).json({message: 'Login successful and first_time updated', email: result[0].email, userId: result[0].id});
                    });
                } else {
                    // Not the first time, just log in the user
                    res.status(200).json({message: 'Login successful', email: result[0].email, userId: result[0].id});
                }
            } else {
                res.status(401).send('Incorrect password');
            }
        } else {
            res.status(404).send('User not found.');
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
            const imageUrl = user.user_img ? user.user_img : '';
            const userInfo = {
                ...user,
                imageUrl: imageUrl,
                // Convert birthday to string or provide a default value
                birthday: user.birthday ? user.birthday.toISOString().split('T')[0] : '',
            };
            delete userInfo.user_img; // Remove the user_img

            //console.log('User Info:', userInfo);
            res.status(200).json(userInfo);
        } else {
            res.status(404).send('User not found');
        }
    });
});


// Endpoint for update user info
app.put('/updateUserInfo', async (req, res) => {

    //console.log("Datos recibidos:", req.body);

    const {
        email,
        first_name,
        last_name,
        phone_number,
        birthday,
        country,
        bio,
        password,
        imageUrl
    } = req.body;

    // Hash the new password if it's provided
    let hashedPassword = null;
    if (password) {
        hashedPassword = await bcrypt.hash(password, 10);
    }

    // Prepare SQL query to update user info
    let userUpdateQuery = `
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

    let userUpdateParams = [
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

        if (imageUrl) {
        // Primero, obtén el user_id del usuario basado en el email
        const getUserIdQuery = 'SELECT user_id FROM User WHERE email = ?';
        db.execute(getUserIdQuery, [email], (err, results) => {
        if (err) {
            console.error('Error fetching user ID', err);
            return res.status(500).send('Error updating user image');
        }

        if (results.length > 0) {
            const userId = results[0].user_id;

            // Now that you have the user_id, update the entry in the Image table
            const imageUpdateQuery = `
                INSERT INTO Image (user_img, User_user_id) 
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE user_img = VALUES(user_img);
            `;
            db.execute(imageUpdateQuery, [imageUrl, userId], (imageErr) => {
                if (imageErr) {
                    console.error('Error saving user image', imageErr);
                    return res.status(500).send('Error saving user image');
                }
            });
        } else {
            console.error('User not found for the given email');
            return res.status(404).send('User not found');
        }
        });
    }


        res.status(200).send('User info updated successfully');
    });
});

    // Register endpoint
    app.post('/register', upload.any(), async (req, res) => {
    const { first_name, last_name, email, phone_number, token, password, birthday, country, imageUrl } = req.body;
    console.log('Datos recividos: ', req.body);
    try {
        // Verify the Firebase Auth token
        const decodedToken = await admin.auth().verifyIdToken(token);
        if (!decodedToken) {
            return res.status(401).send('Invalid Firebase token.');
        }

        // Continue with the registration logic since the token is valid
        const hashedPassword = await bcrypt.hash(password, 10); // Hash the password
        const join_date = new Date(); // Current date and time
        const is_active = 1; // Assuming '1' means active
        const first_time = true; // Set first_time to true for new registrations

        // Insert the user into the database including first_time
        const userQuery = `
        INSERT INTO User (first_name, last_name, email, phone_number, password, birthday, country, join_date, first_time, is_active, firebase_uid)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        db.execute(userQuery, [first_name, last_name, email, phone_number, hashedPassword, birthday, country, join_date, first_time, is_active, token],
        (err, userResult) => {
            if (err) {
            console.error('Error registering the user', err);
            res.status(500).send('Error registering the user');
            return;
            }

            // If an image is provided, insert it into the images table
            if (imageUrl) {
            const userId = userResult.insertId; // Get the inserted user's ID
            //const imageUrl = imageUrl;
            const imageQuery = 'INSERT INTO Image (user_img, User_user_id) VALUES (?, ?)';
            db.execute(imageQuery, [imageUrl, userId], (imageErr) => {
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

// Remove user from the app
app.post('/deleteUser', (req, res) => {
    const { email } = req.body;
    const query = 'UPDATE User SET is_active = 0 WHERE email = ?';

    db.execute(query, [email], (err, result) => {
        if (err) {
            res.status(500).send('Error deleting user');
            return;
        }

        res.status(200).send('User successfully deleted');
    });
});


// Start the server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});


// < =================================================================== >
//              SEND RESET PASSWORD INSTRUCTIONS VIA EMAIL
// < =================================================================== >

const nodemailer = require('nodemailer');

// Configure the transporter for the email service (e.g., Gmail)
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'sociolingo.project@gmail.com', // Change this to your email address
        pass: 'xtgy nblg pkyo fxvk' // Change this to your email password
    }
});

// Function to send email with verification code
function sendVerificationEmail(email, randomCode) {
    const mailOptions = {
        from: 'sociolingo.project@gmail.com', // Sender's email address
        to: email, // Recipient's email address
        subject: 'Verification Code to Reset Password', // Email subject
        text: `Your verification code is: ${randomCode}` // Email body
    };

    // Send the email
    transporter.sendMail(mailOptions, function(error, info){
        if (error) {
            console.error('Error sending email:', error);
        } else {
            console.log('Email sent:', info.response);
        }
    });
}

// Endpoint to send reset password instructions via email
app.post('/sendEmailInstructions', (req, res) => {
    const { email, code } = req.body;
    sendVerificationEmail(email, code); // Call the function to send the email
    res.status(200).send('Email sent successfully');
});

// Endpoint to reset password
app.post('/resetPassword', async (req, res) => {
    const { email, newPassword } = req.body;

    // Imprimir el correo electrónico y la nueva contraseña recibidos
    console.log('Correo electrónico recibido:', email);
    console.log('Nueva contraseña recibida:', newPassword);

    try {
        // Hash the new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Update the user's password in the database
        const query = 'UPDATE User SET password = ? WHERE email = ?';
        db.execute(query, [hashedPassword, email], (err, result) => {
            if (err) {
                console.error('Error updating password:', err);
                res.status(500).send('Error updating password');
                return;
            }
            res.status(200).send('Password updated successfully');
        });
    } catch (error) {
        console.error('Error hashing password:', error);
        res.status(500).send('Error updating password');
    }
});

