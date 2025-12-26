

-- 1. Enable the extension required for mixed-type exclusion constraints
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 2. Satellites (The Assets)
CREATE TABLE IF NOT EXISTS satellites (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL, -- 'SAT-ALPHA', 'SAT-BRAVO'
    type VARCHAR(20) -- 'OPTICAL', 'RADAR', 'INFRARED'
);

-- 3. Requests (The Queue)
CREATE TABLE IF NOT EXISTS requests (
    id SERIAL PRIMARY KEY,
    target_name VARCHAR(100) NOT NULL,
    priority INT NOT NULL, -- 1=Presidential, 2=General, 3=Routine
    satellite_id INT REFERENCES satellites(id),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING' -- 'PENDING', 'SCHEDULED', 'CONFLICT'
);

-- 4. The Schedule (The Enforcer)
CREATE TABLE IF NOT EXISTS schedule (
    id SERIAL PRIMARY KEY,
    request_id INT REFERENCES requests(id),
    satellite_id INT REFERENCES satellites(id),
    
    -- The Magic: TSTZRANGE stores the start and end as a single mathematical range
    mission_window TSTZRANGE NOT NULL,
    
    -- THE CONSTRAINT: 
    -- "Exclude rows where satellite_id is equal (=) AND time ranges overlap (&&)"
    EXCLUDE USING GIST (
        satellite_id WITH =,
        mission_window WITH &&
    )
);

-- 5. Seed Data
INSERT INTO satellites (name, type) VALUES 
('KH-11 (Keyhole)', 'OPTICAL'),
('Lacrosse-5', 'RADAR'),
('SBIRS-GEO', 'INFRARED')
ON CONFLICT (name) DO NOTHING;