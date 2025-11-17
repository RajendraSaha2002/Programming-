/*******************************************************************************
** Crime Reports Database Script
**
** This script defines the schema, populates tables with sample data, and
** provides analytical queries for a system tracking crime incidents.
*******************************************************************************/

-- =============================================================================
-- 1. SCHEMA DEFINITION (DDL)
-- =============================================================================

-- Table 1: crime_types - Lookup table for offense categories
CREATE TABLE crime_types (
    crime_type_id INT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    severity_level INT -- 1 (low) to 5 (high)
);

-- Table 2: officers - Information on police units or reporting officers
CREATE TABLE officers (
    officer_id INT PRIMARY KEY,
    unit_badge_number VARCHAR(20) UNIQUE NOT NULL,
    division VARCHAR(50),
    rank_level VARCHAR(50)
);

-- Table 3: incidents - Main table for reported crimes
CREATE TABLE incidents (
    incident_id INT PRIMARY KEY,
    crime_type_id INT,
    reporting_officer_id INT,
    incident_date DATE NOT NULL,
    incident_time TIME,
    location_street VARCHAR(255) NOT NULL,
    location_type VARCHAR(50), -- e.g., 'Residential', 'Commercial', 'Public Park'
    case_status VARCHAR(50), -- e.g., 'Active', 'Closed - Arrest Made', 'Closed - Unsolved'
    reported_minutes_delay INT, -- Time between occurrence and report (in minutes)
    -- Foreign Key constraints
    FOREIGN KEY (crime_type_id) REFERENCES crime_types(crime_type_id),
    FOREIGN KEY (reporting_officer_id) REFERENCES officers(officer_id)
);


-- =============================================================================
-- 2. SAMPLE DATA INSERTION (DML)
-- =============================================================================

-- CRIME_TYPES
INSERT INTO crime_types (crime_type_id, type_name, severity_level) VALUES
(1, 'Vandalism', 1),
(2, 'Larceny/Theft', 2),
(3, 'Assault', 3),
(4, 'Burglary', 4),
(5, 'Homicide', 5);

-- OFFICERS
INSERT INTO officers (officer_id, unit_badge_number, division, rank_level) VALUES
(10, 'A401', 'North Precinct', 'Officer'),
(11, 'B505', 'Central Precinct', 'Sergeant'),
(12, 'C612', 'Traffic Division', 'Officer');

-- INCIDENTS
INSERT INTO incidents (incident_id, crime_type_id, reporting_officer_id, incident_date, incident_time, location_street, location_type, case_status, reported_minutes_delay) VALUES
(1001, 2, 10, '2024-10-01', '14:30:00', '123 Oak St', 'Commercial', 'Closed - Arrest Made', 15),
(1002, 3, 11, '2024-10-01', '21:45:00', '45 Elm Ave', 'Residential', 'Active', 0),
(1003, 1, 10, '2024-10-02', '09:00:00', 'Public Park Central', 'Public Park', 'Closed - Unsolved', 120),
(1004, 4, 12, '2024-10-03', '03:15:00', '789 Pine Ln', 'Residential', 'Active', 5),
(1005, 2, 11, '2024-10-03', '11:00:00', 'Mall Entrance', 'Commercial', 'Active', 60),
(1006, 5, 11, '2024-10-04', '00:00:00', 'Bridge Over River', 'Infrastructure', 'Active', 0);


-- =============================================================================
-- 3. 5 KEY CRIME REPORT ANALYSIS QUERIES (DQL)
-- =============================================================================

-- QUERY 1: Incident Count by Crime Type and Severity
-- Purpose: See which types of crimes are most common and their relative severity.
-------------------------------------------------------------------------------
SELECT
    ct.type_name,
    ct.severity_level,
    COUNT(i.incident_id) AS total_incidents
FROM
    incidents i
JOIN
    crime_types ct ON i.crime_type_id = ct.crime_type_id
GROUP BY
    ct.type_name, ct.severity_level
ORDER BY
    total_incidents DESC;

-- QUERY 2: Case Resolution Status by Officer Division
-- Purpose: Evaluate the effectiveness of different police divisions in closing cases.
-------------------------------------------------------------------------------
SELECT
    o.division,
    i.case_status,
    COUNT(i.incident_id) AS total_cases
FROM
    incidents i
JOIN
    officers o ON i.reporting_officer_id = o.officer_id
GROUP BY
    o.division, i.case_status
ORDER BY
    o.division, total_cases DESC;

-- QUERY 3: Average Reporting Delay by Location Type
-- Purpose: Identify locations where crime is reported significantly later, suggesting awareness issues.
-------------------------------------------------------------------------------
SELECT
    location_type,
    CAST(AVG(reported_minutes_delay) AS DECIMAL(10, 2)) AS avg_delay_minutes
FROM
    incidents
GROUP BY
    location_type
ORDER BY
    avg_delay_minutes DESC;

-- QUERY 4: High-Severity Incidents by Time of Day
-- Purpose: Pinpoint peak times for serious crimes (Severity 3 and above).
-------------------------------------------------------------------------------
SELECT
    i.incident_date,
    i.incident_time,
    ct.type_name
FROM
    incidents i
JOIN
    crime_types ct ON i.crime_type_id = ct.crime_type_id
WHERE
    ct.severity_level >= 3
ORDER BY
    i.incident_time;

-- QUERY 5: Officer Reporting Volume
-- Purpose: Find the total number of incidents reported by each officer/unit.
-------------------------------------------------------------------------------
SELECT
    o.unit_badge_number,
    o.division,
    o.rank_level,
    COUNT(i.incident_id) AS incidents_reported
FROM
    officers o
LEFT JOIN
    incidents i ON o.officer_id = i.reporting_officer_id
GROUP BY
    o.officer_id, o.unit_badge_number, o.division, o.rank_level
ORDER BY
    incidents_reported DESC;
