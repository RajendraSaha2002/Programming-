

-- 1. Acoustic Signatures Table
CREATE TABLE IF NOT EXISTS signatures (
    id SERIAL PRIMARY KEY,
    class_name VARCHAR(50) NOT NULL, -- e.g., 'Akula II', 'Los Angeles'
    country VARCHAR(50) NOT NULL,
    prop_blade_count INT NOT NULL,   -- Unique identifier feature
    base_frequency FLOAT NOT NULL,   -- The "Hum" in Hz
    noise_level VARCHAR(20),         -- 'Silent', 'Quiet', 'Noisy'
    notes TEXT
);

-- 2. Seed Data (Simulated Acoustic Intelligence)
-- Russian Subs
INSERT INTO signatures (class_name, country, prop_blade_count, base_frequency, noise_level, notes) VALUES 
('Akula Class II', 'Russia', 7, 50.0, 'Quiet', 'Distinctive 50Hz hum from coolant pumps.'),
('Kilo Class (Project 877)', 'Russia', 6, 45.5, 'Silent', ' Known as the "Black Hole" due to silence.'),
('Typhoon Class', 'Russia', 7, 38.0, 'Noisy', 'Large displacement creates turbulence.');

-- US Subs
INSERT INTO signatures (class_name, country, prop_blade_count, base_frequency, noise_level, notes) VALUES 
('Los Angeles Class (688i)', 'USA', 7, 60.0, 'Quiet', 'Standard USN 60Hz electrical grid hum.'),
('Virginia Class', 'USA', 9, 55.0, 'Silent', 'Pump-jet propulsor makes blade count hard to isolate.'),
('Seawolf Class', 'USA', 8, 42.0, 'Silent', 'Optimized for deep water stealth.');

-- Chinese Subs
INSERT INTO signatures (class_name, country, prop_blade_count, base_frequency, noise_level, notes) VALUES 
('Type 093 Shang', 'China', 7, 52.0, 'Quiet', 'Reactors emit high-pitch whine.'),
('Type 039A Yuan', 'China', 7, 48.0, 'Silent', 'AIP system active.');