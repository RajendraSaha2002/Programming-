
-- 1. SCHEMA SETUP
-- Creating the table to match the standard Hotel Booking Demand dataset used in the video.

DROP TABLE IF EXISTS hotel_bookings;

CREATE TABLE hotel_bookings (
    hotel VARCHAR(50),                  -- City Hotel / Resort Hotel
    is_canceled INT,                    -- 0 = Not Canceled, 1 = Canceled
    lead_time INT,
    arrival_date_year INT,
    arrival_date_month VARCHAR(20),
    arrival_date_week_number INT,
    arrival_date_day_of_month INT,
    stays_in_weekend_nights INT,
    stays_in_week_nights INT,
    adults INT,
    children INT,
    babies INT,
    meal VARCHAR(20),
    country VARCHAR(10),
    market_segment VARCHAR(20),
    distribution_channel VARCHAR(20),
    is_repeated_guest INT,
    previous_cancellations INT,
    previous_bookings_not_canceled INT,
    reserved_room_type VARCHAR(5),      -- A, B, C, etc.
    assigned_room_type VARCHAR(5),      -- A, B, C, etc.
    booking_changes INT,
    deposit_type VARCHAR(20),
    agent VARCHAR(10),
    company VARCHAR(10),
    days_in_waiting_list INT,
    customer_type VARCHAR(20),
    adr DECIMAL(10, 2),                 -- Average Daily Rate
    required_car_parking_spaces INT,
    total_of_special_requests INT,
    reservation_status VARCHAR(20),
    reservation_status_date DATE
);

-- =======================================================================================
-- 2. DATA INSERTION (DUMMY DATA)
-- Inserting sample data to replicate the scenarios discussed (Couples, Families, Room Mismatches).
-- =======================================================================================

INSERT INTO hotel_bookings (hotel, is_canceled, arrival_date_year, arrival_date_month, adults, children, babies, reserved_room_type, assigned_room_type, country) VALUES
-- Scenario 1: Couples (2 Adults, 0 Kids) - Some canceled, some not
('Resort Hotel', 0, 2015, 'July', 2, 0, 0, 'C', 'C', 'PRT'),
('Resort Hotel', 0, 2015, 'July', 2, 0, 0, 'C', 'C', 'PRT'),
('City Hotel', 1, 2016, 'August', 2, 0, 0, 'A', 'A', 'USA'), -- Canceled Couple
('City Hotel', 0, 2016, 'August', 2, 0, 0, 'A', 'A', 'FRA'),

-- Scenario 2: Singles (1 Adult, 0 Kids)
('Resort Hotel', 0, 2015, 'September', 1, 0, 0, 'A', 'C', 'GBR'), -- Room upgrade (Undesired/Changed)
('City Hotel', 1, 2017, 'January', 1, 0, 0, 'A', 'A', 'PRT'),

-- Scenario 3: Families (Adults + Children/Babies)
('Resort Hotel', 0, 2016, 'July', 2, 2, 0, 'G', 'G', 'ESP'),
('City Hotel', 1, 2016, 'December', 3, 0, 0, 'A', 'A', 'PRT'), -- 3 Adults considered Family in logic
('City Hotel', 1, 2017, 'February', 2, 1, 0, 'A', 'A', 'BRA'),

-- Scenario 4: Room Mismatch (Reserved != Assigned)
('Resort Hotel', 0, 2015, 'July', 2, 0, 0, 'A', 'C', 'PRT'), -- Got better room? Not Canceled
('City Hotel', 1, 2016, 'October', 2, 0, 0, 'D', 'A', 'DEU'); -- Got worse/different room? Canceled


-- =======================================================================================
-- 3. FEATURE ENGINEERING (Excel Formulas to SQL)
-- The video creates custom columns 'Room Status' and 'Guest Type'.
-- =======================================================================================

-- 3.1 Create new columns
ALTER TABLE hotel_bookings ADD COLUMN room_status_type VARCHAR(20);
ALTER TABLE hotel_bookings ADD COLUMN guest_type VARCHAR(20);

-- 3.2 Update 'Room Status' (Desired vs Undesired)
-- Excel Logic: IF(Reserved = Assigned, "Desired", "Undesired")
UPDATE hotel_bookings
SET room_status_type = CASE 
    WHEN reserved_room_type = assigned_room_type THEN 'Desired'
    ELSE 'Undesired'
END;

-- 3.3 Update 'Guest Type' (Couple vs Single vs Family)
-- Excel Logic: IF(Adults=2 & Kids=0, "Couple", IF(Adults=1 & Kids=0, "Single", "Family"))
UPDATE hotel_bookings
SET guest_type = CASE 
    WHEN adults = 2 AND children = 0 AND babies = 0 THEN 'Couple'
    WHEN adults = 1 AND children = 0 AND babies = 0 THEN 'Single'
    ELSE 'Family'
END;


-- =======================================================================================
-- 4. DASHBOARD ANALYSIS QUERIES
-- Recreating the Pivot Tables used for the dashboard charts.
-- =======================================================================================

-- Insight 1: Total Bookings & Cancellations Overview
-- Used for the "Scorecard" numbers at the top.
SELECT 
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS total_cancellations,
    ROUND((SUM(is_canceled) * 100.0 / COUNT(*)), 2) AS cancellation_rate
FROM hotel_bookings;

-- Insight 2: Cancellations by Guest Type
-- Video Finding: Which group cancels the most? (Couples/Families/Singles)
SELECT 
    guest_type,
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS cancelled_bookings,
    ROUND((SUM(is_canceled) * 100.0 / COUNT(*)), 2) AS cancellation_percentage
FROM hotel_bookings
GROUP BY guest_type
ORDER BY cancellation_percentage DESC;

-- Insight 3: Impact of Room Mismatch (Desired vs Undesired)
-- Video Finding: Does not getting the requested room lead to cancellation?
-- (Video conclusion: Surprisingly, Undesired rooms had low cancellation rates in their data).
SELECT 
    room_status_type,
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS cancelled_bookings,
    ROUND((SUM(is_canceled) * 100.0 / COUNT(*)), 2) AS cancellation_percentage
FROM hotel_bookings
GROUP BY room_status_type;

-- Insight 4: Trend by Arrival Month/Year
-- Used for the Slicer and Timeline charts.
SELECT 
    arrival_date_year,
    arrival_date_month,
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS cancellations
FROM hotel_bookings
GROUP BY arrival_date_year, arrival_date_month
ORDER BY arrival_date_year, 
    -- Custom sorting for months
    CASE 
        WHEN arrival_date_month = 'January' THEN 1
        WHEN arrival_date_month = 'February' THEN 2
        WHEN arrival_date_month = 'March' THEN 3
        WHEN arrival_date_month = 'April' THEN 4
        WHEN arrival_date_month = 'May' THEN 5
        WHEN arrival_date_month = 'June' THEN 6
        WHEN arrival_date_month = 'July' THEN 7
        WHEN arrival_date_month = 'August' THEN 8
        WHEN arrival_date_month = 'September' THEN 9
        WHEN arrival_date_month = 'October' THEN 10
        WHEN arrival_date_month = 'November' THEN 11
        WHEN arrival_date_month = 'December' THEN 12
    END;

-- Insight 5: Hotel Type Analysis (City vs Resort)
-- Pie Chart Data
SELECT 
    hotel,
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS cancellations,
    ROUND((SUM(is_canceled) * 100.0 / COUNT(*)), 2) AS cancellation_rate
FROM hotel_bookings
GROUP BY hotel;