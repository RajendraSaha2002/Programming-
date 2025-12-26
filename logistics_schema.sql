

-- 1. Immutable Ledger
CREATE TABLE IF NOT EXISTS ledger_immutable (
    transaction_hash VARCHAR(64) PRIMARY KEY, -- SHA-256
    item_id VARCHAR(50) NOT NULL,
    item_type VARCHAR(20) DEFAULT 'STANDARD', -- 'STANDARD', 'SENSITIVE', 'HAZMAT'
    from_loc VARCHAR(50) NOT NULL,
    to_loc VARCHAR(50) NOT NULL,
    officer_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Seed Data (Simulated history)
-- Normal movement
INSERT INTO ledger_immutable (transaction_hash, item_id, item_type, from_loc, to_loc, officer_id, timestamp) 
VALUES ('hash_1', 'AMMO-BOX-101', 'SENSITIVE', 'Depot A', 'Truck 5', 'CPT-Miller', NOW() - INTERVAL '1 hour');

-- Suspicious movement (Rapid transfers)
INSERT INTO ledger_immutable (transaction_hash, item_id, item_type, from_loc, to_loc, officer_id, timestamp) 
VALUES ('hash_2', 'PART-X99', 'STANDARD', 'Warehouse 1', 'Dock A', 'LT-Dan', NOW() - INTERVAL '2 minutes');

INSERT INTO ledger_immutable (transaction_hash, item_id, item_type, from_loc, to_loc, officer_id, timestamp) 
VALUES ('hash_3', 'PART-X99', 'STANDARD', 'Dock A', 'Ship B', 'LT-Dan', NOW() - INTERVAL '1 minute');