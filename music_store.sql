

-- 1. TABLE SETUP & DATA INSERTION
-- Creating a schema similar to the Chinook database used in the video.

DROP TABLE IF EXISTS invoice_line;
DROP TABLE IF EXISTS invoice;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS track;
DROP TABLE IF EXISTS album;
DROP TABLE IF EXISTS artist;
DROP TABLE IF EXISTS genre;
DROP TABLE IF EXISTS media_type;
DROP TABLE IF EXISTS playlist_track;
DROP TABLE IF EXISTS playlist;

-- Create Tables
CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    last_name VARCHAR(50),
    first_name VARCHAR(50),
    title VARCHAR(50),
    reports_to INT,
    levels VARCHAR(10), -- Specific column mentioned in the video
    birth_date TIMESTAMP,
    hire_date TIMESTAMP,
    address VARCHAR(120),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(50),
    phone VARCHAR(50),
    fax VARCHAR(50),
    email VARCHAR(50)
);

CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    company VARCHAR(80),
    address VARCHAR(70),
    city VARCHAR(40),
    state VARCHAR(40),
    country VARCHAR(40),
    postal_code VARCHAR(10),
    phone VARCHAR(24),
    fax VARCHAR(24),
    email VARCHAR(60),
    support_rep_id INT
);

CREATE TABLE invoice (
    invoice_id INT PRIMARY KEY,
    customer_id INT,
    invoice_date TIMESTAMP,
    billing_address VARCHAR(70),
    billing_city VARCHAR(40),
    billing_state VARCHAR(40),
    billing_country VARCHAR(40),
    billing_postal_code VARCHAR(10),
    total DECIMAL(10,2)
);

CREATE TABLE invoice_line (
    invoice_line_id INT PRIMARY KEY,
    invoice_id INT,
    track_id INT,
    unit_price DECIMAL(10,2),
    quantity INT
);

CREATE TABLE artist (
    artist_id INT PRIMARY KEY,
    name VARCHAR(120)
);

CREATE TABLE album (
    album_id INT PRIMARY KEY,
    title VARCHAR(160),
    artist_id INT
);

CREATE TABLE track (
    track_id INT PRIMARY KEY,
    name VARCHAR(200),
    album_id INT,
    media_type_id INT,
    genre_id INT,
    composer VARCHAR(220),
    milliseconds INT,
    bytes INT,
    unit_price DECIMAL(10,2)
);

CREATE TABLE genre (
    genre_id INT PRIMARY KEY,
    name VARCHAR(120)
);

-- Insert Dummy Data
INSERT INTO employee (employee_id, last_name, first_name, levels, title, reports_to) VALUES
(1, 'Adams', 'Andrew', 'L5', 'General Manager', NULL),
(2, 'Edwards', 'Nancy', 'L4', 'Sales Manager', 1),
(3, 'Peacock', 'Jane', 'L3', 'Sales Support Agent', 2),
(9, 'Madan', 'Mohan', 'L7', 'Senior Engineer', 1); -- The senior-most in the video example

INSERT INTO customer (customer_id, first_name, last_name, email, country, support_rep_id) VALUES
(1, 'R', 'Madhav', 'madhav@gmail.com', 'India', 3),
(2, 'Mark', 'Taylor', 'mark@yahoo.com', 'Australia', 3),
(3, 'Diego', 'Gutierrez', 'diego@apple.com', 'Argentina', 3),
(4, 'Manoj', 'Kumar', 'manoj@yahoo.co.in', 'India', 3);

INSERT INTO invoice (invoice_id, customer_id, invoice_date, billing_city, billing_country, total) VALUES
(1, 1, '2022-01-01', 'Mumbai', 'India', 100.00),
(2, 2, '2022-01-02', 'Sydney', 'Australia', 50.00),
(3, 3, '2022-01-03', 'Buenos Aires', 'Argentina', 75.00),
(4, 4, '2022-01-04', 'Delhi', 'India', 25.00),
(5, 1, '2022-01-05', 'Mumbai', 'India', 50.00);

INSERT INTO artist (artist_id, name) VALUES (1, 'Queen'), (2, 'Metallica'), (3, 'Arijit Singh');
INSERT INTO album (album_id, title, artist_id) VALUES (1, 'Greatest Hits', 1), (2, 'Black Album', 2);
INSERT INTO genre (genre_id, name) VALUES (1, 'Rock'), (2, 'Pop'), (3, 'Metal');

INSERT INTO track (track_id, name, album_id, genre_id, milliseconds, unit_price) VALUES
(1, 'Bohemian Rhapsody', 1, 1, 354000, 0.99),
(2, 'Enter Sandman', 2, 3, 331000, 0.99),
(3, 'We Will Rock You', 1, 1, 122000, 0.99),
(4, 'Another One Bites The Dust', 1, 1, 215000, 0.99);

INSERT INTO invoice_line (invoice_line_id, invoice_id, track_id, unit_price, quantity) VALUES
(1, 1, 1, 0.99, 10),
(2, 1, 3, 0.99, 5),
(3, 2, 2, 0.99, 2),
(4, 3, 4, 0.99, 10);


-- =======================================================================================
-- 2. QUESTION SET 1: EASY
-- =======================================================================================

-- Q1: Who is the senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q2: Which countries have the most invoices?
SELECT COUNT(*) AS c, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;

-- Q3: What are top 3 values of total invoice?
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- Q4: Which city has the best customers? 
-- We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals.
SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;

-- Q5: Who is the best customer? 
-- The customer who has spent the most money will be declared the best customer.
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spending
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spending DESC
LIMIT 1;


-- =======================================================================================
-- 3. QUESTION SET 2: MODERATE
-- =======================================================================================

-- Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
-- Return your list ordered alphabetically by email starting with A.
SELECT DISTINCT email, first_name, last_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
ORDER BY email;

-- Q7: Let's invite the artists who have written the most rock music in our dataset.
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC
LIMIT 10;

-- Q8: Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) AS avg_track_length
    FROM track
)
ORDER BY milliseconds DESC;


-- =======================================================================================
-- 4. QUESTION SET 3: ADVANCED
-- =======================================================================================

-- Q9: Find how much amount spent by each customer on artists? 
-- Write a query to return customer name, artist name and total spent.
-- Logic: First find best selling artist, then find customer spending on that artist.

WITH best_selling_artist AS (
    SELECT artist.artist_id, artist.name AS artist_name, 
           SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM invoice_line
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
    GROUP BY 1, 2
    ORDER BY 3 DESC
    LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
       SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;


-- Q10: We want to find out the most popular music Genre for each country. 
-- We determine the most popular genre as the genre with the highest amount of purchases.
-- Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

WITH popular_genre AS (
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
           ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
    FROM invoice_line 
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY 2, 3, 4
)
SELECT * FROM popular_genre WHERE RowNo <= 1;


-- Q11: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH Customer_with_country AS (
    SELECT customer.customer_id, customer.first_name, customer.last_name, billing_country, SUM(total) AS total_spending,
           ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
    FROM invoice
    JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY 1, 2, 3, 4
)
SELECT * FROM Customer_with_country WHERE RowNo <= 1;