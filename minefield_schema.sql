
-- 1. Mines Table
CREATE TABLE IF NOT EXISTS mines (
    id SERIAL PRIMARY KEY,
    latitude FLOAT NOT NULL,  -- Y coordinate (0-100 for simulation)
    longitude FLOAT NOT NULL, -- X coordinate (0-100 for simulation)
    mine_type VARCHAR(50),    -- 'Contact', 'Magnetic', 'Acoustic'
    status VARCHAR(20) DEFAULT 'ACTIVE' -- 'ACTIVE', 'NEUTRALIZED'
);

-- 2. Seed Data (A blockage in the middle)
-- We simulate a 100x100km operational box
INSERT INTO mines (latitude, longitude, mine_type, status) VALUES 
(50.0, 40.0, 'Magnetic', 'ACTIVE'),
(52.0, 42.0, 'Contact', 'ACTIVE'),
(48.0, 45.0, 'Acoustic', 'ACTIVE'),
(55.0, 50.0, 'Magnetic', 'ACTIVE'),
(45.0, 55.0, 'Contact', 'ACTIVE'),
(30.0, 70.0, 'Dummy', 'NEUTRALIZED'); -- Safe to pass