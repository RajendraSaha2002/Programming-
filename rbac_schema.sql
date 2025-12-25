-- Run this in your PostgreSQL Query Tool (pgAdmin)

-- 1. Create Tables
CREATE TABLE IF NOT EXISTS agents (
    agent_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    clearance_level INT NOT NULL, -- 0: PUBLIC, 1: SECRET, 2: TOP SECRET
    access_code VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS classified_docs (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(100) NOT NULL,
    required_clearance INT NOT NULL,
    summary TEXT
);

-- 2. Seed Agents
INSERT INTO agents (agent_id, name, clearance_level, access_code) VALUES 
('J-117', 'John Sierra', 1, 'alpha123'),     -- SECRET
('M-007', 'Miranda Keyes', 2, 'omega999'),    -- TOP SECRET
('A-001', 'Admin Staff', 0, 'guest')          -- PUBLIC
ON CONFLICT (agent_id) DO NOTHING;

-- 3. Seed Classified Documents
INSERT INTO classified_docs (filename, required_clearance, summary) VALUES 
('Base_Cafeteria_Menu.pdf', 0, 'Standard daily meal plan for personnel.'),
('Satellite_Patrol_Routes.pdf', 1, 'SECRET: Coordinates for low-orbit surveillance assets.'),
('Nuclear_Silo_Launch_Codes.pdf', 2, 'TOP SECRET: Payload activation sequence for Sector 4.'),
('Project_Blue_Book_Roswell.pdf', 2, 'TOP SECRET: Full investigation into the 1947 crash site.');