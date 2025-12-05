-- Run this in your PostgreSQL Query Tool (pgAdmin or PyCharm Database Tool)

-- 1. Create the database (Optional, if you don't have one)
-- CREATE DATABASE library_db;

-- 2. Connect to your database and run this table creation
CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    author VARCHAR(100) NOT NULL,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    published_date DATE DEFAULT CURRENT_DATE
);

-- 3. Seed some initial data
INSERT INTO books (title, author, isbn) VALUES 
('The Great Gatsby', 'F. Scott Fitzgerald', '9780743273565'),
('1984', 'George Orwell', '9780451524935'),
('Python Crash Course', 'Eric Matthes', '9781593279288')
ON CONFLICT (isbn) DO NOTHING;