CREATE DATABASE IF NOT EXISTS sales_db;
USE sales_db;

-- 1. Raw Sales Data (Transactional)
CREATE TABLE IF NOT EXISTS sales_raw (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    amount DOUBLE NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE DEFAULT (CURRENT_DATE)
);

-- 2. Daily Summary (Analytical/ETL Output)
CREATE TABLE IF NOT EXISTS sales_summary (
    report_date DATE PRIMARY KEY,
    total_revenue DOUBLE DEFAULT 0.0,
    total_items_sold INT DEFAULT 0,
    top_product VARCHAR(100),
    last_calculated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SEED DATA (Previous Days)
INSERT INTO sales_raw (product_name, amount, quantity, sale_date) VALUES 
('Laptop', 1200.00, 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
('Mouse', 20.00, 5, DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
('Laptop', 1200.00, 2, DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
('Keyboard', 50.00, 3, DATE_SUB(CURDATE(), INTERVAL 1 DAY));