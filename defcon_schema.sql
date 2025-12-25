

-- 1. Master Checklist Table
CREATE TABLE IF NOT EXISTS defcon_checklist (
    id SERIAL PRIMARY KEY,
    defcon_level INT CHECK (defcon_level BETWEEN 1 AND 5),
    task_description TEXT NOT NULL,
    dept_head VARCHAR(50) NOT NULL, -- e.g., 'Signal Officer', 'Security Chief'
    is_completed BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Clear previous data and seed the Master Protocols
TRUNCATE TABLE defcon_checklist;

-- DEFCON 5 (Normal)
INSERT INTO defcon_checklist (defcon_level, task_description, dept_head) VALUES 
(5, 'Routine security patrols initialized', 'Security Chief'),
(5, 'Standard comms encryption active', 'Signal Officer');

-- DEFCON 4 (Increased Intel/Security)
INSERT INTO defcon_checklist (defcon_level, task_description, dept_head) VALUES 
(4, 'Double guard rotation at Perimeter Gates', 'Security Chief'),
(4, 'Monitor civilian frequencies for anomalies', 'Intel Officer');

-- DEFCON 3 (Increase in Readiness)
INSERT INTO defcon_checklist (defcon_level, task_description, dept_head) VALUES 
(3, 'Recall all personnel to barracks', 'Base Commander'),
(3, 'Initialize Air Defense Radar arrays', 'Air Boss'),
(3, 'Verify secondary power generators', 'Engineering');

-- DEFCON 2 (High Readiness / Prep for War)
INSERT INTO defcon_checklist (defcon_level, task_description, dept_head) VALUES 
(2, 'Seal secondary blast doors', 'Engineering'),
(2, 'Distribute live ammunition to all units', 'Logistics'),
(2, 'Initiate silent comms protocol (EMCON)', 'Signal Officer');

-- DEFCON 1 (Maximum Readiness / Imminent War)
INSERT INTO defcon_checklist (defcon_level, task_description, dept_head) VALUES 
(1, 'Unlock nuclear release safeties', 'Weapon Officer'),
(1, 'Evacuate non-essential personnel to bunkers', 'Base Commander'),
(1, 'Full combat air patrol (CAP) launched', 'Air Boss');