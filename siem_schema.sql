

DROP TABLE IF EXISTS network_logs;

CREATE TABLE IF NOT EXISTS network_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_ip VARCHAR(50),
    target_port INT,
    payload VARCHAR(255),
    classification VARCHAR(50) DEFAULT 'Analyzing...', -- 'CLEAN', 'BOTNET_ATTACK', 'BRUTE_FORCE'
    severity_level INT DEFAULT 0 -- 0=Safe, 100=Critical
);

-- Index for faster time-based queries
CREATE INDEX IF NOT EXISTS idx_time ON network_logs(timestamp);