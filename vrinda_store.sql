
-- 1. SCHEMA SETUP
-- Creating the table to match the raw Excel data structure shown in the video.

DROP TABLE IF EXISTS vrinda_orders;

CREATE TABLE vrinda_orders (
    index INT PRIMARY KEY,
    order_id VARCHAR(20),
    cust_id VARCHAR(20),
    gender VARCHAR(10),         -- Dirty Data: Contains 'M', 'Men', 'W', 'Women'
    age INT,
    date DATE,
    status VARCHAR(50),         -- Delivered, Refunded, Returned, Cancelled
    channel VARCHAR(50),        -- Amazon, Flipkart, Myntra, etc.
    sku VARCHAR(50),
    category VARCHAR(50),       -- Kurta, Set, Western Dress
    size VARCHAR(10),
    qty VARCHAR(10),            -- Dirty Data: Contains '1', '2', 'One', 'Two'
    currency VARCHAR(5),
    amount INT,
    ship_city VARCHAR(50),
    ship_state VARCHAR(50),
    ship_postal_code VARCHAR(20),
    ship_country VARCHAR(20),
    b2b BOOLEAN
);

-- =======================================================================================
-- 2. DATA INSERTION (DUMMY DATA)
-- Inserting sample data that mimics the "dirty" state seen in the video.
-- =======================================================================================

INSERT INTO vrinda_orders VALUES
(1, '405-8078784-5731545', '1714029', 'Women', 44, '2022-12-04', 'Delivered', 'Myntra', 'JNE3781-KR-XXL', 'Kurta', 'XXL', '1', 'INR', 699, 'BENGALURU', 'KARNATAKA', '560029', 'IN', FALSE),
(2, '171-9198151-1101146', '1710168', 'Men', 29, '2022-12-04', 'Delivered', 'Amazon', 'JNE3781-KR-XXL', 'Kurta', 'XXL', '1', 'INR', 649, 'NAVI MUMBAI', 'MAHARASHTRA', '410210', 'IN', FALSE),
(3, '404-0687676-7273146', '1710140', 'W', 67, '2022-12-04', 'Delivered', 'Amazon', 'JNE3781-KR-XXL', 'Kurta', 'XXL', 'One', 'INR', 699, 'GHAZIABAD', 'UTTAR PRADESH', '201009', 'IN', FALSE),
(4, '403-9615377-8133951', '1710092', 'M', 20, '2022-12-04', 'Delivered', 'Myntra', 'JNE3781-KR-XXL', 'Kurta', 'XXL', '1', 'INR', 699, 'CHANDIGARH', 'CHANDIGARH', '160017', 'IN', FALSE),
(5, '407-1069790-7240320', '1709996', 'Women', 62, '2022-12-04', 'Delivered', 'Amazon', 'JNE3781-KR-XXL', 'Kurta', 'XXL', '1', 'INR', 699, 'SRINAGAR', 'JAMMU & KASHMIR', '190011', 'IN', FALSE),
(6, '404-1490984-4565156', '1709663', 'Women', 49, '2022-12-04', 'Delivered', 'Flipkart', 'JNE3405-KR-L', 'Kurta', 'L', 'One', 'INR', 399, 'HYDERABAD', 'TELANGANA', '500072', 'IN', FALSE),
(7, '408-5748499-6859555', '1709538', 'Women', 19, '2022-12-04', 'Delivered', 'Ajio', 'JNE3405-KR-L', 'Kurta', 'L', 'Two', 'INR', 798, 'MEERUT', 'UTTAR PRADESH', '250001', 'IN', FALSE),
(8, '406-7807733-3785945', '1709202', 'M', 28, '2022-12-04', 'Delivered', 'Amazon', 'JNE3405-KR-L', 'Kurta', 'L', '1', 'INR', 399, 'ZIRAKPUR', 'PUNJAB', '140603', 'IN', FALSE),
(9, '407-1069790-7240321', '1709997', 'W', 45, '2022-03-15', 'Returned', 'Amazon', 'JNE3781-KR-M', 'Kurta', 'M', '1', 'INR', 699, 'CHENNAI', 'TAMIL NADU', '600001', 'IN', FALSE),
(10, '404-1490984-4565157', '1709664', 'Men', 35, '2022-01-10', 'Delivered', 'Flipkart', 'JNE3405-KR-S', 'Kurta', 'S', '2', 'INR', 798, 'NEW DELHI', 'DELHI', '110001', 'IN', FALSE);


-- =======================================================================================
-- 3. DATA CLEANING (SQL Step-by-Step)
-- The video emphasizes standardizing specific columns.
-- =======================================================================================

-- 1. Standardize Gender
-- Video Issue: 'M' vs 'Men' and 'W' vs 'Women'.
-- Solution: Standardize everything to 'Men' and 'Women'.
UPDATE vrinda_orders
SET gender = CASE 
    WHEN gender = 'M' THEN 'Men'
    WHEN gender = 'W' THEN 'Women'
    ELSE gender 
END;

-- 2. Standardize Quantity (Qty)
-- Video Issue: 'One' vs '1', 'Two' vs '2'.
-- Solution: Convert text to numbers.
UPDATE vrinda_orders
SET qty = CASE 
    WHEN qty = 'One' THEN '1'
    WHEN qty = 'Two' THEN '2'
    ELSE qty 
END;

-- Cast Qty to Integer for calculations (Optional but recommended)
ALTER TABLE vrinda_orders 
ALTER COLUMN qty TYPE INT 
USING qty::INTEGER;


-- =======================================================================================
-- 4. DATA PROCESSING (Feature Engineering)
-- Creating new "columns" (Age Group, Month) required for the dashboard.
-- =======================================================================================

-- 1. Age Grouping
-- Logic from video: >= 50 is Senior, >= 30 is Adult, < 30 is Teenager.
-- In SQL, we can use a View or CTE for this. Here, I'll add a column for persistence.
ALTER TABLE vrinda_orders ADD COLUMN age_group VARCHAR(20);

UPDATE vrinda_orders
SET age_group = CASE 
    WHEN age >= 50 THEN 'Senior'
    WHEN age >= 30 THEN 'Adult'
    ELSE 'Teenager'
END;

-- 2. Extract Month
-- The dashboard requires monthly analysis.
-- In PostgreSQL, we can extract this dynamically in queries using TO_CHAR(date, 'Month').


-- =======================================================================================
-- 5. DASHBOARD ANALYSIS QUERIES
-- Recreating the Insights and Charts shown in the Excel Dashboard.
-- =======================================================================================

-- Insight 1: Compare Sales and Orders (Single Chart)
-- Shows Total Sales Amount and Count of Orders per Month.
SELECT 
    TO_CHAR(date, 'Month') AS month_name,
    EXTRACT(MONTH FROM date) AS month_num, -- For sorting
    SUM(amount) AS total_sales,
    COUNT(order_id) AS total_orders
FROM vrinda_orders
GROUP BY 1, 2
ORDER BY 2;

-- Insight 2: Highest Sales & Orders Month
-- Simply ORDER BY the result above DESC.
SELECT 
    TO_CHAR(date, 'Month') AS month_name,
    SUM(amount) AS total_sales
FROM vrinda_orders
GROUP BY 1
ORDER BY total_sales DESC
LIMIT 1;

-- Insight 3: Men vs Women Purchases (Who buys more?)
-- Pie Chart Data: Percentage share of sales by Gender.
SELECT 
    gender,
    SUM(amount) AS total_sales,
    ROUND((SUM(amount) * 100.0 / (SELECT SUM(amount) FROM vrinda_orders)), 2) AS percentage_share
FROM vrinda_orders
GROUP BY gender;

-- Insight 4: Order Status Analysis
-- Pie Chart Data: Breakdown of Delivered vs Returned/Cancelled.
SELECT 
    status,
    COUNT(order_id) AS order_count
FROM vrinda_orders
GROUP BY status;

-- Insight 5: Top 5 States Contributing to Sales
-- Horizontal Bar Chart Data.
SELECT 
    ship_state,
    SUM(amount) AS total_sales
FROM vrinda_orders
GROUP BY ship_state
ORDER BY total_sales DESC
LIMIT 5;

-- Insight 6: Relation between Age & Gender (Who buys more?)
-- Column Chart Data: Sales broken down by Age Group and Gender.
SELECT 
    age_group,
    gender,
    COUNT(order_id) AS total_orders
FROM vrinda_orders
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- Insight 7: Channel Contribution
-- Pie/Bar Chart: Which channel (Amazon, Myntra, etc.) drives the most sales?
SELECT 
    channel,
    SUM(amount) AS total_sales,
    ROUND((SUM(amount) * 100.0 / (SELECT SUM(amount) FROM vrinda_orders)), 2) AS contribution_pct
FROM vrinda_orders
GROUP BY channel
ORDER BY total_sales DESC;