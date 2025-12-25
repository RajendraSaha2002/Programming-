

-- 1. Personnel (The Badge Holders)
CREATE TABLE IF NOT EXISTS personnel (
    badge_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    rank VARCHAR(50),
    clearance_level INT NOT NULL, -- 1 (Low) to 5 (Top Secret)
    status VARCHAR(20) DEFAULT 'ACTIVE' -- 'ACTIVE', 'SUSPENDED', 'REVOKED'
);

-- 2. Gates (The Entry Points)
CREATE TABLE IF NOT EXISTS gates (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    required_clearance INT DEFAULT 1
);

-- 3. Blacklist (Stolen/Lost Badges)
CREATE TABLE IF NOT EXISTS stolen_badges (
    badge_id VARCHAR(20) PRIMARY KEY,
    reported_date DATE DEFAULT CURRENT_DATE,
    notes TEXT
);

-- 4. Access Logs (The Audit Trail)
CREATE TABLE IF NOT EXISTS access_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    badge_id VARCHAR(20),
    gate_id INT,
    result VARCHAR(20), -- 'GRANTED', 'DENIED', 'SILENT_ALARM'
    details TEXT
);

-- 5. Seed Data
-- Personnel
INSERT INTO personnel (badge_id, name, rank, clearance_level) VALUES 
('N-101', 'Admiral Vance', 'Admiral', 5),
('N-202', 'Lt. Commander Shepard', 'Officer', 3),
('N-999', 'Seaman Recruit Jones', 'Enlisted', 1);

-- Gates
INSERT INTO gates (id, name, required_clearance) VALUES 
(1, 'Main Gate (Public)', 1),
(2, 'Sector 7 (Research)', 3),
(3, 'Command & Control (CIC)', 5);

-- Stolen Badge (Simulating a threat)
INSERT INTO stolen_badges (badge_id, notes) VALUES 
('N-666', 'Reported lost at local bar. Potential compromise.');