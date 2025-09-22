-- Create tables
CREATE TABLE authors (
    author_id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(100),
    author_id INT,
    published_year INT,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

-- Insert sample data
INSERT INTO authors VALUES (1, 'J.K. Rowling'), (2, 'George Orwell');
INSERT INTO books VALUES (1, 'Harry Potter', 1, 1997), (2, '1984', 2, 1949);

-- Query: List all books with authors
SELECT b.title, a.name AS author, b.published_year
FROM books b
JOIN authors a ON b.author_id = a.author_id;