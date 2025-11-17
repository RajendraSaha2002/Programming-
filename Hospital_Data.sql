/*
================================================================================
Hospital Management System - Microsoft SQL Server Script
================================================================================
This script creates the full schema, populates it with sample data,
and implements views and stored procedures as requested.

Sections:
1. Database & Schema Creation
2. Sample Data Insertion
3. View & Stored Procedures (Reports & Tasks)
4. Demonstration
================================================================================
*/

-- Use master to check/create the database
USE master;
GO

-- Create the database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'HospitalDB')
BEGIN
    CREATE DATABASE HospitalDB;
END
GO

-- Switch to the newly created database
USE HospitalDB;
GO

/*
================================================================================
1. DATABASE & SCHEMA CREATION
   - Dropping tables in reverse order of creation to handle foreign keys
   - Creating the 5 core tables
================================================================================
*/

-- Drop existing tables if they exist (in reverse order of dependency)
DROP TABLE IF EXISTS Billing;
DROP TABLE IF EXISTS Diagnosis;
DROP TABLE IF EXISTS Appointments;
DROP TABLE IF EXISTS Doctors;
DROP TABLE IF EXISTS Patients;
GO

-- Table: Patients
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    DOB DATE NOT NULL,
    Gender NVARCHAR(10),
    Contact NVARCHAR(15),
    Address NVARCHAR(255),
    RegisteredDate DATETIME DEFAULT GETDATE()
);
GO

-- Table: Doctors
CREATE TABLE Doctors (
    DoctorID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Specialization NVARCHAR(100) NOT NULL,
    Contact NVARCHAR(15)
);
GO

-- Table: Appointments
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL REFERENCES Patients(PatientID),
    DoctorID INT NOT NULL REFERENCES Doctors(DoctorID),
    AppointmentDate DATETIME NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Scheduled'
        CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled')),
    Reason NVARCHAR(500)
);
GO

-- Table: Diagnosis
CREATE TABLE Diagnosis (
    DiagnosisID INT PRIMARY KEY IDENTITY(1,1),
    AppointmentID INT NOT NULL REFERENCES Appointments(AppointmentID),
    Notes NVARCHAR(1000) NOT NULL,
    Prescription NVARCHAR(1000)
);
GO

-- Table: Billing
CREATE TABLE Billing (
    BillID INT PRIMARY KEY IDENTITY(1,1),
    AppointmentID INT NOT NULL REFERENCES Appointments(AppointmentID),
    PatientID INT NOT NULL REFERENCES Patients(PatientID),
    BillDate DATE NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL CHECK (Amount >= 0),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (Status IN ('Pending', 'Paid'))
);
GO

PRINT 'Section 1: Database and Schema created successfully.';
GO

/*
================================================================================
2. SAMPLE DATA INSERTION
   - Populating tables with data to make reports meaningful.
   - Includes appointments for TODAY (using GETDATE())
   - Includes a patient (Jane Doe) with repeated visits.
================================================================================
*/

BEGIN TRANSACTION;
PRINT 'Inserting sample data...';

-- Insert Patients
INSERT INTO Patients (FirstName, LastName, DOB, Gender, Contact)
VALUES
('John', 'Smith', '1985-04-12', 'Male', '555-0101'),
('Jane', 'Doe', '1992-07-20', 'Female', '555-0102'),
('Michael', 'Johnson', '1978-11-30', 'Male', '555-0103'),
('Emily', 'White', '2018-02-15', 'Female', '555-0104');

-- Insert Doctors
INSERT INTO Doctors (FirstName, LastName, Specialization, Contact)
VALUES
('Alan', 'Brown', 'Cardiology', '555-0201'),
('Sarah', 'Davis', 'Pediatrics', '555-0202'),
('James', 'Wilson', 'Dermatology', '555-0203'),
('Maria', 'Garcia', 'Cardiology', '555-0204'); -- Second cardiologist for analysis

-- Insert Appointments
-- Note: We use GETDATE() to create appointments for "today"
DECLARE @Today_10AM DATETIME = DATEADD(hour, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
DECLARE @Today_2PM DATETIME = DATEADD(hour, 14, CAST(CAST(GETDATE() AS DATE) AS DATETIME));

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, Status, Reason)
VALUES
-- Past completed appointment for Jane Doe (for repeat visit task)
(2, 1, '2025-10-15 09:00:00', 'Completed', 'Annual Checkup'),
-- Past completed appointment for John Smith
(1, 3, '2025-10-20 11:00:00', 'Completed', 'Skin rash check'),
-- **Today's appointment** for Jane Doe (her 2nd visit)
(2, 1, @Today_10AM, 'Scheduled', 'Follow-up consultation'),
-- **Today's appointment** for Emily White
(4, 2, @Today_2PM, 'Scheduled', 'Vaccination'),
-- Future appointment
(3, 4, '2025-12-05 14:30:00', 'Scheduled', 'Heart pressure check');

-- Insert Diagnosis (for completed appointments)
INSERT INTO Diagnosis (AppointmentID, Notes, Prescription)
VALUES
(1, 'Normal checkup. Advised regular exercise.', 'None'),
(2, 'Contact dermatitis.', 'Hydrocortisone cream');

-- Insert Billing (for completed appointments)
INSERT INTO Billing (AppointmentID, PatientID, BillDate, Amount, Status)
VALUES
(1, 2, '2025-10-15', 150.00, 'Paid'),   -- Jane Doe's first bill
(2, 1, '2025-10-20', 120.00, 'Paid');   -- John Smith's bill

-- Add a second bill for Jane Doe, faking a lab test from her first visit
INSERT INTO Billing (AppointmentID, PatientID, BillDate, Amount, Status)
VALUES (1, 2, '2025-10-16', 75.00, 'Pending'); -- Jane Doe's second bill

COMMIT TRANSACTION;
PRINT 'Section 2: Sample data inserted successfully.';
GO

/*
================================================================================
3. VIEW & STORED PROCEDURES (Reports & Tasks)
   - v_TodaysAppointments (Task 1 - Date Functions)
   - sp_GetRepeatPatients (Task 2 - CTE)
   - sp_GetPatientBillingSummary (Task 3)
   - sp_GetSpecializationAnalysis (Task 4)
================================================================================
*/

-- Task 1: View for Appointments list for today (Uses Date Functions)
CREATE OR ALTER VIEW v_TodaysAppointments
AS
SELECT
    a.AppointmentDate,
    FORMAT(a.AppointmentDate, 'hh:mm tt') AS AppointmentTime,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    d.FirstName AS DoctorFirstName,
    d.LastName AS DoctorLastName,
    d.Specialization,
    a.Status,
    a.Reason
FROM Appointments a
JOIN Patients p ON a.PatientID = p.PatientID
JOIN Doctors d ON a.DoctorID = d.DoctorID
WHERE
    -- Use CONVERT to compare only the DATE part
    CONVERT(DATE, a.AppointmentDate) = CONVERT(DATE, GETDATE());
GO

-- Task 2: Procedure for Patients with repeated visits (Uses CTE)
CREATE OR ALTER PROCEDURE sp_GetRepeatPatients
AS
BEGIN
    SET NOCOUNT ON;

    -- Use a Common Table Expression (CTE) to count completed visits
    WITH PatientVisitCounts (PatientID, VisitCount) AS
    (
        SELECT
            PatientID,
            COUNT(AppointmentID) AS VisitCount
        FROM Appointments
        WHERE Status = 'Completed' -- Only count visits they actually attended
        GROUP BY PatientID
    )
    -- Select patients from the CTE who have more than 1 visit
    SELECT
        p.PatientID,
        p.FirstName,
        p.LastName,
        p.Contact,
        v.VisitCount
    FROM Patients p
    JOIN PatientVisitCounts v ON p.PatientID = v.PatientID
    WHERE
        v.VisitCount > 1
    ORDER BY
        v.VisitCount DESC;
END
GO

-- Task 3: Procedure for Total bill per patient
CREATE OR ALTER PROCEDURE sp_GetPatientBillingSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PatientID,
        p.FirstName,
        p.LastName,
        SUM(b.Amount) AS TotalBilledAmount,
        SUM(CASE WHEN b.Status = 'Pending' THEN b.Amount ELSE 0 END) AS TotalPendingAmount,
        COUNT(b.BillID) AS TotalBills
    FROM Patients p
    LEFT JOIN Billing b ON p.PatientID = b.PatientID
    GROUP BY
        p.PatientID, p.FirstName, p.LastName
    ORDER BY
        TotalBilledAmount DESC;
END
GO

-- Task 4: Procedure for Doctor specialization analysis
CREATE OR ALTER PROCEDURE sp_GetSpecializationAnalysis
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.Specialization,
        COUNT(d.DoctorID) AS NumberOfDoctors, -- Total doctors in specialty
        COUNT(a.AppointmentID) AS TotalAppointments -- Total appointments for specialty
    FROM Doctors d
    LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
    GROUP BY
        d.Specialization
    ORDER BY
        TotalAppointments DESC;
END
GO

PRINT 'Section 3: View and Stored Procedures created successfully.';
GO

/*
================================================================================
5. DEMONSTRATION
   - Executing the procedures and querying the view
================================================================================
*/

PRINT '========================================';
PRINT 'RUNNING DEMONSTRATION...';
PRINT '========================================';

-- Task 1: Show today''s appointments
PRINT '--- Task 1: Appointments List for Today (from v_TodaysAppointments) ---';
SELECT * FROM v_TodaysAppointments;
GO

-- Task 2: Show patients with repeated visits
PRINT '--- Task 2: Patients with Repeated Visits (from sp_GetRepeatPatients) ---';
-- Note: This will be empty until Jane Doe's 2nd appointment is marked 'Completed'
-- Let's update her first appointment to completed (already done)
-- We'll demo this by showing the "counter example" of a single-visit patient.
PRINT '--- (Note: Jane Doe has a 2nd visit scheduled, but only 1 *completed*.)';
PRINT '--- (No results expected from sp_GetRepeatPatients yet.)';
EXEC sp_GetRepeatPatients;
GO

-- Counter-Example: Show visit count for a single-visit patient (John Smith)
PRINT '--- Counter-Example: Visit count for John Smith (PatientID 1) ---';
SELECT 
    p.FirstName, 
    p.LastName, 
    (SELECT COUNT(*) FROM Appointments a WHERE a.PatientID = p.PatientID AND a.Status = 'Completed') AS CompletedVisits
FROM Patients p
WHERE p.PatientID = 1;
GO

-- Task 3: Show total bill per patient
PRINT '--- Task 3: Total Billing Summary per Patient (from sp_GetPatientBillingSummary) ---';
EXEC sp_GetPatientBillingSummary;
GO

-- Task 4: Show doctor specialization analysis
PRINT '--- Task 4: Doctor Specialization Analysis (from sp_GetSpecializationAnalysis) ---';
EXEC sp_GetSpecializationAnalysis;
GO

PRINT '========================================';
PRINT 'DEMONSTRATION COMPLETE.';
PRINT '========================================';