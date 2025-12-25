

-- 1. Pilots Table
CREATE TABLE IF NOT EXISTS squadron_pilots (
    id SERIAL PRIMARY KEY,
    callsign VARCHAR(50) UNIQUE NOT NULL,
    rank VARCHAR(20) NOT NULL,
    total_career_hours DECIMAL(10, 2) DEFAULT 0.0
);

-- 2. Flight Logs Table (Time-Series)
CREATE TABLE IF NOT EXISTS flight_logs (
    id SERIAL PRIMARY KEY,
    pilot_id INT REFERENCES squadron_pilots(id),
    mission_id VARCHAR(50),
    takeoff_time TIMESTAMP NOT NULL,
    landing_time TIMESTAMP NOT NULL,
    duration_hours DECIMAL(5, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Seed Data
INSERT INTO squadron_pilots (callsign, rank, total_career_hours) VALUES 
('Maverick', 'Captain', 2500.0),
('Iceman', 'Commander', 2800.0),
('Phoenix', 'Lieutenant', 850.0);

-- Seed some recent flights for Maverick to test the 50hr limit
-- Adding 48 hours of flight in the last 4 days
INSERT INTO flight_logs (pilot_id, mission_id, takeoff_time, landing_time, duration_hours) VALUES 
(1, 'OP-NORTH', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '12 hours', 12.0),
(1, 'OP-SOUTH', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '12 hours', 12.0),
(1, 'OP-EAST', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '12 hours', 12.0),
(1, 'OP-WEST', NOW() - INTERVAL '1 days', NOW() - INTERVAL '1 days' + INTERVAL '12 hours', 12.0);
-- Maverick currently has 48 hours logged in the last 7 days.