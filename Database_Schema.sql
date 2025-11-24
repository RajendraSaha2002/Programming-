-- Run this in your MySQL Workbench or Command Line Client
-- 1. Create Database
CREATE DATABASE IF NOT EXISTS student_db;
USE student_db;

-- 2. Create Main Table
CREATE TABLE IF NOT EXISTS student_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    roll_number INT NOT NULL UNIQUE,
    math INT CHECK (math BETWEEN 0 AND 100),
    science INT CHECK (science BETWEEN 0 AND 100),
    english INT CHECK (english BETWEEN 0 AND 100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Insert Dummy Data (Optional testing)
INSERT INTO student_results (name, roll_number, math, science, english) VALUES 
('Alice Johnson', 101, 85, 90, 88),
('Bob Smith', 102, 76, 65, 80),
('Charlie Brown', 103, 92, 95, 91),
('David Lee', 104, 55, 60, 58),
('Eve Davis', 105, 45, 50, 48);