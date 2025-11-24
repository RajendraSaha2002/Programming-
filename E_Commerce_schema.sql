CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- 2. Products Table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50)
);

-- 3. Orders (Purchase History)
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    product_id INT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- 4. Recommendations Table (Populated by Python)
CREATE TABLE IF NOT EXISTS recommendations (
    user_id INT,
    product_id INT,
    score DOUBLE, -- Confidence score
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    PRIMARY KEY (user_id, product_id)
);

-- SEED DATA
INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie'), ('Dave');

INSERT INTO products (name, category) VALUES 
('Laptop', 'Electronics'),
('Wireless Mouse', 'Electronics'),
('Mechanical Keyboard', 'Electronics'),
('Coffee Mug', 'Home'),
('Water Bottle', 'Home');

-- SEED HISTORY (Patterns)
-- Alice bought Laptop & Mouse
INSERT INTO orders (user_id, product_id) VALUES (1, 1), (1, 2);
-- Bob bought Laptop, Mouse & Keyboard (Strong correlation)
INSERT INTO orders (user_id, product_id) VALUES (2, 1), (2, 2), (2, 3);
-- Charlie bought Laptop (Should be recommended Mouse & Keyboard)
INSERT INTO orders (user_id, product_id) VALUES (3, 1);