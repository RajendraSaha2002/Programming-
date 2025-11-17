/*******************************************************************************
** Library Management Database Script
**
** This script defines the schema, populates tables with sample data, and
** provides analytical queries for a system managing books, patrons, and loans.
*******************************************************************************/

-- Current Run Date for Loan Analysis: 2025-10-06

-- =============================================================================
-- 0. CLEANUP (DROP TABLES)
--    The DROP TABLE IF EXISTS commands ensure the script is idempotent and can be
--    run multiple times without throwing the "already exists" error.
--    Tables with foreign keys (e.g., loans) must be dropped before the tables
--    they reference (e.g., books, patrons).
--    NOTE: The "NOTICE: table does not exist, skipping" messages are normal during this cleanup step.
-- =============================================================================
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS patrons;
DROP TABLE IF EXISTS authors;


-- =============================================================================
-- 1. SCHEMA DEFINITION (DDL)
-- =============================================================================

-- Table 1: authors
CREATE TABLE authors (
    author_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_year INT
);

-- Table 2: books
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author_id INT,
    isbn VARCHAR(20) UNIQUE,
    publication_year INT,
    genre VARCHAR(50), -- e.g., 'Fiction', 'Biography', 'Science'
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

-- Table 3: patrons - Library members
CREATE TABLE patrons (
    patron_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    membership_date DATE,
    city VARCHAR(100)
);

-- Table 4: loans - Tracks which book is checked out by which patron
CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    book_id INT,
    patron_id INT,
    checkout_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE, -- NULL if not yet returned
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (patron_id) REFERENCES patrons(patron_id)
);

-- =============================================================================
-- 2. SAMPLE DATA INSERTION (DML)
-- =============================================================================

-- AUTHORS
INSERT INTO authors (author_id, first_name, last_name, birth_year) VALUES
(101, 'J.R.R.', 'Tolkien', 1892),
(102, 'Toni', 'Morrison', 1931),
(103, 'Carl', 'Sagan', 1934);

-- BOOKS
INSERT INTO books (book_id, title, author_id, isbn, publication_year, genre) VALUES
(201, 'The Hobbit', 101, '9780345339683', 1937, 'Fantasy'),
(202, 'Beloved', 102, '9781400033416', 1987, 'Historical Fiction'),
(203, 'Cosmos', 103, '9780345539434', 1980, 'Science'),
(204, 'The Silmarillion', 101, '9780618391113', 1977, 'Fantasy'),
(205, 'Sula', 102, '9781400078752', 1973, 'Fiction');

-- PATRONS
INSERT INTO patrons (patron_id, first_name, last_name, membership_date, city) VALUES
(301, 'Alex', 'Chen', '2023-01-20', 'Willow Creek'),
(302, 'Maria', 'Garcia', '2023-05-15', 'Central City'),
(303, 'Ethan', 'Kim', '2024-03-01', 'Willow Creek');

-- LOANS
INSERT INTO loans (loan_id, book_id, patron_id, checkout_date, due_date, return_date) VALUES
(401, 201, 301, '2025-09-01', '2025-09-22', '2025-09-20'), -- Returned (On Time)
(402, 202, 302, '2025-09-10', '2025-10-01', '2025-10-05'), -- Returned (Late)
(403, 203, 303, '2025-09-25', '2025-10-16', NULL),         -- Currently checked out
(404, 201, 302, '2025-10-01', '2025-10-22', NULL),         -- Currently checked out
(405, 205, 301, '2025-09-15', '2025-10-01', NULL);         -- Currently overdue (as of 2025-10-06)


-- =============================================================================
-- 3. 5 KEY LIBRARY MANAGEMENT ANALYSIS QUERIES (DQL)
-- =============================================================================

-- QUERY 1: Currently Overdue Books (As of 2025-10-06)
-- Purpose: Identify books that are past their due date and have not been returned.
-------------------------------------------------------------------------------
SELECT
    b.title,
    p.first_name || ' ' || p.last_name AS patron_name,
    l.checkout_date,
    l.due_date
FROM
    loans l
JOIN
    books b ON l.book_id = b.book_id
JOIN
    patrons p ON l.patron_id = p.patron_id
WHERE
    l.return_date IS NULL AND l.due_date < '2025-10-06'
ORDER BY
    l.due_date;

-- QUERY 2: Most Popular Books by Total Checkout Count
-- Purpose: Find out which titles are in highest demand to inform reordering decisions.
-------------------------------------------------------------------------------
SELECT
    b.title,
    a.first_name || ' ' || a.last_name AS author_name,
    COUNT(l.loan_id) AS total_checkouts
FROM
    books b
JOIN
    authors a ON b.author_id = a.author_id
LEFT JOIN
    loans l ON b.book_id = l.book_id
GROUP BY
    b.book_id, b.title, author_name
ORDER BY
    total_checkouts DESC;

-- QUERY 3: Top Patrons by Total Books Borrowed
-- Purpose: Identify the most active members for loyalty programs or targeted communications.
-------------------------------------------------------------------------------
SELECT
    p.first_name || ' ' || p.last_name AS patron_name,
    p.city,
    COUNT(l.loan_id) AS total_books_borrowed
FROM
    patrons p
JOIN
    loans l ON p.patron_id = l.patron_id
GROUP BY
    p.patron_id, patron_name, p.city
ORDER BY
    total_books_borrowed DESC;

-- QUERY 4: Average Loan Duration by Genre (in days)
-- Purpose: Analyze how long different genres are typically kept by patrons.
-------------------------------------------------------------------------------
SELECT
    b.genre,
    -- CORRECTED: Standard SQL/PostgreSQL subtraction of two DATE fields yields the difference in days (an integer/numeric result).
    CAST(AVG(l.return_date - l.checkout_date) AS INT) AS avg_loan_duration_days
FROM
    loans l
JOIN
    books b ON l.book_id = b.book_id
WHERE
    l.return_date IS NOT NULL -- Only calculate for returned books
GROUP BY
    b.genre
ORDER BY
    avg_loan_duration_days DESC;

-- QUERY 5: Inventory Check: How many copies of "Fantasy" books are currently checked out?
-- Purpose: Get a quick count of high-demand genres that are unavailable.
-------------------------------------------------------------------------------
SELECT
    b.genre,
    COUNT(l.loan_id) AS currently_checked_out
FROM
    loans l
JOIN
    books b ON l.book_id = b.book_id
WHERE
    b.genre = 'Fantasy'
    AND l.return_date IS NULL
GROUP BY
    b.genre;
