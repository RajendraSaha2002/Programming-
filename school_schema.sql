CREATE DATABASE IF NOT EXISTS school_tracker;
USE school_tracker;

-- 1. Students Table
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    grade_level INT NOT NULL
);

-- 2. Attendance Table
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent') NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(id)
);

-- 3. Alerts Table (Populated by Python)
CREATE TABLE IF NOT EXISTS risk_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNIQUE, 
    risk_score DOUBLE,
    message VARCHAR(255),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id)
);

-- SEED DATA (Initial Students)
INSERT INTO students (name, grade_level) VALUES 
('Alice Johnson', 10),
('Bob Smith', 10),
('Charlie Brown', 10),
('Diana Prince', 11),
('Evan Wright', 11);

-- SEED DATA (Bob has a pattern of absence)
INSERT INTO attendance (student_id, date, status) VALUES
(2, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'Absent'),
(2, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'Absent'),
(2, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'Present'),
(2, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 'Absent');