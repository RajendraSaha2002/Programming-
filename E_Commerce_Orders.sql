-- Create tables
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(8,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Insert sample data
INSERT INTO customers VALUES (1, 'John Doe'), (2, 'Jane Smith');
INSERT INTO products VALUES (1, 'Laptop', 1200.00), (2, 'Mouse', 25.00);
INSERT INTO orders VALUES (1, 1, '2025-09-20'), (2, 2, '2025-09-21');
INSERT INTO order_items VALUES (1, 1, 1), (1, 2, 2), (2, 2, 1);

-- Query: List all orders with customer and total amount
SELECT o.order_id, c.name AS customer, SUM(p.price * oi.quantity) AS total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_id, c.name;