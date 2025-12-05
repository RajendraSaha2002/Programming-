-- Run this in your PostgreSQL Query Tool (pgAdmin or PyCharm)

-- 1. Create Database (Optional)
-- CREATE DATABASE shop_inventory_db;

-- 2. Create Suppliers Table (Parent)
CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20)
);

-- 3. Create Products Table (Child with Foreign Key)
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock_count INT NOT NULL,
    supplier_id INT,
    CONSTRAINT fk_supplier
        FOREIGN KEY(supplier_id) 
        REFERENCES suppliers(id)
        ON DELETE SET NULL -- If supplier is deleted, keep product but nullify supplier
);

-- 4. Seed Data
INSERT INTO suppliers (name, phone) VALUES 
('Acme Corp', '555-0100'),
('Global Tech', '555-0200'),
('Fresh Foods Ltd', '555-0300');

INSERT INTO products (name, price, stock_count, supplier_id) VALUES 
('Gaming Mouse', 45.00, 10, 2),
('Mechanical Keyboard', 85.50, 5, 2),
('Office Chair', 120.00, 15, 1),
('Organic Apples', 2.50, 100, 3);