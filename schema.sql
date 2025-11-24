CREATE DATABASE IF NOT EXISTS inventory_ml;
USE inventory_ml;

-- Table to store product details and the latest prediction
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    current_price DOUBLE NOT NULL,
    predicted_next_price DOUBLE DEFAULT 0.0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table to store historical price data for ML training
CREATE TABLE IF NOT EXISTS price_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    price DOUBLE NOT NULL,
    recorded_date DATE NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Seed some initial data for testing
INSERT INTO products (name, current_price) VALUES 
('Gaming Laptop', 1200.00),
('Wireless Mouse', 25.50),
('Mechanical Keyboard', 85.00);

-- Seed history for the Laptop (Simulating price drop over time)
INSERT INTO price_history (product_id, price, recorded_date) VALUES
(1, 1300.00, DATE_SUB(CURDATE(), INTERVAL 5 DAY)),
(1, 1280.00, DATE_SUB(CURDATE(), INTERVAL 4 DAY)),
(1, 1250.00, DATE_SUB(CURDATE(), INTERVAL 3 DAY)),
(1, 1220.00, DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
(1, 1200.00, DATE_SUB(CURDATE(), INTERVAL 1 DAY));