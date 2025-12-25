

-- 1. Aircraft Table (The Assets)
CREATE TABLE IF NOT EXISTS aircraft (
    id SERIAL PRIMARY KEY,
    tail_no VARCHAR(20) UNIQUE NOT NULL,
    model VARCHAR(20) NOT NULL, -- 'F-18', 'F-35', 'E-2D'
    fuel_level INT DEFAULT 100,
    maintenance_status VARCHAR(20) DEFAULT 'GOOD', -- 'GOOD', 'DOWN'
    status VARCHAR(20) DEFAULT 'ON_DECK' -- 'ON_DECK', 'AIRBORNE', 'HANGAR'
);

-- 2. Deck Spots (The Geography)
CREATE TABLE IF NOT EXISTS deck_spots (
    id SERIAL PRIMARY KEY,
    spot_name VARCHAR(50) NOT NULL, -- e.g., 'Parking 1', 'Catapult 1', 'Elevator 3'
    spot_type VARCHAR(20) NOT NULL, -- 'PARKING', 'CATAPULT', 'ELEVATOR'
    operational_status VARCHAR(20) DEFAULT 'READY', -- 'READY', 'FOUL', 'DOWN' (Maintenance)
    
    -- Which plane is parked here? (Unique constraint ensures planes don't overlap)
    occupied_by_plane_id INT UNIQUE REFERENCES aircraft(id) ON DELETE SET NULL
);

-- 3. Seed Data
-- Aircraft
INSERT INTO aircraft (tail_no, model) VALUES 
('VFA-101', 'F-18'), 
('VFA-102', 'F-18'), 
('VFA-200', 'F-35'),
('VAW-12', 'E-2D');

-- Spots
-- Parking Spots
INSERT INTO deck_spots (spot_name, spot_type) VALUES 
('Parking Alpha', 'PARKING'),
('Parking Bravo', 'PARKING'),
('Parking Charlie', 'PARKING');

-- Catapults
INSERT INTO deck_spots (spot_name, spot_type) VALUES 
('Catapult 1', 'CATAPULT'),
('Catapult 2', 'CATAPULT');

-- Elevators (One is broken)
INSERT INTO deck_spots (spot_name, spot_type, operational_status) VALUES 
('Elevator 1', 'ELEVATOR', 'READY'),
('Elevator 3', 'ELEVATOR', 'DOWN'); -- Maintenance Mode

-- Park some planes initially
UPDATE deck_spots SET occupied_by_plane_id = 1 WHERE spot_name = 'Parking Alpha';
UPDATE deck_spots SET occupied_by_plane_id = 2 WHERE spot_name = 'Parking Bravo';