

-- 1. TABLE SETUP
-- Creating the sales table as described in the video (04:00)

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    invoice_id VARCHAR(30) PRIMARY KEY,
    branch VARCHAR(5),
    city VARCHAR(30),
    customer_type VARCHAR(30),
    gender VARCHAR(10),
    product_line VARCHAR(100),
    unit_price DECIMAL(10, 2),
    quantity INT,
    vat FLOAT, -- Value Added Tax (5%)
    total DECIMAL(12, 4),
    date DATE,
    time TIME,
    payment_method VARCHAR(15),
    cogs DECIMAL(10, 2), -- Cost of Goods Sold
    gross_margin_pct FLOAT,
    gross_income DECIMAL(12, 4),
    rating FLOAT
);

-- 2. DUMMY DATA INSERTION
-- Since we don't have the CSV, inserting sample data to make queries runnable.
INSERT INTO sales VALUES
('1001', 'A', 'Yangon', 'Member', 'Female', 'Health and beauty', 74.69, 7, 26.14, 548.97, '2019-01-05', '13:08:00', 'Ewallet', 522.83, 4.76, 26.14, 9.1),
('1002', 'C', 'Naypyitaw', 'Normal', 'Female', 'Electronic accessories', 15.28, 5, 3.82, 80.22, '2019-01-12', '10:29:00', 'Cash', 76.40, 4.76, 3.82, 9.6),
('1003', 'A', 'Yangon', 'Normal', 'Male', 'Home and lifestyle', 46.33, 7, 16.22, 340.52, '2019-03-03', '12:20:00', 'Credit card', 324.31, 4.76, 16.22, 7.4),
('1004', 'B', 'Mandalay', 'Member', 'Male', 'Health and beauty', 56.50, 2, 5.65, 118.65, '2019-02-15', '19:15:00', 'Cash', 113.00, 4.76, 5.65, 8.5),
('1005', 'B', 'Mandalay', 'Member', 'Female', 'Sports and travel', 90.00, 1, 4.50, 94.50, '2019-02-20', '09:10:00', 'Ewallet', 90.00, 4.76, 4.50, 6.5);


-- =======================================================================================
-- 3. FEATURE ENGINEERING (Timestamp 20:37)
-- =======================================================================================

-- A. TIME OF DAY
-- Add a column to categorize time into Morning, Afternoon, Evening
ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

-- Update the column using CASE statement
UPDATE sales
SET time_of_day = (
    CASE
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END
);

-- B. DAY NAME
-- Add a column for the day of the week (Mon, Tue, Wed)
ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

-- Postgres uses TO_CHAR(date, 'Day') instead of MySQL's DAYNAME()
UPDATE sales
SET day_name = TRIM(TO_CHAR(date, 'Day'));

-- C. MONTH NAME
-- Add a column for the month name (Jan, Feb, Mar)
ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

-- Postgres uses TO_CHAR(date, 'Month') instead of MySQL's MONTHNAME()
UPDATE sales
SET month_name = TRIM(TO_CHAR(date, 'Month'));


-- =======================================================================================
-- 4. BUSINESS QUESTIONS & EXPLORATORY DATA ANALYSIS (EDA)
-- =======================================================================================

-- ---------------------------------------------------------------------------------------
-- GENERIC QUESTIONS
-- ---------------------------------------------------------------------------------------

-- Q1: How many unique cities does the data have?
SELECT DISTINCT city FROM sales;

-- Q2: In which city is each branch?
SELECT DISTINCT branch, city FROM sales;


-- ---------------------------------------------------------------------------------------
-- PRODUCT QUESTIONS
-- ---------------------------------------------------------------------------------------

-- Q3: How many unique product lines does the data have?
SELECT COUNT(DISTINCT product_line) FROM sales;

-- Q4: What is the most common payment method?
SELECT payment_method, COUNT(*) AS count
FROM sales
GROUP BY payment_method
ORDER BY count DESC;

-- Q5: What is the most selling product line?
SELECT product_line, COUNT(*) AS count
FROM sales
GROUP BY product_line
ORDER BY count DESC;

-- Q6: What is the total revenue by month?
SELECT month_name AS month, SUM(total) AS total_revenue
FROM sales
GROUP BY month_name
ORDER BY total_revenue DESC;

-- Q7: What month had the largest COGS (Cost of Goods Sold)?
SELECT month_name AS month, SUM(cogs) AS cogs
FROM sales
GROUP BY month_name
ORDER BY cogs DESC;

-- Q8: What product line had the largest revenue?
SELECT product_line, SUM(total) AS total_revenue
FROM sales
GROUP BY product_line
ORDER BY total_revenue DESC;

-- Q9: What city had the largest revenue?
SELECT branch, city, SUM(total) AS total_revenue
FROM sales
GROUP BY branch, city
ORDER BY total_revenue DESC;

-- Q10: What product line had the largest VAT?
SELECT product_line, AVG(vat) AS avg_tax
FROM sales
GROUP BY product_line
ORDER BY avg_tax DESC;

-- Q11: Which branch sold more products than average product sold?
SELECT branch, SUM(quantity) AS qty
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

-- Q12: What is the most common product line by gender?
SELECT gender, product_line, COUNT(gender) AS total_cnt
FROM sales
GROUP BY gender, product_line
ORDER BY total_cnt DESC;

-- Q13: What is the average rating of each product line?
SELECT product_line, ROUND(AVG(rating)::numeric, 2) AS avg_rating
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;