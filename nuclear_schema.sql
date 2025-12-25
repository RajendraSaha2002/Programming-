

-- 1. Authorized Officers Table
CREATE TABLE IF NOT EXISTS officers (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL, -- Storing the BCRYPT hash, not plain text
    rank VARCHAR(50) NOT NULL
);

-- 2. Audit Log (Immutable History)
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    action VARCHAR(100), -- 'KEY_TURN_1', 'KEY_TURN_2', 'LAUNCH_AUTHORIZED', 'TIMEOUT'
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(20) DEFAULT '127.0.0.1'
);

-- Note: We do NOT seed users here because we need Python to generate the Bcrypt hashes.
-- The Python script will handle the initial seeding.