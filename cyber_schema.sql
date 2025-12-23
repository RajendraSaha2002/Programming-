

-- 1. Create Database (Optional)
-- CREATE DATABASE cyber_def_db;

-- 2. Incidents Table (Standard Relational Data)
CREATE TABLE IF NOT EXISTS incidents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('Low', 'Medium', 'High', 'CRITICAL')),
    status VARCHAR(20) DEFAULT 'Open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Evidence Table (The JSONB Magic)
CREATE TABLE IF NOT EXISTS evidence (
    id SERIAL PRIMARY KEY,
    incident_id INT,
    description VARCHAR(255),
    
    -- THIS IS THE KEY FEATURE:
    -- We store raw logs as Binary JSON. Postgres can "read" inside this column.
    log_data JSONB, 
    
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_incident
        FOREIGN KEY(incident_id) 
        REFERENCES incidents(id)
        ON DELETE CASCADE
);

-- 4. Create a GIN Index (Makes searching inside JSON fast)
CREATE INDEX IF NOT EXISTS idx_log_data ON evidence USING GIN (log_data);

-- 5. Seed Data
INSERT INTO incidents (title, severity) VALUES 
('Suspicious Outbound Traffic', 'High'),
('Failed Login Brute Force', 'Medium');

-- Insert raw JSON logs into the evidence table
INSERT INTO evidence (incident_id, description, log_data) VALUES 
(1, 'Firewall Log', '{"src_ip": "192.168.1.50", "dest_ip": "104.22.11.0", "port": 443, "action": "allow"}'),
(1, 'IDS Alert', '{"alert_id": 9901, "src_ip": "192.168.1.50", "threat": "Malware C2"}'),
(2, 'Auth Log', '{"user": "admin", "src_ip": "45.10.11.12", "result": "failed", "attempts": 5}');