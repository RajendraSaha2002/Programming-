

-- 1. Raw Intercepts (The "Feed")
CREATE TABLE IF NOT EXISTS raw_intercepts (
    id SERIAL PRIMARY KEY,
    sender VARCHAR(50),
    receiver VARCHAR(50),
    message_content TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_processed BOOLEAN DEFAULT FALSE
);

-- 2. Processed Intelligence (The "Value")
CREATE TABLE IF NOT EXISTS processed_intel (
    id SERIAL PRIMARY KEY,
    intercept_id INT REFERENCES raw_intercepts(id),
    entity_type VARCHAR(50), -- 'LOCATION', 'KEYWORD', 'DATE', 'PERSON'
    extracted_value VARCHAR(255),
    threat_score INT DEFAULT 0
);

-- 3. Seed Data (Simulated Traffic)
INSERT INTO raw_intercepts (sender, receiver, message_content) VALUES 
('Viper', 'Nest', 'The nuclear material has been secured at sector 7.'),
('Alpha', 'Bravo', 'Meeting scheduled for 2024-12-01 at coordinates 45.33, -12.55.'),
('Unknown', 'HQ', 'Just a routine supply run. Nothing to report.'),
('Shadow', 'Ghost', 'Target acquired. Awaiting green light for strike.');