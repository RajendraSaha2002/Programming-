

-- 1. Master Table (Partitioned)
-- We partition by 'status' to keep the "Live" table small and fast.
CREATE TABLE IF NOT EXISTS tracks (
    id SERIAL,
    track_uuid VARCHAR(20) NOT NULL,
    x_pos INT NOT NULL,
    y_pos INT NOT NULL,
    speed_knots INT NOT NULL,
    heading_deg INT NOT NULL,
    altitude_ft INT NOT NULL,
    iff_status VARCHAR(20) DEFAULT 'UNKNOWN', -- 'FRIENDLY', 'UNKNOWN', 'HOSTILE'
    
    -- The calculated "Fuzzy" score
    threat_score INT DEFAULT 0,
    
    -- Partition Key
    status VARCHAR(20) NOT NULL, -- 'LIVE', 'ENGAGED', 'DESTROYED', 'ARCHIVED'
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, status)
) PARTITION BY LIST (status);

-- 2. Create Partitions
-- The "Hot" Data (Fast queries)
CREATE TABLE tracks_active PARTITION OF tracks 
    FOR VALUES IN ('LIVE', 'ENGAGED');

-- The "Cold" Data (Logs)
CREATE TABLE tracks_history PARTITION OF tracks 
    FOR VALUES IN ('DESTROYED', 'ARCHIVED');

-- 3. Index for UUID lookups
CREATE INDEX idx_uuid ON tracks(track_uuid);