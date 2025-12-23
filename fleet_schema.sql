

-- 1. Vehicles Table
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- e.g., 'Humvee Alpha-1'
    type VARCHAR(50),           -- 'Humvee', 'Tank', 'Truck'
    current_mileage INT DEFAULT 0,
    
    -- Maintenance Tracking Fields
    last_service_date DATE DEFAULT CURRENT_DATE,
    mileage_at_last_service INT DEFAULT 0,
    
    status VARCHAR(50) DEFAULT 'Ready' -- 'Ready', 'MAINTENANCE REQUIRED'
);

-- 2. Maintenance Logs (History)
CREATE TABLE IF NOT EXISTS maintenance_logs (
    id SERIAL PRIMARY KEY,
    vehicle_id INT,
    service_date DATE DEFAULT CURRENT_DATE,
    description TEXT,
    CONSTRAINT fk_vehicle
        FOREIGN KEY(vehicle_id) 
        REFERENCES vehicles(id)
        ON DELETE CASCADE
);

-- 3. Seed Data
-- Vehicle 1: Freshly serviced (Ready)
INSERT INTO vehicles (name, type, current_mileage, last_service_date, mileage_at_last_service)
VALUES ('Tank T-90', 'Tank', 12000, CURRENT_DATE, 12000);

-- Vehicle 2: High Mileage since last service (Should trigger Alert)
-- It had service at 30k miles, but is now at 36k miles (Difference > 5000)
INSERT INTO vehicles (name, type, current_mileage, last_service_date, mileage_at_last_service)
VALUES ('Humvee H1', 'Humvee', 36000, CURRENT_DATE, 30000);

-- Vehicle 3: Old Service Date (Should trigger Alert)
-- Service was 7 months ago
INSERT INTO vehicles (name, type, current_mileage, last_service_date, mileage_at_last_service)
VALUES ('Transport Truck', 'Truck', 5000, CURRENT_DATE - INTERVAL '7 months', 4800);