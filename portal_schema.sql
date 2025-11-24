CREATE DATABASE IF NOT EXISTS job_portal_db;
USE job_portal_db;

-- 1. Jobs Table
CREATE TABLE IF NOT EXISTS jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    required_skills VARCHAR(255) NOT NULL, -- Comma separated keywords
    posted_date DATE DEFAULT (CURRENT_DATE)
);

-- 2. Candidates Table
CREATE TABLE IF NOT EXISTS candidates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT,
    name VARCHAR(100) NOT NULL,
    resume_text TEXT NOT NULL,
    match_score DOUBLE DEFAULT 0.0, -- Calculated by Python
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);

-- SEED DATA
INSERT INTO jobs (title, required_skills) VALUES 
('Java Developer', 'java, spring, sql, jdbc'),
('Data Scientist', 'python, pandas, machine learning, sql');

INSERT INTO candidates (job_id, name, resume_text) VALUES 
(1, 'John Doe', 'I am an expert in Java and SQL. I love coding.'),
(1, 'Alice Smith', 'I know Python and Machine Learning. I want to learn Java.'),
(2, 'Bob Jones', 'Experienced in Python, Pandas, and Machine Learning models.');