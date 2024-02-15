#CREATE DATABASE chat_app_db;
#USE chat_app_db;
-- Creating the user table
CREATE TABLE User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(20),
    password VARCHAR(250) NOT NULL,
    birthday DATE,
    country VARCHAR(100),
    bio varchar(1000),
    join_date DATETIME,
    first_time TINYINT(1) DEFAULT 1,
    is_active TINYINT,
    firebase_uid VARCHAR(255) UNIQUE
);

CREATE TABLE Image (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    user_img VARCHAR(255),
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    User_user_id INT UNIQUE,
    FOREIGN KEY(User_user_id) REFERENCES User(user_id)
);

-- Creating the hobby board
CREATE TABLE Hobby (
    hobby_id INT AUTO_INCREMENT PRIMARY KEY,
    hobby_name VARCHAR(255) NOT NULL
);

-- Relationship between users and hobbies (many to many)
CREATE TABLE User_has_Hobby (
    User_user_id INT NOT NULL,
    Hobby_hobby_id INT NOT NULL,
    PRIMARY KEY(User_user_id, Hobby_hobby_id),
    FOREIGN KEY(User_user_id) REFERENCES User(user_id),
    FOREIGN KEY(Hobby_hobby_id) REFERENCES Hobby(hobby_id)
);

-- Creating the language table
CREATE TABLE Language (
    lang_id INT AUTO_INCREMENT PRIMARY KEY,
    lang_name VARCHAR(50) NOT NULL
);

-- Relationship between users and languages (many-to-many)
CREATE TABLE User_has_Language (
    User_user_id INT NOT NULL,
    Language_lang_id INT NOT NULL,
    native_lang TINYINT NOT NULL,
    experience_level INT NOT NULL,
    PRIMARY KEY(User_user_id, Language_lang_id),
    FOREIGN KEY(User_user_id) REFERENCES User(user_id),
    FOREIGN KEY(Language_lang_id) REFERENCES Language(lang_id)
);

-- Creation of the interest table
CREATE TABLE Interest (
    interest_id INT AUTO_INCREMENT PRIMARY KEY,
    interest_name VARCHAR(255) NOT NULL
);

-- Relación entre usuarios e intereses (muchos a muchos)
CREATE TABLE User_has_Interest (
    User_user_id INT NOT NULL,
    Interest_interest_id INT NOT NULL,
    PRIMARY KEY(User_user_id, Interest_interest_id),
    FOREIGN KEY(User_user_id) REFERENCES User(user_id),
    FOREIGN KEY(Interest_interest_id) REFERENCES Interest(interest_id)
);

/**
-- NO ADDED YET 


-- Creating the message table
CREATE TABLE Message (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    text VARCHAR(1500) NOT NULL,
    time_stamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    User_user_id INT,
    FOREIGN KEY(User_user_id) REFERENCES User(user_id)
);

-- Creating the conversation table
CREATE TABLE Conversation (
    conversation_id INT AUTO_INCREMENT PRIMARY KEY,
    start_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Relationship between users and conversations (many-to-many)
CREATE TABLE User_has_Conversation (
    User_user_id INT NOT NULL,
    Conversation_conversation_id INT NOT NULL,
    ai_assisted TINYINT NOT NULL DEFAULT 0,
    initiator VARCHAR(50),
    PRIMARY KEY(User_user_id, Conversation_conversation_id),
    FOREIGN KEY(User_user_id) REFERENCES User(user_id),
    FOREIGN KEY(Conversation_conversation_id) REFERENCES Conversation(conversation_id)
);

-- Relationship between conversations and messages (one to many)
CREATE TABLE Conversation_has_Message (
    Conversation_conversation_id INT NOT NULL,
    Message_message_id INT NOT NULL,
    PRIMARY KEY(Conversation_conversation_id, Message_message_id),
    FOREIGN KEY(Conversation_conversation_id) REFERENCES Conversation(conversation_id),
    FOREIGN KEY(Message_message_id) REFERENCES Message(message_id)
);
**/


/**
* These lines are not necesary right now
* Now the creation of user need to do based by the register screen because it now is working with firebase server to auth users
**/

-- Adding 10 users 
-- Insert 10 users -- all user passwords are 123456
/**
INSERT INTO User (first_name, last_name, email, phone_number, password, birthday, country, bio, join_date, is_active)
VALUES 
('John', 'Doe', 'john.doe@example.com', '+1234567890', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1990-01-01', 'USA', 'Bio of John Doe', NOW(), 1),
('Jane', 'Smith', 'jane.smith@example.com', '+1234567891', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1991-02-01', 'Canada', 'Bio of Jane Smith', NOW(), 1),
('Alice', 'Johnson', 'alice.johnson@example.com', '+1234567892', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1992-03-01', 'UK', 'Bio of Alice Johnson', NOW(), 1),
('Bob', 'Brown', 'bob.brown@example.com', '+1234567893', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1993-04-01', 'Mexico', 'Bio of Bob Brown', NOW(), 1),
('Charlie', 'Davis', 'charlie.davis@example.com', '+1234567894', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1994-05-01', 'Australia', 'Bio of Charlie Davis', NOW(), 1),
('Diana', 'Evans', 'diana.evans@example.com', '+1234567895', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1995-06-01', 'Germany', 'Bio of Diana Evans', NOW(), 1),
('Frank', 'Garcia', 'frank.garcia@example.com', '+1234567896', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1996-07-01', 'France', 'Bio of Frank Garcia', NOW(), 1),
('Grace', 'Hill', 'grace.hill@example.com', '+1234567897', '$$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1997-08-01', 'India', 'Bio of Grace Hill', NOW(), 1),
('Henry', 'Ivy', 'henry.ivy@example.com', '+1234567898', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1998-09-01', 'Japan', 'Bio of Henry Ivy', NOW(), 1),
('Isabel', 'Jennings', 'isabel.jennings@example.com', '+1234567899', '$2b$10$hJkCghzt99tT2EDNN2cJLecaiQ1nFmzVre5BjDgtSaIfEqZl.CtZG', '1999-10-01', 'South Korea', 'Bio of Isabel Jennings', NOW(), 1);

-- After inserting users, assuming you want to insert images for users with IDs 1 to 10
INSERT INTO Image (user_img, User_user_id)
VALUES 
(NULL, 1),
(NULL, 2),
(NULL, 3),
(NULL, 4),
(NULL, 5),
(NULL, 6),
(NULL, 7),
(NULL, 8),
(NULL, 9),
(NULL, 10);
**/