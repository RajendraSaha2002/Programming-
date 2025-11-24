CREATE DATABASE IF NOT EXISTS attendance_db;
USE attendance_db;

-- 1. Employees Table
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50)
);

-- 2. Attendance Table
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    date DATE NOT NULL,
    in_time TIME,
    out_time TIME,
    status ENUM('Present', 'Late', 'Absent') DEFAULT 'Present',
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    UNIQUE(employee_id, date) -- Prevent multiple entries per day
);

-- SEED DATA (Employees)
INSERT INTO employees (name, department) VALUES 
('John Doe', 'IT'),
('Jane Smith', 'HR'),
('Mike Johnson', 'Sales');

-- SEED DATA (Simulated Attendance History for Reports)
-- John was late on day 1, normal on day 2
INSERT INTO attendance (employee_id, date, in_time, out_time, status) VALUES 
(1, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '09:45:00', '17:00:00', 'Late'),
(1, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '09:00:00', '17:00:00', 'Present');

-- Jane was on time both days
INSERT INTO attendance (employee_id, date, in_time, out_time, status) VALUES 
(2, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '08:55:00', '17:05:00', 'Present'),
(2, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '09:00:00', '17:00:00', 'Present');