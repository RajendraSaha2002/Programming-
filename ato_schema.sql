

-- 1. Pilots Table
CREATE TABLE IF NOT EXISTS pilots (
    id SERIAL PRIMARY KEY,
    callsign VARCHAR(50) UNIQUE NOT NULL,
    certified_type VARCHAR(20) NOT NULL, -- e.g., 'F-35', 'A-10'
    status VARCHAR(20) DEFAULT 'READY'   -- 'READY', 'KIA', 'REST'
);

-- 2. Weapons Inventory
CREATE TABLE IF NOT EXISTS weapons (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    effect_type VARCHAR(50) NOT NULL, -- e.g., 'Penetrator', 'Anti-Armor', 'Anti-Air'
    stock INT DEFAULT 0
);

-- 3. Aircraft Fleet
CREATE TABLE IF NOT EXISTS aircraft (
    id SERIAL PRIMARY KEY,
    tail_number VARCHAR(20) UNIQUE NOT NULL,
    model_type VARCHAR(20) NOT NULL, -- e.g., 'F-35', 'A-10'
    compatible_effects TEXT[],        -- Array of effects it can carry
    status VARCHAR(20) DEFAULT 'READY'
);

-- 4. Targets Table
CREATE TABLE IF NOT EXISTS targets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    target_type VARCHAR(50) NOT NULL, -- e.g., 'Bunker', 'Tank Column'
    priority INT CHECK (priority BETWEEN 1 AND 10)
);

-- 5. Missions Table (The ATO Output)
CREATE TABLE IF NOT EXISTS missions (
    id SERIAL PRIMARY KEY,
    target_id INT REFERENCES targets(id),
    pilot_id INT REFERENCES pilots(id),
    aircraft_id INT REFERENCES aircraft(id),
    weapon_id INT REFERENCES weapons(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL
);

-- --- SEED DATA ---
INSERT INTO pilots (callsign, certified_type) VALUES 
('Maverick', 'F-35'), ('Jester', 'F-35'), ('Warthog', 'A-10'), ('Viper', 'A-10');

INSERT INTO weapons (name, effect_type, stock) VALUES 
('GBU-31 JDAM', 'Penetrator', 10),
('AGM-65 Maverick', 'Anti-Armor', 20),
('AIM-120 AMRAAM', 'Anti-Air', 15);

INSERT INTO aircraft (tail_number, model_type, compatible_effects) VALUES 
('AF-001', 'F-35', ARRAY['Penetrator', 'Anti-Air']),
('AF-002', 'F-35', ARRAY['Penetrator', 'Anti-Air']),
('AF-088', 'A-10', ARRAY['Anti-Armor']);

INSERT INTO targets (name, target_type, priority) VALUES 
('Command Bunker Z-1', 'Bunker', 10),
('Enemy Division Alpha', 'Tank Column', 7);