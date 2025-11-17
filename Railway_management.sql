/*******************************************************************************
** Railway System Database Script for PostgreSQL (MAXIMIZED SCHEMA)
**
** This script defines an extremely detailed and large schema for managing a
** railway system. It maximizes the number of tables and columns to reflect
** a complex, real-world enterprise system, including personnel, asset tracking,
** dynamic pricing, and system auditing.
*******************************************************************************/

-- =============================================================================
-- 0. CLEANUP (DROP FUNCTIONS AND TABLES)
--    Uses CASCADE to handle foreign key dependencies and ensures the script is
--    idempotent (can be run multiple times).
-- =============================================================================

-- Drop triggers first
DROP TRIGGER IF EXISTS trg_update_seats ON tickets;
DROP TRIGGER IF EXISTS trg_notify_delay ON schedules;

-- Drop functions
DROP FUNCTION IF EXISTS update_seat_availability();
DROP FUNCTION IF EXISTS generate_delay_notification();

-- Drop tables (using CASCADE for safety)
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS fare_modifiers CASCADE;
DROP TABLE IF EXISTS maintenance_logs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS segment_fares CASCADE;
DROP TABLE IF EXISTS fare_segments CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS seat_availability CASCADE;
DROP TABLE IF EXISTS seat_inventory CASCADE;
DROP TABLE IF EXISTS coaches CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS schedules CASCADE;
DROP TABLE IF EXISTS route_stops CASCADE;
DROP TABLE IF EXISTS routes CASCADE;
DROP TABLE IF EXISTS trains CASCADE;
DROP TABLE IF EXISTS stations CASCADE;
DROP TABLE IF EXISTS users CASCADE;


-- =============================================================================
-- 1. SCHEMA DEFINITION (DDL - Maximum Detail)
-- =============================================================================

-- Table 1: users (20 Columns - Enhanced Security and Contact)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    password_hash TEXT NOT NULL,
    security_question VARCHAR(255),
    security_answer_hash TEXT,
    user_role VARCHAR(50) NOT NULL DEFAULT 'Customer', -- 'Customer', 'Staff', 'Admin', 'Maintenance'
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    date_of_birth DATE,
    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'India',
    preferred_language VARCHAR(10) DEFAULT 'en',
    marketing_opt_in BOOLEAN DEFAULT FALSE
);

-- Table 2: staff (Personnel Management)
CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL, -- Link to users for login/contact
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(100) NOT NULL, -- 'Driver', 'Conductor', 'Mechanic', 'Ticketing Agent'
    department VARCHAR(100) NOT NULL, -- 'Operations', 'Maintenance', 'Administration'
    hire_date DATE NOT NULL,
    salary NUMERIC(12, 2) NOT NULL,
    is_certified BOOLEAN DEFAULT FALSE,
    shift_schedule VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Table 3: stations (15 Columns - Infrastructure Detail)
CREATE TABLE stations (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(100) UNIQUE NOT NULL,
    station_code VARCHAR(10) UNIQUE NOT NULL,
    city VARCHAR(100),
    state_province VARCHAR(100),
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),
    is_major_junction BOOLEAN DEFAULT FALSE,
    number_of_platforms INT DEFAULT 1,
    has_wifi BOOLEAN DEFAULT FALSE,
    has_waiting_room BOOLEAN DEFAULT TRUE,
    has_cargo_facility BOOLEAN DEFAULT FALSE,
    elevation_meters INT,
    zone VARCHAR(50), -- e.g., 'North', 'South-West'
    manager_staff_id INT -- Reference to Staff
);

-- Table 4: trains (10 Columns - Train Specifications)
CREATE TABLE trains (
    train_id SERIAL PRIMARY KEY,
    train_name VARCHAR(100) UNIQUE NOT NULL,
    train_number VARCHAR(15) UNIQUE NOT NULL,
    train_type VARCHAR(50) NOT NULL, -- 'Electric', 'Diesel', 'High-Speed'
    max_speed_kmh INT,
    total_length_meters NUMERIC(6, 2),
    weight_tonnes NUMERIC(8, 2),
    year_of_manufacture INT,
    last_major_service_date DATE,
    status VARCHAR(50) DEFAULT 'Active' -- 'Active', 'In Maintenance', 'Retired'
);

-- Table 5: coaches (12 Columns - Detailed Rolling Stock Inventory)
CREATE TABLE coaches (
    coach_id SERIAL PRIMARY KEY,
    train_id INT, -- NULL if not currently assigned to a train set
    coach_serial_number VARCHAR(20) UNIQUE NOT NULL,
    coach_type VARCHAR(50) NOT NULL, -- 'Sleeper', 'AC 3 Tier', 'Pantry Car', 'Luggage Van'
    manufacturer VARCHAR(100),
    year_of_service INT,
    max_capacity INT, -- Kept this as overall physical coach capacity
    is_handicap_accessible BOOLEAN DEFAULT FALSE,
    has_power_outlets BOOLEAN DEFAULT TRUE,
    last_wash_date DATE,
    condition_rating INT, -- 1 (Poor) to 5 (Excellent)
    FOREIGN KEY (train_id) REFERENCES trains(train_id)
);

-- Table 6: classes (6 Columns)
CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(50) UNIQUE NOT NULL,
    class_code VARCHAR(10) UNIQUE NOT NULL, -- e.g., 'SL', '3A', 'CC'
    description TEXT,
    is_ac BOOLEAN NOT NULL,
    luggage_policy TEXT
);

-- Table 7: seat_inventory (7 Columns - Total physical seats by coach type)
CREATE TABLE seat_inventory (
    inventory_id SERIAL PRIMARY KEY,
    coach_id INT NOT NULL,
    class_id INT NOT NULL,
    seat_layout VARCHAR(50), -- e.g., '2x3', '1x2'
    total_seats INT NOT NULL,
    FOREIGN KEY (coach_id) REFERENCES coaches(coach_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    UNIQUE (coach_id, class_id)
);

-- Table 8: routes (5 Columns)
CREATE TABLE routes (
    route_id SERIAL PRIMARY KEY,
    train_id INT NOT NULL,
    route_description TEXT,
    operating_days_mask VARCHAR(7), -- e.g., '1101100' for Mon, Tue, Thu, Fri
    total_distance_km NUMERIC(10, 2),
    FOREIGN KEY (train_id) REFERENCES trains(train_id)
);

-- Table 9: route_stops (10 Columns - Detailed stop timing)
CREATE TABLE route_stops (
    route_stop_id SERIAL PRIMARY KEY,
    route_id INT NOT NULL,
    station_id INT NOT NULL,
    stop_sequence INT NOT NULL,
    scheduled_arrival_time TIME WITHOUT TIME ZONE,
    scheduled_departure_time TIME WITHOUT TIME ZONE,
    halt_duration_minutes INT DEFAULT 5,
    distance_from_origin_km NUMERIC(10, 2),
    platform_number VARCHAR(10),
    track_number VARCHAR(10),
    FOREIGN KEY (route_id) REFERENCES routes(route_id),
    FOREIGN KEY (station_id) REFERENCES stations(station_id),
    UNIQUE (route_id, stop_sequence)
);

-- Table 10: schedules (10 Columns - Specific run details)
CREATE TABLE schedules (
    schedule_id SERIAL PRIMARY KEY,
    route_id INT NOT NULL,
    departure_date DATE NOT NULL,
    scheduled_departure_ts TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_departure_ts TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) NOT NULL DEFAULT 'On Time',
    train_status_message TEXT,
    driver_staff_id INT, -- Staff assigned as driver
    conductor_staff_id INT, -- Staff assigned as conductor
    FOREIGN KEY (route_id) REFERENCES routes(route_id),
    FOREIGN KEY (driver_staff_id) REFERENCES staff(staff_id),
    FOREIGN KEY (conductor_staff_id) REFERENCES staff(staff_id),
    UNIQUE (route_id, departure_date)
);

-- Table 11: seat_availability (4 Columns - Real-time availability)
CREATE TABLE seat_availability (
    schedule_id INT NOT NULL,
    class_id INT NOT NULL,
    available_seats INT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (schedule_id, class_id),
    FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id)
);

-- Table 12: fare_segments (5 Columns - Defines adjacent stops for pricing)
CREATE TABLE fare_segments (
    segment_id SERIAL PRIMARY KEY,
    route_id INT NOT NULL,
    start_station_id INT NOT NULL,
    end_station_id INT NOT NULL,
    distance_km NUMERIC(10, 2),
    FOREIGN KEY (route_id) REFERENCES routes(route_id)
);

-- Table 13: segment_fares (5 Columns - Base fare for a segment and class)
CREATE TABLE segment_fares (
    segment_fare_id SERIAL PRIMARY KEY,
    segment_id INT NOT NULL,
    class_id INT NOT NULL,
    base_price NUMERIC(10, 2) NOT NULL,
    tax_rate NUMERIC(4, 3) DEFAULT 0.05, -- 5% tax
    FOREIGN KEY (segment_id) REFERENCES fare_segments(segment_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    UNIQUE (segment_id, class_id)
);

-- Table 14: fare_modifiers (Dynamic Pricing Rules)
CREATE TABLE fare_modifiers (
    modifier_id SERIAL PRIMARY KEY,
    modifier_name VARCHAR(100) UNIQUE NOT NULL, -- 'Tatkal', 'Senior Citizen', 'Holiday Surcharge'
    modifier_type VARCHAR(20) NOT NULL, -- 'Discount' or 'Surcharge'
    percentage_change NUMERIC(4, 3) NOT NULL, -- e.g., 0.10 for 10%
    is_active BOOLEAN DEFAULT TRUE,
    valid_from DATE,
    valid_until DATE
);

-- Table 15: bookings (10 Columns - Reservation Header)
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    schedule_id INT NOT NULL,
    origin_stop_id INT NOT NULL,
    destination_stop_id INT NOT NULL,
    booking_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_fare NUMERIC(10, 2) NOT NULL,
    booking_status VARCHAR(50) DEFAULT 'Confirmed', -- 'Confirmed', 'Canceled', 'Waiting List'
    payment_method VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id),
    FOREIGN KEY (origin_stop_id) REFERENCES stations(station_id),
    FOREIGN KEY (destination_stop_id) REFERENCES stations(station_id)
);

-- Table 16: tickets (12 Columns - Individual Passenger Tickets)
CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    class_id INT NOT NULL,
    passenger_name VARCHAR(100) NOT NULL,
    passenger_age INT NOT NULL,
    seat_number VARCHAR(10),
    pnr_number VARCHAR(15) UNIQUE NOT NULL,
    date_of_travel DATE NOT NULL,
    ticket_fare NUMERIC(10, 2) NOT NULL, -- Fare for this specific ticket
    applied_modifier_id INT, -- e.g., for Senior Citizen Discount
    is_checked_in BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (applied_modifier_id) REFERENCES fare_modifiers(modifier_id)
);

-- Table 17: maintenance_logs (10 Columns - Tracking train reliability)
CREATE TABLE maintenance_logs (
    log_id SERIAL PRIMARY KEY,
    train_id INT, -- NULL if general equipment maintenance
    coach_id INT,
    log_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    maintenance_type VARCHAR(100) NOT NULL, -- 'Scheduled', 'Unscheduled', 'Repair', 'Inspection'
    description TEXT NOT NULL,
    cost NUMERIC(10, 2),
    performed_by_staff_id INT,
    next_due_date DATE,
    FOREIGN KEY (train_id) REFERENCES trains(train_id),
    FOREIGN KEY (coach_id) REFERENCES coaches(coach_id),
    FOREIGN KEY (performed_by_staff_id) REFERENCES staff(staff_id)
);

-- Table 18: notifications (7 Columns - For communicating delays/updates)
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    schedule_id INT,
    message TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    notification_type VARCHAR(50) DEFAULT 'SYSTEM', -- 'ALERT', 'UPDATE', 'PROMO'
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Table 19: audit_log (10 Columns - System activity log)
CREATE TABLE audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    user_id INT,
    action_type VARCHAR(50) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE', 'LOGIN'
    table_name VARCHAR(100) NOT NULL,
    record_id INT,
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    old_data JSONB, -- Storing old record data
    new_data JSONB, -- Storing new record data
    ip_address INET,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


-- =============================================================================
-- 2. TRIGGER FUNCTIONS (PL/pgSQL)
--    The functions remain largely the same, operating on the core tables.
-- =============================================================================

-- TRIGGER FUNCTION 1: Update Seat Availability
CREATE OR REPLACE FUNCTION update_seat_availability()
RETURNS trigger AS $$
BEGIN
    DECLARE
        v_schedule_id INT;
    BEGIN
        SELECT schedule_id INTO v_schedule_id
        FROM bookings
        WHERE booking_id = NEW.booking_id;

        UPDATE seat_availability
        SET available_seats = available_seats - 1, last_update = NOW()
        WHERE schedule_id = v_schedule_id
          AND class_id = NEW.class_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Booking failed: Seat inventory for schedule %s and class %s was not found.', v_schedule_id, NEW.class_id;
        END IF;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER FUNCTION 2: Generate Delay Notification
CREATE OR REPLACE FUNCTION generate_delay_notification()
RETURNS trigger AS $$
BEGIN
    IF (NEW.status IS DISTINCT FROM OLD.status) OR (NEW.actual_departure_ts IS DISTINCT FROM OLD.actual_departure_ts) THEN
        DECLARE
            v_train_name VARCHAR;
            v_message TEXT;
            v_user_id INT;
        BEGIN
            SELECT t.train_name INTO v_train_name
            FROM schedules s
            JOIN routes r ON s.route_id = r.route_id
            JOIN trains t ON r.train_id = t.train_id
            WHERE s.schedule_id = NEW.schedule_id;

            v_message := 'ALERT: Train ' || v_train_name || ' status is now ' || UPPER(NEW.status) || '. ';

            IF NEW.actual_departure_ts IS NOT NULL THEN
                v_message := v_message || 'Estimated New Departure: ' || TO_CHAR(NEW.actual_departure_ts AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI TZH');
            END IF;

            IF NEW.train_status_message IS NOT NULL THEN
                v_message := v_message || '. Reason: ' || NEW.train_status_message;
            END IF;

            FOR v_user_id IN
                SELECT DISTINCT user_id FROM bookings WHERE schedule_id = NEW.schedule_id
            LOOP
                INSERT INTO notifications (user_id, schedule_id, message, notification_type)
                VALUES (v_user_id, NEW.schedule_id, v_message, 'ALERT');
            END LOOP;
        END;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- 3. TRIGGER ATTACHMENTS
-- =============================================================================

-- Trigger for Real-Time Seat Availability
CREATE TRIGGER trg_update_seats
AFTER INSERT ON tickets
FOR EACH ROW
EXECUTE FUNCTION update_seat_availability();

-- Trigger for Train Status/Delay Notifications
CREATE TRIGGER trg_notify_delay
AFTER UPDATE ON schedules
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status OR OLD.actual_departure_ts IS DISTINCT FROM NEW.actual_departure_ts)
EXECUTE FUNCTION generate_delay_notification();


-- =============================================================================
-- 4. SAMPLE DATA INSERTION (DML - Increased Volume)
-- =============================================================================

-- USERS (10 Rows)
INSERT INTO users (username, email, phone_number, password_hash, user_role, date_of_birth, city, last_login) VALUES
('alice_cust', 'alice@e.com', '9876543210', 'hpw1', 'Customer', '1990-05-15', 'New Delhi', NOW()),
('rail_staff_op', 'op@rail.com', '9998887770', 'hpw2', 'Staff', '1975-01-20', 'Mumbai', NOW()),
('bob_cust', 'bob@e.com', '9871234560', 'hpw3', 'Customer', '2000-11-01', 'Jaipur', NOW()),
('driver_dave', 'dave@rail.com', '9871234561', 'hpw4', 'Staff', '1980-03-03', 'New Delhi', NOW()),
('conductor_carol', 'carol@rail.com', '9871234562', 'hpw5', 'Staff', '1985-04-04', 'Mumbai', NOW()),
('admin_alex', 'alex@rail.com', '9871234563', 'hpw6', 'Admin', '1970-05-05', 'New Delhi', NOW()),
('cust_eve', 'eve@e.com', '9871234564', 'hpw7', 'Customer', '1995-06-06', 'Mumbai', NOW()),
('cust_frank', 'frank@e.com', '9871234565', 'hpw8', 'Customer', '1992-07-07', 'Jaipur', NOW()),
('cust_grace', 'grace@e.com', '9871234566', 'hpw9', 'Customer', '1988-08-08', 'New Delhi', NOW()),
('maint_mike', 'mike@rail.com', '9871234567', 'hpw10', 'Maintenance', '1965-09-09', 'Mumbai', NOW());

-- STAFF (7 Rows)
INSERT INTO staff (user_id, employee_id, first_name, last_name, job_title, department, hire_date, salary, is_certified) VALUES
(2, 'E001', 'Rail', 'Staff', 'Station Master', 'Operations', '2010-01-01', 90000.00, TRUE), -- ID 1 (Rail Staff)
(4, 'E002', 'Dave', 'Driver', 'Locomotive Driver', 'Operations', '2005-03-15', 120000.00, TRUE), -- ID 2 (Driver Dave)
(5, 'E003', 'Carol', 'Conductor', 'Senior Conductor', 'Operations', '2012-07-22', 85000.00, TRUE), -- ID 3 (Conductor Carol)
(6, 'E004', 'Alex', 'Admin', 'Chief Administrator', 'Administration', '2000-01-01', 150000.00, TRUE), -- ID 4 (Admin Alex)
(10, 'E005', 'Mike', 'Maint', 'Mechanical Engineer', 'Maintenance', '2018-05-10', 95000.00, TRUE), -- ID 5 (Maint Mike)
(1, 'E006', 'Alice', 'Johnson', 'Ticketing Agent', 'Administration', '2023-11-01', 60000.00, FALSE), -- ID 6 (Alice - Used as agent)
(3, 'E007', 'Bob', 'Lee', 'Junior Conductor', 'Operations', '2024-01-01', 70000.00, FALSE); -- ID 7 (Bob - Used as junior conductor)

-- STATIONS (5 Rows)
INSERT INTO stations (station_name, station_code, city, latitude, longitude, is_major_junction, number_of_platforms, manager_staff_id) VALUES
('New Delhi', 'NDLS', 'New Delhi', 28.6435, 77.2223, TRUE, 16, 1),  -- ID 1
('Mumbai Central', 'BCT', 'Mumbai', 18.9667, 72.8227, TRUE, 9, 1), -- ID 2
('Jaipur Junction', 'JP', 'Jaipur', 26.9124, 75.7873, TRUE, 7, 1), -- ID 3
('Surat', 'ST', 'Surat', 21.1702, 72.8311, FALSE, 4, 1), -- ID 4
('Ahmedabad', 'ADI', 'Ahmedabad', 23.0225, 72.5714, TRUE, 12, 1); -- ID 5

-- TRAINS (3 Rows)
INSERT INTO trains (train_name, train_number, train_type, max_speed_kmh, total_length_meters, year_of_manufacture) VALUES
('Rajdhani Express', '12952', 'Electric', 130, 450.00, 2010), -- ID 1
('Shatabdi Intercity', '12030', 'Electric', 110, 300.00, 2015), -- ID 2
('Gujarat Mail', '12901', 'Diesel', 100, 400.00, 2005); -- ID 3

-- CLASSES (4 Rows)
INSERT INTO classes (class_name, class_code, description, is_ac) VALUES
('Sleeper', 'SL', 'Non-AC coach for long distance travel.', FALSE), -- ID 1
('AC 3-Tier', '3A', 'Air-conditioned coach with three tiers.', TRUE), -- ID 2
('AC Chair Car', 'CC', 'Air-conditioned seating coach, usually for day journeys.', TRUE), -- ID 3
('First AC', '1A', 'Premium air-conditioned private cabin.', TRUE); -- ID 4

-- COACHES (12 Rows - Detailed Inventory)
-- FIX APPLIED HERE: Removed 'class_id' column and its corresponding value (the last integer)
INSERT INTO coaches (train_id, coach_serial_number, coach_type, manufacturer, max_capacity) VALUES
(1, 'RJDH-S1-001', 'Sleeper', 'ICF', 72), -- ID 1
(1, 'RJDH-S2-002', 'Sleeper', 'ICF', 72), -- ID 2
(1, 'RJDH-B1-003', 'AC 3 Tier', 'LHB', 64), -- ID 3
(1, 'RJDH-B2-004', 'AC 3 Tier', 'LHB', 64), -- ID 4
(1, 'RJDH-H1-005', 'First AC', 'LHB', 24), -- ID 5
(2, 'SHTB-C1-006', 'AC Chair Car', 'LHB', 78), -- ID 6
(2, 'SHTB-C2-007', 'AC Chair Car', 'LHB', 78), -- ID 7
(2, 'SHTB-E1-008', 'Executive Class', 'LHB', 56), -- ID 8
(3, 'GJML-S1-009', 'Sleeper', 'ICF', 72), -- ID 9
(3, 'GJML-S2-010', 'Sleeper', 'ICF', 72), -- ID 10
(3, 'GJML-B1-011', 'AC 3 Tier', 'LHB', 64), -- ID 11
(3, 'GJML-A1-012', 'First AC', 'LHB', 24); -- ID 12

-- SEAT INVENTORY (4 Rows - Total seats per coach, linked to class)
INSERT INTO seat_inventory (coach_id, class_id, seat_layout, total_seats) VALUES
(1, 1, '3x3', 72),  -- RJDH-S1-001 (SL)
(3, 2, '2x2', 64),  -- RJDH-B1-003 (3A)
(5, 4, '1x1', 24),  -- RJDH-H1-005 (1A)
(6, 3, '2x3', 78);  -- SHTB-C1-006 (CC)

-- ROUTES (2 Routes)
INSERT INTO routes (train_id, route_description, operating_days_mask, total_distance_km) VALUES
(1, 'Delhi to Mumbai Express Route via Jaipur', '1111111', 1386.00), -- Route ID 1 (Daily)
(2, 'Delhi to Ahmedabad Intercity Express', '1101100', 934.00); -- Route ID 2 (M, T, Th, F)

-- ROUTE STOPS (Route 1: NDLS(1) -> JP(3) -> ST(4) -> BCT(2). 4 Stops)
INSERT INTO route_stops (route_id, station_id, stop_sequence, scheduled_arrival_time, scheduled_departure_time, distance_from_origin_km) VALUES
(1, 1, 1, NULL, '18:00:00', 0.0),      -- NDLS (Origin)
(1, 3, 2, '22:30:00', '22:45:00', 303.0), -- Jaipur
(1, 4, 3, '06:00:00', '06:05:00', 1250.0), -- Surat
(1, 2, 4, '09:00:00', NULL, 1386.0);   -- BCT (Destination)

-- ROUTE STOPS (Route 2: NDLS(1) -> JP(3) -> ADI(5). 3 Stops)
INSERT INTO route_stops (route_id, station_id, stop_sequence, scheduled_arrival_time, scheduled_departure_time, distance_from_origin_km) VALUES
(2, 1, 1, NULL, '06:00:00', 0.0),      -- NDLS (Origin)
(2, 3, 2, '10:30:00', '10:40:00', 303.0), -- Jaipur
(2, 5, 3, '14:00:00', NULL, 934.0);   -- Ahmedabad

-- FARE SEGMENTS (Route 1: 3 segments * 3 classes = 9 segment fares)
INSERT INTO fare_segments (route_id, start_station_id, end_station_id, distance_km) VALUES
(1, 1, 3, 303.0), -- Segment 1: NDLS to JP
(1, 3, 4, 947.0), -- Segment 2: JP to ST
(1, 4, 2, 136.0), -- Segment 3: ST to BCT
(1, 1, 2, 1386.0); -- Segment 4: NDLS to BCT (Full Route)

-- SEGMENT FARES (Sample for Full Route (Segment 4))
INSERT INTO segment_fares (segment_id, class_id, base_price) VALUES
(4, 1, 2000.00), -- Full Route, Sleeper
(4, 2, 3600.00), -- Full Route, 3A
(4, 4, 6000.00); -- Full Route, 1A

-- FARE MODIFIERS (3 Rows)
INSERT INTO fare_modifiers (modifier_name, modifier_type, percentage_change, valid_from) VALUES
('Tatkal', 'Surcharge', 0.30, '2024-01-01'), -- ID 1: 30% Surcharge
('Senior Citizen', 'Discount', -0.40, '2024-01-01'), -- ID 2: 40% Discount
('Weekend Surcharge', 'Surcharge', 0.15, '2024-01-01'); -- ID 3: 15% Surcharge

-- SCHEDULES (6 Rows - 2 Train runs for different days)
INSERT INTO schedules (route_id, departure_date, scheduled_departure_ts, driver_staff_id, conductor_staff_id) VALUES
(1, '2025-10-10', '2025-10-10 18:00:00+05:30', 2, 3), -- ID 1 (Rajdhani, Today)
(1, '2025-10-11', '2025-10-11 18:00:00+05:30', 2, 3), -- ID 2 (Rajdhani, Tomorrow)
(2, '2025-10-10', '2025-10-10 06:00:00+05:30', 2, 7), -- ID 3 (Shatabdi, Today)
(2, '2025-10-13', '2025-10-13 06:00:00+05:30', 2, 7); -- ID 4 (Shatabdi, Monday)

-- SEAT AVAILABILITY (Initial load for Schedule 1 and 3)
INSERT INTO seat_availability (schedule_id, class_id, available_seats) VALUES
(1, 1, 500), (1, 2, 100), (1, 4, 24), -- Schedule 1 (Rajdhani)
(3, 3, 156), (3, 4, 56); -- Schedule 3 (Shatabdi - CC & 1A equivalent)

-- BOOKINGS (5 Rows - Transaction Header)
INSERT INTO bookings (user_id, schedule_id, origin_stop_id, destination_stop_id, total_fare, payment_method) VALUES
(1, 1, 1, 2, 7200.00, 'Credit Card'), -- ID 1: Alice, NDLS-BCT, 2 Tickets * 3600.00 (3A)
(3, 1, 3, 2, 1500.00, 'UPI'), -- ID 2: Bob, JP-BCT, 1 Ticket (SL)
(7, 3, 1, 5, 2500.00, 'Debit Card'), -- ID 3: Eve, NDLS-ADI, 1 Ticket (CC)
(8, 1, 1, 3, 4000.00, 'Credit Card'), -- ID 4: Frank, NDLS-JP, 2 Tickets (SL)
(9, 1, 1, 2, 3000.00, 'Wallet'); -- ID 5: Grace, NDLS-BCT, 1 Ticket (SL)

-- TICKETS (7 Rows - Maximum transaction detail)
INSERT INTO tickets (booking_id, class_id, passenger_name, passenger_age, seat_number, pnr_number, date_of_travel, ticket_fare, applied_modifier_id) VALUES
(1, 2, 'Alice Johnson', 30, 'B1-12', 'PNR00000001', '2025-10-10', 3600.00, NULL),
(1, 2, 'David Johnson', 32, 'B1-13', 'PNR00000002', '2025-10-10', 3600.00, NULL),
(2, 1, 'Bob Lee', 45, 'S5-22', 'PNR00000003', '2025-10-10', 1500.00, NULL),
(3, 3, 'Eve Smith', 28, 'C3-05', 'PNR00000004', '2025-10-10', 2500.00, NULL),
(4, 1, 'Frank Q', 55, 'S2-01', 'PNR00000005', '2025-10-10', 1000.00, NULL),
(4, 1, 'Jenna Q', 68, 'S2-02', 'PNR00000006', '2025-10-10', 1000.00 * (1 - 0.40), 2), -- Senior Citizen Discount
(5, 1, 'Grace M', 25, 'S1-10', 'PNR00000007', '2025-10-10', 2000.00, NULL);

-- MAINTENANCE LOGS (4 Rows)
INSERT INTO maintenance_logs (train_id, coach_id, maintenance_type, description, cost, performed_by_staff_id, next_due_date) VALUES
(1, 3, 'Scheduled', 'AC gas recharge in B1 coach.', 5000.00, 5, '2026-03-01'),
(1, NULL, 'Repair', 'Replaced faulty headlight on locomotive.', 15000.00, 5, NULL),
(2, 6, 'Inspection', 'Pre-trip safety check completed.', 100.00, 5, '2025-10-11'),
(NULL, 1, 'Repair', 'General body damage repair.', 800.00, 5, NULL);

-- AUDIT LOG (3 Rows - Sample Login Activity)
INSERT INTO audit_log (user_id, action_type, table_name, record_id, ip_address) VALUES
(6, 'LOGIN', 'users', 6, '192.168.1.10'),
(1, 'INSERT', 'bookings', 5, '203.0.113.50'),
(2, 'UPDATE', 'schedules', 1, '10.0.0.2');


-- =============================================================================
-- 5. ANALYTICAL QUERIES (DQL)
-- =============================================================================

-- QUERY 1: Real-Time Seat Availability (Shows 100% capacity utilization tracking)
-- Functionality: Provides up-to-date seat count for a specific schedule (ID 1).
-------------------------------------------------------------------------------
SELECT
    t.train_name,
    c.class_name,
    sa.available_seats,
    sa.last_update
FROM
    seat_availability sa
JOIN
    schedules s ON sa.schedule_id = s.schedule_id
JOIN
    routes r ON s.route_id = r.route_id
JOIN
    trains t ON r.train_id = t.train_id
JOIN
    classes c ON sa.class_id = c.class_id
WHERE
    s.schedule_id = 1;

-- QUERY 2: Full Detailed Schedule and Route Stops
-- Functionality: Train and Schedule Management (Arrival/Departure/Stops).
-------------------------------------------------------------------------------
SELECT
    t.train_name,
    s.departure_date,
    st.station_name,
    rs.stop_sequence,
    rs.scheduled_arrival_time,
    rs.scheduled_departure_time,
    rs.halt_duration_minutes,
    rs.platform_number
FROM
    schedules s
JOIN
    routes r ON s.route_id = r.route_id
JOIN
    trains t ON r.train_id = t.train_id
JOIN
    route_stops rs ON r.route_id = rs.route_id
JOIN
    stations st ON rs.station_id = st.station_id
WHERE
    s.schedule_id = 1
ORDER BY
    rs.stop_sequence;

-- QUERY 3: Check Train Status and Trigger Notification
-- Action: Simulate a delay update (Run this UPDATE to test the NOTIFICATION TRIGGER)
-------------------------------------------------------------------------------
-- UPDATE schedules
-- SET status = 'Delayed', actual_departure_ts = '2025-10-10 19:15:00+05:30', train_status_message = 'Due to upstream signal failure at Station X'
-- WHERE schedule_id = 1 AND status = 'On Time';
-- SELECT * FROM notifications WHERE schedule_id = 1; -- Check the notifications table after running the UPDATE

-- QUERY 4: Revenue Summary by Applied Fare Modifier (Discount/Surcharge Analysis)
-- Purpose: Analyze the financial impact of dynamic pricing rules.
-------------------------------------------------------------------------------
SELECT
    COALESCE(fm.modifier_name, 'Standard Fare') AS fare_modifier,
    fm.modifier_type,
    COUNT(t.ticket_id) AS total_tickets_sold,
    SUM(t.ticket_fare) AS total_revenue_by_modifier
FROM
    tickets t
LEFT JOIN
    fare_modifiers fm ON t.applied_modifier_id = fm.modifier_id
GROUP BY
    fm.modifier_name, fm.modifier_type
ORDER BY
    total_revenue_by_modifier DESC;

-- QUERY 5: Maintenance Cost and Reliability Summary by Coach Type
-- Purpose: Track asset reliability and operational expenditure (OpEx) at the coach level.
-------------------------------------------------------------------------------
SELECT
    c.coach_type,
    cl.class_name,
    COUNT(ml.log_id) AS total_maintenance_events,
    SUM(ml.cost) AS total_maintenance_cost,
    AVG(ml.cost) AS average_cost_per_event
FROM
    coaches c
JOIN
    seat_inventory si ON c.coach_id = si.coach_id
JOIN
    classes cl ON si.class_id = cl.class_id
LEFT JOIN
    maintenance_logs ml ON c.coach_id = ml.coach_id
GROUP BY
    c.coach_type, cl.class_name
ORDER BY
    total_maintenance_cost DESC;
