CREATE DATABASE IF NOT EXISTS banking_db;
USE banking_db;

-- 1. Customers Table
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DOUBLE DEFAULT 0.0
);

-- 2. Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    amount DOUBLE NOT NULL,
    type ENUM('DEPOSIT', 'WITHDRAWAL') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_checked_for_fraud BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- 3. Fraud Alerts Table
CREATE TABLE IF NOT EXISTS fraud_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT,
    risk_score DOUBLE, -- -1 (Anomaly) to 1 (Normal) usually, or probability
    reason VARCHAR(255),
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- SEED DATA (Normal User Behavior)
INSERT INTO customers (name, balance) VALUES 
('Alice Johnson', 5000.00),
('Bob Smith', 12000.00),
('Charlie Brown', 300.00);

-- SEED HISTORICAL TRANSACTIONS (Normal amounts for ML training)
INSERT INTO transactions (customer_id, amount, type, is_checked_for_fraud) VALUES
(1, 50.00, 'DEPOSIT', TRUE),
(1, 100.00, 'WITHDRAWAL', TRUE),
(1, 45.00, 'DEPOSIT', TRUE),
(2, 500.00, 'DEPOSIT', TRUE),
(2, 200.00, 'WITHDRAWAL', TRUE),
(3, 20.00, 'DEPOSIT', TRUE),
(3, 10.00, 'WITHDRAWAL', TRUE);