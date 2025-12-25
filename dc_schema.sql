
-- 1. Ship Compartments (The Graph Nodes)
CREATE TABLE IF NOT EXISTS compartments (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    x_coord INT NOT NULL, -- For UI plotting
    y_coord INT NOT NULL,
    
    -- Graph Edges: Which rooms connect to this one?
    neighbor_ids INT[] 
);

-- 2. Active Incidents (The State)
CREATE TABLE IF NOT EXISTS incidents (
    room_id INT PRIMARY KEY REFERENCES compartments(id),
    type VARCHAR(20) NOT NULL, -- 'FIRE', 'FLOOD', 'SMOKE'
    severity INT DEFAULT 1
);

-- 3. Seed Data (A simplified Deck Plan)
-- Layout:
-- [Bridge 101] -- [Hallway 102] -- [Mess Hall 103]
--                      |
--                 [Engine Room 201] -- [Fuel Storage 202]
--                      |
--                 [Ammo Magazine 301]

INSERT INTO compartments (id, name, x_coord, y_coord, neighbor_ids) VALUES 
(101, 'Bridge',       100, 100, ARRAY[102]),
(102, 'Main Hallway', 300, 100, ARRAY[101, 103, 201]),
(103, 'Mess Hall',    500, 100, ARRAY[102]),
(201, 'Engine Room',  300, 300, ARRAY[102, 202, 301]),
(202, 'Fuel Storage', 500, 300, ARRAY[201]),
(301, 'Ammo Magazine',300, 500, ARRAY[201]);