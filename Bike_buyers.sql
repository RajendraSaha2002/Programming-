
-- 1. SCHEMA SETUP
-- Creating the table to match the raw Excel data structure (approx timestamp 02:21)

DROP TABLE IF EXISTS bike_buyers;

CREATE TABLE bike_buyers (
    id INT PRIMARY KEY,
    marital_status VARCHAR(10), -- Currently 'M' or 'S'
    gender VARCHAR(10),         -- Currently 'F' or 'M'
    income DECIMAL(10,2),
    children INT,
    education VARCHAR(50),
    occupation VARCHAR(50),
    home_owner VARCHAR(5),      -- 'Yes' or 'No'
    cars INT,
    commute_distance VARCHAR(20),
    region VARCHAR(50),
    age INT,
    purchased_bike VARCHAR(5)   -- 'Yes' or 'No'
);

-- =======================================================================================
-- 2. DATA INSERTION (DUMMY DATA)
-- Inserting sample data that mimics the variety seen in the video 
-- (e.g., Different regions, income levels, commute distances, and ages).
-- =======================================================================================

INSERT INTO bike_buyers (id, marital_status, gender, income, children, education, occupation, home_owner, cars, commute_distance, region, age, purchased_bike) VALUES
(12496, 'M', 'F', 40000, 1, 'Bachelors', 'Skilled Manual', 'Yes', 0, '0-1 Miles', 'Europe', 42, 'No'),
(24107, 'M', 'M', 30000, 3, 'Partial College', 'Clerical', 'Yes', 1, '0-1 Miles', 'Europe', 43, 'No'),
(14177, 'M', 'M', 80000, 5, 'Partial College', 'Professional', 'No', 2, '2-5 Miles', 'Europe', 60, 'No'),
(24381, 'S', 'M', 70000, 0, 'Bachelors', 'Professional', 'Yes', 1, '5-10 Miles', 'Pacific', 41, 'Yes'),
(25597, 'S', 'M', 30000, 0, 'Bachelors', 'Clerical', 'No', 0, '0-1 Miles', 'Europe', 36, 'Yes'),
(13507, 'M', 'F', 10000, 2, 'Partial College', 'Manual', 'Yes', 0, '1-2 Miles', 'Europe', 50, 'No'),
(27974, 'S', 'M', 160000, 2, 'High School', 'Management', 'Yes', 4, '0-1 Miles', 'Pacific', 33, 'Yes'),
(19364, 'M', 'M', 40000, 1, 'Bachelors', 'Skilled Manual', 'Yes', 0, '0-1 Miles', 'Europe', 43, 'Yes'),
(22155, 'M', 'F', 20000, 2, 'Partial High School', 'Clerical', 'Yes', 2, '5-10 Miles', 'Pacific', 58, 'No'),
(19280, 'M', 'M', 120000, 2, 'Bachelors', 'Management', 'Yes', 1, '0-1 Miles', 'Europe', 40, 'Yes'),
(22173, 'M', 'F', 30000, 3, 'High School', 'Skilled Manual', 'No', 2, '1-2 Miles', 'Pacific', 54, 'Yes'),
(12697, 'S', 'F', 90000, 0, 'Bachelors', 'Professional', 'No', 4, '10+ Miles', 'Pacific', 27, 'No'),
(11434, 'M', 'M', 170000, 5, 'Partial College', 'Professional', 'Yes', 0, '0-1 Miles', 'Europe', 55, 'No'),
(25323, 'M', 'M', 40000, 2, 'Partial College', 'Clerical', 'Yes', 1, '1-2 Miles', 'Europe', 35, 'Yes'),
(23542, 'S', 'F', 60000, 1, 'Bachelors', 'Skilled Manual', 'No', 1, '0-1 Miles', 'Pacific', 45, 'Yes');


-- =======================================================================================
-- 3. DATA CLEANING (SQL Step-by-Step)
-- The video spends significant time standardizing columns. We do this with UPDATE.
-- =======================================================================================

-- Video Step 1: Standardize Marital Status (M -> Married, S -> Single)
-- Timestamp approx 04:40
UPDATE bike_buyers
SET marital_status = CASE 
    WHEN marital_status = 'M' THEN 'Married'
    WHEN marital_status = 'S' THEN 'Single'
    ELSE marital_status 
END;

-- Video Step 2: Standardize Gender (M -> Male, F -> Female)
UPDATE bike_buyers
SET gender = CASE 
    WHEN gender = 'M' THEN 'Male'
    WHEN gender = 'F' THEN 'Female'
    ELSE gender 
END;

-- Video Step 3: Clean Commute Distance Text
-- Timestamp approx 22:28: He changes "10+ Miles" to "More than 10 Miles" for better sorting/readability.
UPDATE bike_buyers
SET commute_distance = 'More than 10 Miles'
WHERE commute_distance = '10+ Miles';


-- =======================================================================================
-- 4. DASHBOARD ANALYSIS QUERIES
-- Recreating the Pivot Tables and Visualizations from the video.
-- =======================================================================================

-- Visualization 1: Average Income by Gender and Purchase Status
-- Timestamp approx 14:28
-- Logic: Does income affect the decision to buy a bike?
SELECT 
    gender,
    purchased_bike,
    ROUND(AVG(income), 2) AS avg_income
FROM bike_buyers
GROUP BY gender, purchased_bike
ORDER BY gender, purchased_bike;


-- Visualization 2: Customer Commute Distance
-- Timestamp approx 19:09
-- Logic: Does commute distance impact bike purchasing? (Short commute = more likely to bike?)
SELECT 
    commute_distance,
    purchased_bike,
    COUNT(id) AS customer_count
FROM bike_buyers
GROUP BY commute_distance, purchased_bike
ORDER BY 
    -- Custom sorting to ensure mileage ranges appear in logical order
    CASE 
        WHEN commute_distance = '0-1 Miles' THEN 1
        WHEN commute_distance = '1-2 Miles' THEN 2
        WHEN commute_distance = '2-5 Miles' THEN 3
        WHEN commute_distance = '5-10 Miles' THEN 4
        ELSE 5 
    END,
    purchased_bike;


-- Visualization 3: Customer Age Brackets
-- Timestamp approx 24:33
-- Logic: The video creates age buckets (Adolescent, Middle Age, Old) to visualize trends.
-- Buckets used: < 31, >= 31 and < 54, >= 54

WITH Age_Brackets AS (
    SELECT 
        purchased_bike,
        age,
        CASE 
            WHEN age < 31 THEN 'Adolescent'
            WHEN age >= 31 AND age < 54 THEN 'Middle Age'
            WHEN age >= 54 THEN 'Old'
        END AS age_bracket
    FROM bike_buyers
)
SELECT 
    age_bracket,
    purchased_bike,
    COUNT(*) AS customer_count
FROM Age_Brackets
GROUP BY age_bracket, purchased_bike
ORDER BY customer_count DESC;