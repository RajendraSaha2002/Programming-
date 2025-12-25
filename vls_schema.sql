

-- 1. The VLS Grid Table
CREATE TABLE IF NOT EXISTS vls_cells (
    cell_id INT PRIMARY KEY, -- 1 to 96
    module_id INT,           -- 1-8 (Forward), 9-12 (Aft)
    missile_type VARCHAR(20) DEFAULT 'None', -- 'Tomahawk', 'SM-2', 'ESSM'
    status VARCHAR(20) DEFAULT 'ARMED' -- 'ARMED', 'SAFE', 'EMPTY', 'JAMMED'
);

-- Note: The Python script handles the complex seeding of 96 cells 
-- to ensure a realistic random loadout.