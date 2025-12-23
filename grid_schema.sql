

-- 1. Sectors Table (The Physical Grid)
CREATE TABLE IF NOT EXISTS sectors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'SECURE', -- 'SECURE', 'WARNING', 'ALARM', 'OFFLINE'
    last_patrol TIMESTAMP
);

-- 2. Event Logs (The "Fusion" History)
CREATE TABLE IF NOT EXISTS event_logs (
    id SERIAL PRIMARY KEY,
    sector_id INT,
    event_type VARCHAR(50), -- 'MOTION', 'CAMERA_HUMAN', 'FUSED_ALARM'
    description TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Seed Data (4 Sectors)
INSERT INTO sectors (name) VALUES 
('North Gate'), ('East Wall'), ('South Loading'), ('West Parking');