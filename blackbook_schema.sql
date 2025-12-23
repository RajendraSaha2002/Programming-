
-- 1. Create the Intelligence Table
CREATE TABLE IF NOT EXISTS intel_reports (
    id SERIAL PRIMARY KEY,
    codename VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    clearance_level VARCHAR(20) NOT NULL -- 'LOW', 'TOP_SECRET'
);

-- 2. Insert Classified Data
INSERT INTO intel_reports (codename, content, clearance_level) VALUES 
('Operation Nighthawk', 'Routine patrol reports for sector 7. Nothing significant.', 'LOW'),
('Project Blue Book', 'Weather balloon sighting confirmed in Roswell.', 'LOW'),
('Operation Zeus', 'TOP SECRET: Asset located in Geneva safehouse. Awaiting extraction.', 'TOP_SECRET'),
('Area 51', 'TOP SECRET: Prototype aircraft testing schedule confirmed.', 'TOP_SECRET');

-- 3. Enable Row-Level Security (The Magic Switch)
ALTER TABLE intel_reports ENABLE ROW LEVEL SECURITY;

-- 4. Create Database Users (Roles) with specific permissions
-- We drop them first to ensure clean creation if re-running
DROP ROLE IF EXISTS junior_analyst;
DROP ROLE IF EXISTS general_wolf;

CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE general_wolf WITH LOGIN PASSWORD 'general123';

-- 5. Grant Basic "SELECT" Permission
-- Without RLS, this would give them access to EVERYTHING.
GRANT SELECT ON intel_reports TO junior_analyst;
GRANT SELECT ON intel_reports TO general_wolf;

-- 6. Define Security Policies (The Rules)

-- POLICY A: Junior Analysts can ONLY see 'LOW' clearance rows
CREATE POLICY junior_view ON intel_reports
    FOR SELECT
    TO junior_analyst
    USING (clearance_level = 'LOW');

-- POLICY B: Generals can see EVERYTHING (expression is always true)
CREATE POLICY general_view ON intel_reports
    FOR SELECT
    TO general_wolf
    USING (true);