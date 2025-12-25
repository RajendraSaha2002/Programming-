

-- 1. Jets Table (The "Parent" Carrier)
CREATE TABLE IF NOT EXISTS jets (
    id SERIAL PRIMARY KEY,
    tail_number VARCHAR(20) UNIQUE NOT NULL, -- e.g., 'AF-88-001'
    model VARCHAR(20) NOT NULL -- 'F-16', 'F-35'
);

-- 2. Missiles Table (The "Child" Payload)
CREATE TABLE IF NOT EXISTS missiles (
    id SERIAL PRIMARY KEY,
    serial_number VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'AMRAAM-99-X'
    type VARCHAR(50) NOT NULL, -- 'AIM-120', 'AIM-9X'
    flight_hours DECIMAL(10, 2) DEFAULT 0.0,
    max_hours DECIMAL(10, 2) DEFAULT 100.0, -- The limit before service required
    service_status VARCHAR(20) DEFAULT 'SERVICEABLE', -- 'SERVICEABLE', 'UNSERVICEABLE'
    
    -- Which jet is it currently attached to? (NULL if in storage)
    attached_jet_id INT,
    CONSTRAINT fk_jet
        FOREIGN KEY(attached_jet_id) 
        REFERENCES jets(id)
        ON DELETE SET NULL
);

-- 3. Seed Data
INSERT INTO jets (tail_number, model) VALUES 
('Viper-1', 'F-16'),
('Panther-2', 'F-35');

-- Seed Missiles
-- Missile A: Brand new
INSERT INTO missiles (serial_number, type, flight_hours, attached_jet_id) 
VALUES ('AIM-120-ALPHA', 'AIM-120', 10.5, 1);

-- Missile B: Critical Condition (98 hours). A 3-hour flight will kill it.
INSERT INTO missiles (serial_number, type, flight_hours, attached_jet_id) 
VALUES ('AIM-9X-BRAVO', 'AIM-9X', 98.0, 1);

-- Missile C: Storage
INSERT INTO missiles (serial_number, type, flight_hours, attached_jet_id) 
VALUES ('AIM-120-CHARLIE', 'AIM-120', 45.0, NULL);