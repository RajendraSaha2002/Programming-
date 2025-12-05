-- Run this in your PostgreSQL Query Tool (pgAdmin)

-- 1. Create Database (Manually create if it doesn't exist)
-- CREATE DATABASE school_db;

-- 2. Create Students Table
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    grade_level INT,
    enrollment_date DATE DEFAULT CURRENT_DATE
);

-- 3. Seed Data
INSERT INTO students (full_name, email, grade_level) VALUES 
('John Doe', 'john@example.com', 10),
('Jane Smith', 'jane@school.org', 11)
ON CONFLICT (email) DO NOTHING;