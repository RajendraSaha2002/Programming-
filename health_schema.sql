CREATE DATABASE IF NOT EXISTS health_db;
USE health_db;

-- Table to store health data
CREATE TABLE IF NOT EXISTS health_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    bmi DOUBLE NOT NULL,
    heart_rate INT NOT NULL,
    risk_level VARCHAR(20) DEFAULT 'Pending', -- Low, Medium, High
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SEED DATA (Sample Users)
INSERT INTO health_logs (user_name, age, bmi, heart_rate, risk_level) VALUES 
('John Doe', 30, 22.5, 72, 'Low'),
('Alice Smith', 45, 28.0, 85, 'Medium'),
('Bob Jones', 55, 31.5, 110, 'High');