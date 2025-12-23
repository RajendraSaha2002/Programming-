

-- 1. Create Database (Optional)
-- CREATE DATABASE biometric_db;

-- 2. Access Logs Table
CREATE TABLE IF NOT EXISTS access_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id VARCHAR(50),
    door_id VARCHAR(50),
    access_granted BOOLEAN -- TRUE = Success, FALSE = Fail/Denied
);

-- 3. THE IMMUTABLE TRIGGER (Security Feature)
-- First, define the function that runs when someone tries to delete
CREATE OR REPLACE FUNCTION prevent_log_deletion()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'SECURITY ALERT: Access Logs are Immutable. Deletion is strictly prohibited.';
END;
$$ LANGUAGE plpgsql;

-- Second, attach the function to the table
DROP TRIGGER IF EXISTS trigger_immutable_logs ON access_logs;

CREATE TRIGGER trigger_immutable_logs
BEFORE DELETE ON access_logs
FOR EACH ROW
EXECUTE FUNCTION prevent_log_deletion();

-- 4. Seed Data
INSERT INTO access_logs (user_id, door_id, access_granted) VALUES 
('Officer_K', 'Sector_7', TRUE),
('Officer_K', 'Sector_7', TRUE),
('Unknown', 'Sector_7', FALSE);