
-- 1. DATABASE & TABLE SETUP
-- We will create the normalized tables described in the video:
-- Orders, Customers, Address, Item, Ingredient, Recipe, Inventory, Staff, Shift, Rota

DROP TABLE IF EXISTS rota;
DROP TABLE IF EXISTS shift;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS recipe;
DROP TABLE IF EXISTS ingredient;
DROP TABLE IF EXISTS item;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS address;
DROP TABLE IF EXISTS customers;

-- A. CUSTOMER & ORDER TABLES
CREATE TABLE customers (
    cust_id INT PRIMARY KEY,
    cust_firstname VARCHAR(50),
    cust_lastname VARCHAR(50),
    cust_email VARCHAR(100),
    cust_phone VARCHAR(20)
);

CREATE TABLE address (
    add_id INT PRIMARY KEY,
    delivery_address1 VARCHAR(255),
    delivery_address2 VARCHAR(255),
    delivery_city VARCHAR(50),
    delivery_zipcode VARCHAR(20)
);

CREATE TABLE item (
    item_id VARCHAR(10) PRIMARY KEY, -- 'sku' in video context
    item_name VARCHAR(100),
    item_cat VARCHAR(50), -- Pizza, Side, Beverage
    item_size VARCHAR(20),
    item_price DECIMAL(10,2)
);

CREATE TABLE orders (
    row_id SERIAL PRIMARY KEY,
    order_id VARCHAR(20),
    created_at TIMESTAMP,
    item_id VARCHAR(10), -- Links to item.item_id (sku)
    quantity INT,
    cust_id INT,
    delivery BOOLEAN, -- TRUE for delivery, FALSE for pick-up
    add_id INT
);

-- B. INVENTORY TABLES
CREATE TABLE ingredient (
    ing_id VARCHAR(10) PRIMARY KEY,
    ing_name VARCHAR(100),
    ing_weight INT, -- Weight in grams/ml that the ingredient is bought in
    ing_meas VARCHAR(20), -- grams, ml, etc.
    ing_price DECIMAL(10,2) -- Price per unit bought
);

CREATE TABLE recipe (
    row_id SERIAL PRIMARY KEY,
    recipe_id VARCHAR(20), -- This links to item.item_id (The Pizza SKU)
    ing_id VARCHAR(10),    -- Links to ingredient.ing_id
    quantity INT           -- Amount of ingredient used in this recipe (grams)
);

CREATE TABLE inventory (
    inv_id SERIAL PRIMARY KEY,
    item_id VARCHAR(10), -- Links to ingredient.ing_id
    quantity INT         -- Number of units in stock
);

-- C. STAFF TABLES
CREATE TABLE staff (
    staff_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    position VARCHAR(50),
    hourly_rate DECIMAL(10,2)
);

CREATE TABLE shift (
    shift_id VARCHAR(10) PRIMARY KEY,
    day_of_week VARCHAR(20),
    start_time TIME,
    end_time TIME
);

CREATE TABLE rota (
    row_id SERIAL PRIMARY KEY,
    rota_id VARCHAR(20),
    date DATE,
    shift_id VARCHAR(10),
    staff_id VARCHAR(10)
);

-- =======================================================================================
-- 2. DUMMY DATA (For Testing)
-- =======================================================================================

-- Sample Ingredients (Flour, Tomatoes, Cheese)
INSERT INTO ingredient VALUES 
('ING001', 'Pizza Dough Ball', 200, 'g', 1.00),
('ING002', 'Mozzarella', 1000, 'g', 15.00),
('ING003', 'Tomato Sauce', 1000, 'ml', 5.00);

-- Sample Items (Margherita Pizza)
INSERT INTO item VALUES ('sku_marg', 'Pizza Margherita', 'Pizza', 'Regular', 12.50);

-- Sample Recipe (Margherita requires Dough, Cheese, Sauce)
INSERT INTO recipe (recipe_id, ing_id, quantity) VALUES 
('sku_marg', 'ING001', 200), -- 200g dough
('sku_marg', 'ING002', 100), -- 100g cheese
('sku_marg', 'ING003', 80);  -- 80ml sauce

-- Sample Inventory
INSERT INTO inventory (item_id, quantity) VALUES 
('ING001', 50), -- 50 balls of dough
('ING002', 10), -- 10kg cheese
('ING003', 20); -- 20 liters sauce

-- Sample Orders
INSERT INTO orders (order_id, created_at, item_id, quantity, delivery) VALUES 
('ORD-001', '2023-10-01 12:30:00', 'sku_marg', 2, TRUE),
('ORD-002', '2023-10-01 13:00:00', 'sku_marg', 1, FALSE);

-- Sample Staff & Shift
INSERT INTO staff VALUES ('ST01', 'Ben', 'Chef', 'Chef', 25.00);
INSERT INTO shift VALUES ('SH01', 'Monday', '10:00', '14:00'); -- 4 hours
INSERT INTO rota (date, shift_id, staff_id) VALUES ('2023-10-01', 'SH01', 'ST01');


-- =======================================================================================
-- 3. CUSTOM SQL QUERIES (DASHBOARD METRICS)
-- =======================================================================================

-- ---------------------------------------------------------------------------------------
-- QUERY 1: ORDER ACTIVITY
-- Joins Orders, Item, and Address tables to get full details for the main dashboard.
-- ---------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_orders_summary AS
SELECT 
    o.order_id,
    i.item_price,
    o.quantity,
    i.item_cat,
    i.item_name,
    o.created_at,
    o.delivery,
    a.delivery_address1,
    a.delivery_city,
    a.delivery_zipcode
FROM orders o
LEFT JOIN item i ON o.item_id = i.item_id
LEFT JOIN address a ON o.add_id = a.add_id;


-- ---------------------------------------------------------------------------------------
-- QUERY 2: INVENTORY & STOCK COST
-- Calculates how much stock was used vs. how much is remaining.
-- Formula: (Order Qty * Recipe Qty) = Total Ingredient Weight Used
-- Cost Formula: (Ingredient Price / Ingredient Weight) = Cost Per Gram
-- ---------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_stock_calculations AS
WITH ordered_weight_calc AS (
    SELECT 
        o.item_id,
        i.item_name,
        r.ing_id,
        ing.ing_name,
        r.quantity AS recipe_quantity,
        SUM(o.quantity) as order_quantity,
        ing.ing_weight,
        ing.ing_price
    FROM orders o
    LEFT JOIN item i ON o.item_id = i.item_id
    LEFT JOIN recipe r ON i.item_id = r.recipe_id
    LEFT JOIN ingredient ing ON r.ing_id = ing.ing_id
    GROUP BY o.item_id, i.item_name, r.ing_id, r.quantity, ing.ing_name, ing.ing_weight, ing.ing_price
)
SELECT 
    item_name,
    ing_name,
    order_quantity,
    recipe_quantity,
    (order_quantity * recipe_quantity) AS total_ordered_weight,
    ing_price,
    (ing_price / ing_weight) AS unit_cost,
    ((order_quantity * recipe_quantity) * (ing_price / ing_weight)) AS ingredient_cost
FROM ordered_weight_calc;


-- ---------------------------------------------------------------------------------------
-- QUERY 3: STAFF COSTS
-- Calculates hours worked and total cost.
-- MySQL uses TIMEDIFF. In PostgreSQL, we subtract times and extract EPOCH to get seconds.
-- ---------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_staff_costs AS
SELECT 
    r.date,
    s.first_name,
    s.last_name,
    s.hourly_rate,
    sh.start_time,
    sh.end_time,
    -- Calculate Hours Worked: (EndTime - StartTime) -> Interval -> Seconds -> Hours
    (EXTRACT(EPOCH FROM (sh.end_time - sh.start_time)) / 3600) AS hours_worked,
    -- Calculate Cost: Hours * Rate
    ((EXTRACT(EPOCH FROM (sh.end_time - sh.start_time)) / 3600) * s.hourly_rate) AS staff_cost
FROM rota r
LEFT JOIN staff s ON r.staff_id = s.staff_id
LEFT JOIN shift sh ON r.shift_id = sh.shift_id;

-- VERIFY RESULTS
SELECT * FROM view_staff_costs;