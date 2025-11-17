/*******************************************************************************
** Hospital Management Database Script for PostgreSQL
**
** This script defines the schema for managing hospital operations, including
** staff, patients, medical history, appointments, inventory, and billing.
*******************************************************************************/

-- =============================================================================
-- 0. CLEANUP (DROP TABLES)
--    We use the CASCADE keyword to automatically drop dependent foreign key
--    constraints, preventing the "cannot drop table departments because other
--    objects depend on it" error.
-- =============================================================================
DROP TABLE IF EXISTS billing CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS medical_history CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS departments CASCADE;


-- =============================================================================
-- 1. SCHEMA DEFINITION (DDL)
-- =============================================================================

-- Table 1: departments (Hospital departments/specialties)
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) UNIQUE NOT NULL
);

-- Table 2: staff (Doctors, Nurses, Admins)
CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    dept_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL, -- e.g., 'Doctor', 'Nurse', 'Admin'
    specialty VARCHAR(100),    -- e.g., 'Cardiology', 'Pediatrics'
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Table 3: patients (Personal information and contact details)
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    contact_no VARCHAR(20),
    address TEXT
);

-- Table 4: medical_history (Stores past diagnoses and treatments)
CREATE TABLE medical_history (
    history_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    staff_id INT, -- Doctor who recorded the history
    diagnosis TEXT NOT NULL,
    treatment_notes TEXT,
    record_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

-- Table 5: appointments (Appointment scheduling)
CREATE TABLE appointments (
    appt_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    staff_id INT NOT NULL, -- The doctor/physician
    appt_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    reason TEXT,
    status VARCHAR(50) DEFAULT 'Scheduled', -- 'Scheduled', 'Completed', 'Canceled'
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

-- Table 6: inventory (Medical supplies and equipment)
CREATE TABLE inventory (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) UNIQUE NOT NULL,
    item_type VARCHAR(50), -- e.g., 'Medicine', 'Equipment'
    stock_level INT NOT NULL,
    min_stock_alert INT NOT NULL
);

-- Table 7: billing (Patient bills for services rendered)
CREATE TABLE billing (
    bill_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    staff_id INT, -- Staff member/Doctor who authorized service
    service_type VARCHAR(100) NOT NULL, -- e.g., 'Consultation', 'Lab Test', 'Procedure'
    charges NUMERIC(10, 2) NOT NULL,
    bill_date DATE DEFAULT CURRENT_DATE,
    paid_status BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);


-- =============================================================================
-- 2. SAMPLE DATA INSERTION (DML)
-- =============================================================================

-- DEPARTMENTS
INSERT INTO departments (dept_name) VALUES
('Cardiology'), ('Pediatrics'), ('Emergency');

-- STAFF
INSERT INTO staff (dept_id, first_name, last_name, role, specialty) VALUES
(1, 'Dr. Sarah', 'Evans', 'Doctor', 'Cardiology'),
(2, 'Dr. Ben', 'Chang', 'Doctor', 'Pediatrics'),
(3, 'Nurse', 'Kelly', 'Nurse', 'Emergency');

-- PATIENTS
INSERT INTO patients (first_name, last_name, date_of_birth, contact_no, address) VALUES
('John', 'Doe', '1985-03-10', '555-1234', '101 Oak St, Cityville'),
('Jane', 'Smith', '2010-11-25', '555-5678', '202 Pine Ln, Cityville');

-- MEDICAL HISTORY
INSERT INTO medical_history (patient_id, staff_id, diagnosis, treatment_notes, record_date) VALUES
(1, 1, 'Hypertension', 'Prescribed medication A, follow-up in 3 months.', '2024-01-15'),
(2, 2, 'Routine Checkup', 'Vaccines administered. Healthy.', '2024-09-01');

-- APPOINTMENTS (Simulating one past, one upcoming)
INSERT INTO appointments (patient_id, staff_id, appt_time, reason, status) VALUES
(1, 1, '2024-01-15 09:00:00', 'Initial Consultation', 'Completed'),
(2, 2, CURRENT_TIMESTAMP + INTERVAL '1 day', 'Follow-up Checkup', 'Scheduled'), -- Upcoming
(1, 1, CURRENT_TIMESTAMP + INTERVAL '3 days', 'Stress Test', 'Scheduled'); -- Upcoming

-- INVENTORY
INSERT INTO inventory (item_name, item_type, stock_level, min_stock_alert) VALUES
('Bandages (Standard)', 'Supply', 400, 500), -- Low stock
('Flu Vaccine (Dose)', 'Medicine', 150, 50),
('Defibrillator Pads', 'Equipment', 15, 20); -- Low stock

-- BILLING
INSERT INTO billing (patient_id, staff_id, service_type, charges, bill_date, paid_status) VALUES
(1, 1, 'Consultation', 150.00, '2024-01-15', TRUE),
(2, 2, 'Vaccination', 75.00, '2024-09-01', TRUE),
(1, 1, 'Lab Test: Blood Panel', 300.50, CURRENT_DATE, FALSE); -- Outstanding Bill


-- =============================================================================
-- 3. ANALYTICAL QUERIES (BUSINESS FUNCTIONALITIES)
-- =============================================================================

-- QUERY 1: Upcoming Appointment Reminders (For the next 7 days)
-- Functionality: Appointment scheduling and reminder system.
-------------------------------------------------------------------------------
SELECT
    a.appt_time,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.contact_no,
    s.role || ' ' || s.last_name AS staff_name,
    a.reason
FROM
    appointments a
JOIN
    patients p ON a.patient_id = p.patient_id
JOIN
    staff s ON a.staff_id = s.staff_id
WHERE
    a.status = 'Scheduled'
    AND a.appt_time BETWEEN CURRENT_TIMESTAMP AND CURRENT_TIMESTAMP + INTERVAL '7 day'
ORDER BY
    a.appt_time ASC;

-- QUERY 2: Low Stock Alerts (Inventory Management)
-- Functionality: Automatically identify and alert on low stock items.
-------------------------------------------------------------------------------
SELECT
    item_name,
    item_type,
    stock_level,
    min_stock_alert AS required_stock,
    (min_stock_alert - stock_level) AS deficit
FROM
    inventory
WHERE
    stock_level < min_stock_alert
ORDER BY
    deficit DESC;

-- QUERY 3: Detailed Patient Medical History
-- Functionality: Retrieve complete medical history for a specific patient (Patient ID 1).
-------------------------------------------------------------------------------
SELECT
    mh.record_date,
    mh.diagnosis,
    mh.treatment_notes,
    s.first_name || ' ' || s.last_name AS recorded_by_doctor
FROM
    medical_history mh
JOIN
    patients p ON mh.patient_id = p.patient_id
LEFT JOIN
    staff s ON mh.staff_id = s.staff_id
WHERE
    p.patient_id = 1 -- Targeting Patient John Doe
ORDER BY
    mh.record_date DESC;

-- QUERY 4: Outstanding Patient Bills
-- Functionality: Creating and managing patient bills for services.
-------------------------------------------------------------------------------
SELECT
    b.bill_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    b.bill_date,
    b.service_type,
    b.charges,
    s.role || ' ' || s.last_name AS service_provider
FROM
    billing b
JOIN
    patients p ON b.patient_id = p.patient_id
LEFT JOIN
    staff s ON b.staff_id = s.staff_id
WHERE
    b.paid_status = FALSE
ORDER BY
    b.bill_date ASC;

-- QUERY 5: Doctor Workload Summary
-- Purpose: Analyze staff workload by counting completed appointments.
-------------------------------------------------------------------------------
SELECT
    s.first_name || ' ' || s.last_name AS doctor_name,
    s.specialty,
    COUNT(a.appt_id) AS total_completed_appointments
FROM
    staff s
LEFT JOIN
    appointments a ON s.staff_id = a.staff_id
WHERE
    s.role = 'Doctor' AND a.status = 'Completed'
GROUP BY
    s.staff_id, doctor_name, s.specialty
ORDER BY
    total_completed_appointments DESC;
