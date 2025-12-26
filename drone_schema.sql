

-- 1. Drone Telemetry Table
CREATE TABLE IF NOT EXISTS drone_telemetry (
    drone_id VARCHAR(10) PRIMARY KEY,
    status VARCHAR(20) DEFAULT 'CHARGING', -- CHARGING, READY, FLYING, ERROR
    battery_level INT DEFAULT 100,
    current_sector VARCHAR(10) DEFAULT 'BASE',
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Surveillance Logs (The Analysis Results)
CREATE TABLE IF NOT EXISTS surveillance_logs (
    id SERIAL PRIMARY KEY,
    drone_id VARCHAR(10) REFERENCES drone_telemetry(drone_id),
    image_path TEXT,
    analysis_result VARCHAR(50), -- 'SAFE', 'FIRE DETECTED'
    confidence_score DECIMAL(5,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Seed the Swarm (10 Drones for this demo)
INSERT INTO drone_telemetry (drone_id, status) VALUES 
('DRONE-01', 'CHARGING'), ('DRONE-02', 'CHARGING'),
('DRONE-03', 'READY'),    ('DRONE-04', 'READY'),
('DRONE-05', 'FLYING'),   ('DRONE-06', 'FLYING'),
('DRONE-07', 'CHARGING'), ('DRONE-08', 'ERROR'),
('DRONE-09', 'FLYING'),   ('DRONE-10', 'READY')
ON CONFLICT (drone_id) DO NOTHING;