-- =============================================
-- Hospital Management System - SQL Server Script
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'HospitalManagementDB')
BEGIN
    CREATE DATABASE HospitalManagementDB;
END
GO

USE HospitalManagementDB;
GO

-- =============================================
-- DROP EXISTING TABLES (IF ANY)
-- =============================================
IF OBJECT_ID('Billing', 'U') IS NOT NULL DROP TABLE Billing;
IF OBJECT_ID('Diagnosis', 'U') IS NOT NULL DROP TABLE Diagnosis;
IF OBJECT_ID('Appointments', 'U') IS NOT NULL DROP TABLE Appointments;
IF OBJECT_ID('Doctors', 'U') IS NOT NULL DROP TABLE Doctors;
IF OBJECT_ID('Patients', 'U') IS NOT NULL DROP TABLE Patients;
GO

-- =============================================
-- TABLE: Patients
-- =============================================
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F', 'O')),
    PhoneNumber NVARCHAR(15),
    Email NVARCHAR(100),
    Address NVARCHAR(255),
    BloodGroup NVARCHAR(5),
    RegistrationDate DATE DEFAULT GETDATE(),
    CONSTRAINT CHK_DOB CHECK (DateOfBirth < GETDATE())
);
GO

-- =============================================
-- TABLE: Doctors
-- =============================================
CREATE TABLE Doctors (
    DoctorID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Specialization NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(15),
    Email NVARCHAR(100),
    LicenseNumber NVARCHAR(50) UNIQUE NOT NULL,
    ExperienceYears INT,
    ConsultationFee DECIMAL(10,2),
    JoinDate DATE DEFAULT GETDATE()
);
GO

-- =============================================
-- TABLE: Appointments
-- =============================================
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT FOREIGN KEY REFERENCES Patients(PatientID),
    DoctorID INT FOREIGN KEY REFERENCES Doctors(DoctorID),
    AppointmentDate DATE NOT NULL,
    AppointmentTime TIME NOT NULL,
    Status NVARCHAR(20) CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')) DEFAULT 'Scheduled',
    ReasonForVisit NVARCHAR(255),
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

-- =============================================
-- TABLE: Diagnosis
-- =============================================
CREATE TABLE Diagnosis (
    DiagnosisID INT PRIMARY KEY IDENTITY(1,1),
    AppointmentID INT FOREIGN KEY REFERENCES Appointments(AppointmentID),
    PatientID INT FOREIGN KEY REFERENCES Patients(PatientID),
    DoctorID INT FOREIGN KEY REFERENCES Doctors(DoctorID),
    DiagnosisDate DATE DEFAULT GETDATE(),
    Symptoms NVARCHAR(500),
    DiagnosisDetails NVARCHAR(1000),
    Prescription NVARCHAR(1000),
    FollowUpDate DATE
);
GO

-- =============================================
-- TABLE: Billing
-- =============================================
CREATE TABLE Billing (
    BillID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT FOREIGN KEY REFERENCES Patients(PatientID),
    AppointmentID INT FOREIGN KEY REFERENCES Appointments(AppointmentID),
    BillDate DATE DEFAULT GETDATE(),
    ConsultationCharges DECIMAL(10,2),
    MedicineCharges DECIMAL(10,2) DEFAULT 0,
    LabCharges DECIMAL(10,2) DEFAULT 0,
    OtherCharges DECIMAL(10,2) DEFAULT 0,
    TotalAmount AS (ConsultationCharges + MedicineCharges + LabCharges + OtherCharges) PERSISTED,
    PaymentStatus NVARCHAR(20) CHECK (PaymentStatus IN ('Paid', 'Pending', 'Partial')) DEFAULT 'Pending',
    PaymentDate DATE
);
GO

-- =============================================
-- SAMPLE DATA INSERTION
-- =============================================

-- Insert Patients
INSERT INTO Patients (FirstName, LastName, DateOfBirth, Gender, PhoneNumber, Email, Address, BloodGroup, RegistrationDate)
VALUES 
    ('John', 'Doe', '1985-03-15', 'M', '555-0101', 'john.doe@email.com', '123 Main St', 'O+', '2024-01-10'),
    ('Jane', 'Smith', '1990-07-22', 'F', '555-0102', 'jane.smith@email.com', '456 Oak Ave', 'A+', '2024-02-15'),
    ('Robert', 'Johnson', '1978-11-30', 'M', '555-0103', 'robert.j@email.com', '789 Pine Rd', 'B+', '2024-01-20'),
    ('Emily', 'Williams', '1995-05-18', 'F', '555-0104', 'emily.w@email.com', '321 Elm St', 'AB-', '2024-03-05'),
    ('Michael', 'Brown', '1982-09-25', 'M', '555-0105', 'michael.b@email.com', '654 Maple Dr', 'O-', '2024-02-28'),
    ('Sarah', 'Davis', '1988-12-08', 'F', '555-0106', 'sarah.d@email.com', '987 Cedar Ln', 'A-', '2024-01-15');
GO

-- Insert Doctors
INSERT INTO Doctors (FirstName, LastName, Specialization, PhoneNumber, Email, LicenseNumber, ExperienceYears, ConsultationFee, JoinDate)
VALUES 
    ('Dr. James', 'Anderson', 'Cardiology', '555-1001', 'dr.anderson@hospital.com', 'LIC001', 15, 200.00, '2020-01-15'),
    ('Dr. Lisa', 'Martinez', 'Pediatrics', '555-1002', 'dr.martinez@hospital.com', 'LIC002', 10, 150.00, '2021-03-20'),
    ('Dr. David', 'Taylor', 'Orthopedics', '555-1003', 'dr.taylor@hospital.com', 'LIC003', 12, 180.00, '2019-06-10'),
    ('Dr. Susan', 'Wilson', 'Dermatology', '555-1004', 'dr.wilson@hospital.com', 'LIC004', 8, 160.00, '2022-02-28'),
    ('Dr. Mark', 'Moore', 'Neurology', '555-1005', 'dr.moore@hospital.com', 'LIC005', 20, 250.00, '2018-09-05'),
    ('Dr. Nancy', 'Lee', 'General Medicine', '555-1006', 'dr.lee@hospital.com', 'LIC006', 7, 120.00, '2023-01-10');
GO

-- Insert Appointments (Including today's date and historical dates)
INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Status, ReasonForVisit, CreatedDate)
VALUES 
    -- Today's appointments
    (1, 1, CAST(GETDATE() AS DATE), '09:00', 'Scheduled', 'Chest pain checkup', GETDATE()),
    (2, 2, CAST(GETDATE() AS DATE), '10:30', 'Scheduled', 'Child vaccination', GETDATE()),
    (3, 3, CAST(GETDATE() AS DATE), '14:00', 'Scheduled', 'Knee pain', GETDATE()),
    (4, 4, CAST(GETDATE() AS DATE), '15:30', 'Completed', 'Skin rash', GETDATE()),
    (5, 6, CAST(GETDATE() AS DATE), '11:00', 'Scheduled', 'Fever and cold', GETDATE()),
    
    -- Past appointments (for repeated visits analysis)
    (1, 1, '2024-10-15', '09:00', 'Completed', 'Regular checkup', '2024-10-10'),
    (1, 1, '2024-09-20', '10:00', 'Completed', 'Follow-up visit', '2024-09-15'),
    (1, 5, '2024-08-10', '11:00', 'Completed', 'Headache consultation', '2024-08-05'),
    (2, 2, '2024-10-05', '14:00', 'Completed', 'Child health checkup', '2024-10-01'),
    (3, 3, '2024-09-25', '09:30', 'Completed', 'Back pain', '2024-09-20'),
    (3, 3, '2024-08-15', '10:00', 'Completed', 'Follow-up for back pain', '2024-08-10'),
    (4, 4, '2024-11-01', '13:00', 'Completed', 'Acne treatment', '2024-10-28'),
    (5, 6, '2024-10-20', '15:00', 'Completed', 'General health', '2024-10-15'),
    (6, 1, '2024-11-10', '10:00', 'Completed', 'Heart checkup', '2024-11-05');
GO

-- Insert Diagnosis
INSERT INTO Diagnosis (AppointmentID, PatientID, DoctorID, DiagnosisDate, Symptoms, DiagnosisDetails, Prescription, FollowUpDate)
VALUES 
    (6, 1, 1, '2024-10-15', 'Chest discomfort, fatigue', 'Mild hypertension detected', 'Amlodipine 5mg daily', '2024-11-15'),
    (7, 1, 1, '2024-09-20', 'Follow-up checkup', 'Blood pressure under control', 'Continue medication', '2024-10-20'),
    (8, 1, 5, '2024-08-10', 'Severe headache, dizziness', 'Migraine diagnosed', 'Sumatriptan 50mg as needed', '2024-09-10'),
    (9, 2, 2, '2024-10-05', 'Routine checkup', 'Child healthy, growth normal', 'Multivitamin supplements', NULL),
    (10, 3, 3, '2024-09-25', 'Lower back pain, stiffness', 'Muscle strain', 'Ibuprofen 400mg, Physiotherapy', '2024-10-25'),
    (11, 3, 3, '2024-08-15', 'Persistent back pain', 'Improving condition', 'Continue physiotherapy', '2024-09-15'),
    (12, 4, 4, '2024-11-01', 'Facial acne, oily skin', 'Acne vulgaris', 'Benzoyl peroxide gel, Doxycycline', '2024-12-01'),
    (13, 5, 6, '2024-10-20', 'General wellness check', 'All parameters normal', 'Healthy diet advice', NULL),
    (14, 6, 1, '2024-11-10', 'Palpitations', 'ECG normal, anxiety-related', 'Stress management counseling', '2024-12-10');
GO

-- Insert Billing
INSERT INTO Billing (PatientID, AppointmentID, BillDate, ConsultationCharges, MedicineCharges, LabCharges, OtherCharges, PaymentStatus, PaymentDate)
VALUES 
    (1, 6, '2024-10-15', 200.00, 50.00, 100.00, 0.00, 'Paid', '2024-10-15'),
    (1, 7, '2024-09-20', 200.00, 50.00, 0.00, 0.00, 'Paid', '2024-09-20'),
    (1, 8, '2024-08-10', 250.00, 75.00, 150.00, 0.00, 'Paid', '2024-08-10'),
    (2, 9, '2024-10-05', 150.00, 30.00, 50.00, 0.00, 'Paid', '2024-10-05'),
    (3, 10, '2024-09-25', 180.00, 40.00, 80.00, 100.00, 'Paid', '2024-09-25'),
    (3, 11, '2024-08-15', 180.00, 40.00, 0.00, 100.00, 'Paid', '2024-08-15'),
    (4, 12, '2024-11-01', 160.00, 60.00, 0.00, 0.00, 'Paid', '2024-11-01'),
    (4, 4, CAST(GETDATE() AS DATE), 160.00, 45.00, 0.00, 0.00, 'Pending', NULL),
    (5, 13, '2024-10-20', 120.00, 0.00, 120.00, 0.00, 'Paid', '2024-10-20'),
    (6, 14, '2024-11-10', 200.00, 0.00, 200.00, 50.00, 'Paid', '2024-11-10');
GO

-- =============================================
-- SQL TASKS
-- =============================================

-- =============================================
-- TASK 1: Appointments List for Today
-- Using CTE and Date Functions
-- =============================================
PRINT '=== TASK 1: Today''s Appointments ===';
GO

WITH TodaysAppointments AS (
    SELECT 
        a.AppointmentID,
        a.AppointmentDate,
        a.AppointmentTime,
        CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
        p.PhoneNumber AS PatientPhone,
        CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
        d.Specialization,
        a.ReasonForVisit,
        a.Status,
        -- Calculate age of patient
        DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) - 
            CASE 
                WHEN MONTH(p.DateOfBirth) > MONTH(GETDATE()) 
                    OR (MONTH(p.DateOfBirth) = MONTH(GETDATE()) AND DAY(p.DateOfBirth) > DAY(GETDATE()))
                THEN 1 
                ELSE 0 
            END AS PatientAge
    FROM Appointments a
    INNER JOIN Patients p ON a.PatientID = p.PatientID
    INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
    WHERE a.AppointmentDate = CAST(GETDATE() AS DATE)
)
SELECT * 
FROM TodaysAppointments
ORDER BY AppointmentTime;
GO

-- =============================================
-- TASK 2: Patients with Repeated Visits
-- Using CTE and Subqueries
-- =============================================
PRINT '=== TASK 2: Patients with Repeated Visits ===';
GO

WITH PatientVisitCount AS (
    SELECT 
        p.PatientID,
        CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
        p.PhoneNumber,
        p.Email,
        COUNT(a.AppointmentID) AS TotalVisits,
        MIN(a.AppointmentDate) AS FirstVisitDate,
        MAX(a.AppointmentDate) AS LastVisitDate,
        -- Calculate days between first and last visit
        DATEDIFF(DAY, MIN(a.AppointmentDate), MAX(a.AppointmentDate)) AS DaysBetweenVisits
    FROM Patients p
    INNER JOIN Appointments a ON p.PatientID = a.PatientID
    WHERE a.Status IN ('Completed', 'Scheduled')
    GROUP BY p.PatientID, p.FirstName, p.LastName, p.PhoneNumber, p.Email
    HAVING COUNT(a.AppointmentID) > 1
),
VisitDetails AS (
    SELECT 
        pvc.*,
        -- Subquery to get most visited doctor
        (SELECT TOP 1 CONCAT(d.FirstName, ' ', d.LastName)
         FROM Appointments a
         INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
         WHERE a.PatientID = pvc.PatientID
         GROUP BY d.DoctorID, d.FirstName, d.LastName
         ORDER BY COUNT(*) DESC) AS MostVisitedDoctor,
        -- Subquery to get most common reason
        (SELECT TOP 1 a.ReasonForVisit
         FROM Appointments a
         WHERE a.PatientID = pvc.PatientID AND a.ReasonForVisit IS NOT NULL
         GROUP BY a.ReasonForVisit
         ORDER BY COUNT(*) DESC) AS MostCommonReason
    FROM PatientVisitCount pvc
)
SELECT 
    PatientName,
    PhoneNumber,
    TotalVisits,
    FirstVisitDate,
    LastVisitDate,
    DaysBetweenVisits,
    MostVisitedDoctor,
    MostCommonReason,
    CASE 
        WHEN TotalVisits > 5 THEN 'Frequent Visitor'
        WHEN TotalVisits > 2 THEN 'Regular Visitor'
        ELSE 'Occasional Visitor'
    END AS VisitorType
FROM VisitDetails
ORDER BY TotalVisits DESC;
GO

-- =============================================
-- TASK 3: Total Bill Per Patient
-- Using CTE and Window Functions
-- =============================================
PRINT '=== TASK 3: Total Bill Per Patient ===';
GO

WITH PatientBilling AS (
    SELECT 
        p.PatientID,
        CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
        p.PhoneNumber,
        COUNT(DISTINCT b.BillID) AS TotalBills,
        SUM(b.ConsultationCharges) AS TotalConsultationCharges,
        SUM(b.MedicineCharges) AS TotalMedicineCharges,
        SUM(b.LabCharges) AS TotalLabCharges,
        SUM(b.OtherCharges) AS TotalOtherCharges,
        SUM(b.TotalAmount) AS GrandTotal,
        SUM(CASE WHEN b.PaymentStatus = 'Paid' THEN b.TotalAmount ELSE 0 END) AS TotalPaid,
        SUM(CASE WHEN b.PaymentStatus = 'Pending' THEN b.TotalAmount ELSE 0 END) AS TotalPending,
        MIN(b.BillDate) AS FirstBillDate,
        MAX(b.BillDate) AS LastBillDate
    FROM Patients p
    LEFT JOIN Billing b ON p.PatientID = b.PatientID
    GROUP BY p.PatientID, p.FirstName, p.LastName, p.PhoneNumber
),
RankedPatients AS (
    SELECT 
        *,
        -- Rank patients by total spending
        RANK() OVER (ORDER BY GrandTotal DESC) AS SpendingRank,
        -- Calculate percentage of total revenue
        CAST(GrandTotal * 100.0 / SUM(GrandTotal) OVER () AS DECIMAL(5,2)) AS PercentageOfRevenue,
        -- Calculate average bill amount
        CASE 
            WHEN TotalBills > 0 THEN CAST(GrandTotal / TotalBills AS DECIMAL(10,2))
            ELSE 0 
        END AS AverageBillAmount
    FROM PatientBilling
    WHERE GrandTotal > 0
)
SELECT 
    PatientName,
    PhoneNumber,
    TotalBills,
    TotalConsultationCharges,
    TotalMedicineCharges,
    TotalLabCharges,
    TotalOtherCharges,
    GrandTotal,
    TotalPaid,
    TotalPending,
    AverageBillAmount,
    SpendingRank,
    PercentageOfRevenue,
    FirstBillDate,
    LastBillDate,
    DATEDIFF(DAY, FirstBillDate, LastBillDate) AS DaysSinceFirstBill
FROM RankedPatients
ORDER BY GrandTotal DESC;
GO

-- =============================================
-- TASK 4: Doctor Specialization Analysis
-- Using CTE and Aggregations
-- =============================================
PRINT '=== TASK 4: Doctor Specialization Analysis ===';
GO

WITH SpecializationStats AS (
    SELECT 
        d.Specialization,
        COUNT(DISTINCT d.DoctorID) AS NumberOfDoctors,
        COUNT(a.AppointmentID) AS TotalAppointments,
        SUM(CASE WHEN a.Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedAppointments,
        SUM(CASE WHEN a.Status = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledAppointments,
        SUM(CASE WHEN a.Status = 'Scheduled' THEN 1 ELSE 0 END) AS ScheduledAppointments,
        AVG(d.ConsultationFee) AS AvgConsultationFee,
        SUM(b.TotalAmount) AS TotalRevenue,
        AVG(d.ExperienceYears) AS AvgExperience
    FROM Doctors d
    LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
    LEFT JOIN Billing b ON a.AppointmentID = b.AppointmentID
    GROUP BY d.Specialization
),
DoctorPerformance AS (
    SELECT 
        d.DoctorID,
        CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
        d.Specialization,
        d.ExperienceYears,
        d.ConsultationFee,
        COUNT(a.AppointmentID) AS AppointmentsHandled,
        SUM(b.TotalAmount) AS RevenueGenerated,
        -- Calculate completion rate
        CAST(SUM(CASE WHEN a.Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / 
            NULLIF(COUNT(a.AppointmentID), 0) AS DECIMAL(5,2)) AS CompletionRate
    FROM Doctors d
    LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
    LEFT JOIN Billing b ON a.AppointmentID = b.AppointmentID
    GROUP BY d.DoctorID, d.FirstName, d.LastName, d.Specialization, d.ExperienceYears, d.ConsultationFee
)
SELECT 
    s.Specialization,
    s.NumberOfDoctors,
    s.TotalAppointments,
    s.CompletedAppointments,
    s.CancelledAppointments,
    s.ScheduledAppointments,
    CAST(s.AvgConsultationFee AS DECIMAL(10,2)) AS AvgConsultationFee,
    ISNULL(s.TotalRevenue, 0) AS TotalRevenue,
    CAST(s.AvgExperience AS DECIMAL(5,2)) AS AvgExperienceYears,
    -- Calculate completion percentage
    CASE 
        WHEN s.TotalAppointments > 0 
        THEN CAST(s.CompletedAppointments * 100.0 / s.TotalAppointments AS DECIMAL(5,2))
        ELSE 0 
    END AS CompletionPercentage,
    -- Rank by revenue
    RANK() OVER (ORDER BY s.TotalRevenue DESC) AS RevenueRank
FROM SpecializationStats s
ORDER BY TotalRevenue DESC;
GO

-- Show detailed doctor performance
PRINT '=== Detailed Doctor Performance by Specialization ===';
GO

WITH DoctorPerformance AS (
    SELECT 
        d.DoctorID,
        CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
        d.Specialization,
        d.ExperienceYears,
        d.ConsultationFee,
        COUNT(a.AppointmentID) AS AppointmentsHandled,
        SUM(b.TotalAmount) AS RevenueGenerated,
        CAST(SUM(CASE WHEN a.Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / 
            NULLIF(COUNT(a.AppointmentID), 0) AS DECIMAL(5,2)) AS CompletionRate
    FROM Doctors d
    LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
    LEFT JOIN Billing b ON a.AppointmentID = b.AppointmentID
    GROUP BY d.DoctorID, d.FirstName, d.LastName, d.Specialization, d.ExperienceYears, d.ConsultationFee
)
SELECT 
    DoctorName,
    Specialization,
    ExperienceYears,
    ConsultationFee,
    AppointmentsHandled,
    ISNULL(RevenueGenerated, 0) AS RevenueGenerated,
    CompletionRate,
    RANK() OVER (PARTITION BY Specialization ORDER BY RevenueGenerated DESC) AS RankInSpecialization
FROM DoctorPerformance
ORDER BY Specialization, RevenueGenerated DESC;
GO

-- =============================================
-- VIEWS CREATION
-- =============================================

-- =============================================
-- VIEW 1: Today's Appointment Schedule
-- =============================================
IF OBJECT_ID('vw_TodaysSchedule', 'V') IS NOT NULL DROP VIEW vw_TodaysSchedule;
GO

CREATE VIEW vw_TodaysSchedule AS
SELECT 
    a.AppointmentID,
    a.AppointmentTime,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    p.PhoneNumber AS PatientPhone,
    CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
    d.Specialization,
    a.ReasonForVisit,
    a.Status,
    DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS PatientAge
FROM Appointments a
INNER JOIN Patients p ON a.PatientID = p.PatientID
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
WHERE a.AppointmentDate = CAST(GETDATE() AS DATE);
GO

-- =============================================
-- VIEW 2: Patient Summary
-- =============================================
IF OBJECT_ID('vw_PatientSummary', 'V') IS NOT NULL DROP VIEW vw_PatientSummary;
GO

CREATE VIEW vw_PatientSummary AS
SELECT 
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    p.Gender,
    DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
    p.BloodGroup,
    p.PhoneNumber,
    p.Email,
    COUNT(DISTINCT a.AppointmentID) AS TotalVisits,
    MAX(a.AppointmentDate) AS LastVisitDate,
    SUM(ISNULL(b.TotalAmount, 0)) AS TotalAmountSpent,
    SUM(CASE WHEN b.PaymentStatus = 'Pending' THEN b.TotalAmount ELSE 0 END) AS PendingAmount
FROM Patients p
LEFT JOIN Appointments a ON p.PatientID = a.PatientID
LEFT JOIN Billing b ON p.PatientID = b.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName, p.Gender, p.DateOfBirth, 
         p.BloodGroup, p.PhoneNumber, p.Email;
GO

-- =============================================
-- VIEW 3: Doctor Workload
-- =============================================
IF OBJECT_ID('vw_DoctorWorkload', 'V') IS NOT NULL DROP VIEW vw_DoctorWorkload;
GO

CREATE VIEW vw_DoctorWorkload AS
SELECT 
    d.DoctorID,
    CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
    d.Specialization,
    d.ExperienceYears,
    COUNT(a.AppointmentID) AS TotalAppointments,
    SUM(CASE WHEN a.Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedAppointments,
    SUM(CASE WHEN a.Status = 'Scheduled' THEN 1 ELSE 0 END) AS UpcomingAppointments,
    SUM(CASE WHEN a.AppointmentDate = CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS TodaysAppointments,
    SUM(ISNULL(b.TotalAmount, 0)) AS TotalRevenueGenerated
FROM Doctors d
LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
LEFT JOIN Billing b ON a.AppointmentID = b.AppointmentID
GROUP BY d.DoctorID, d.FirstName, d.LastName, d.Specialization, d.ExperienceYears;
GO

-- =============================================
-- VIEW 4: Billing Overview
-- =============================================
IF OBJECT_ID('vw_BillingOverview', 'V') IS NOT NULL DROP VIEW vw_BillingOverview;
GO

CREATE VIEW vw_BillingOverview AS
SELECT 
    b.BillID,
    b.BillDate,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
    d.Specialization,
    b.ConsultationCharges,
    b.MedicineCharges,
    b.LabCharges,
    b.OtherCharges,
    b.TotalAmount,
    b.PaymentStatus,
    b.PaymentDate,
    CASE 
        WHEN b.PaymentStatus = 'Pending' THEN DATEDIFF(DAY, b.BillDate, GETDATE())
        ELSE NULL 
    END AS DaysPending
FROM Billing b
INNER JOIN Patients p ON b.PatientID = p.PatientID
INNER JOIN Appointments a ON b.AppointmentID = a.AppointmentID
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID;
GO

-- =============================================
-- VIEW 5: Patient Visit History
-- =============================================
IF OBJECT_ID('vw_PatientVisitHistory', 'V') IS NOT NULL DROP VIEW vw_PatientVisitHistory;
GO

CREATE VIEW vw_PatientVisitHistory AS
SELECT 
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    a.AppointmentDate,
    a.AppointmentTime,
    CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
    d.Specialization,
    a.ReasonForVisit,
    a.Status,
    diag.DiagnosisDetails,
    diag.Prescription,
    b.TotalAmount,
    b.PaymentStatus
FROM Patients p
INNER JOIN Appointments a ON p.PatientID = a.PatientID
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
LEFT JOIN Diagnosis diag ON a.AppointmentID = diag.AppointmentID
LEFT JOIN Billing b ON a.AppointmentID = b.AppointmentID;
GO

-- =============================================
-- DEMONSTRATE VIEWS USAGE
-- =============================================

PRINT '=== VIEW 1: Today''s Schedule ===';
SELECT * FROM vw_TodaysSchedule ORDER BY AppointmentTime;
GO

PRINT '=== VIEW 2: Patient Summary ===';
SELECT * FROM vw_PatientSummary ORDER BY TotalAmountSpent DESC;
GO

PRINT '=== VIEW 3: Doctor Workload ===';
SELECT * FROM vw_DoctorWorkload ORDER BY TotalRevenueGenerated DESC;
GO

PRINT '=== VIEW 4: Billing Overview (Pending Payments) ===';
SELECT * FROM vw_BillingOverview WHERE PaymentStatus = 'Pending' ORDER BY DaysPending DESC;
GO

PRINT '=== VIEW 5: Patient Visit History Sample ===';
SELECT TOP 10 * FROM vw_PatientVisitHistory ORDER BY AppointmentDate DESC;
GO

-- =============================================
-- ADDITIONAL ADVANCED QUERIES
-- =============================================

-- =============================================
-- BONUS QUERY 1: Monthly Revenue Trend
-- =============================================
PRINT '=== BONUS: Monthly Revenue Trend ===';
GO

WITH MonthlyRevenue AS (
    SELECT 
        YEAR(BillDate) AS Year,
        MONTH(BillDate) AS Month,
        DATENAME(MONTH, BillDate) AS MonthName,
        COUNT(BillID) AS TotalBills,
        SUM(TotalAmount) AS MonthlyRevenue,
        SUM(CASE WHEN PaymentStatus = 'Paid' THEN TotalAmount ELSE 0 END) AS PaidAmount,
        SUM(CASE WHEN PaymentStatus = 'Pending' THEN TotalAmount ELSE 0 END) AS PendingAmount
    FROM Billing
    GROUP BY YEAR(BillDate), MONTH(BillDate), DATENAME(MONTH, BillDate)
)
SELECT 
    Year,
    Month,
    MonthName,
    TotalBills,
    MonthlyRevenue,
    PaidAmount,
    PendingAmount,
    LAG(MonthlyRevenue) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue,
    CASE 
        WHEN LAG(MonthlyRevenue) OVER (ORDER BY Year, Month) IS NOT NULL
        THEN CAST((MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY Year, Month)) * 100.0 / 
             LAG(MonthlyRevenue) OVER (ORDER BY Year, Month) AS DECIMAL(10,2))
        ELSE NULL
    END AS GrowthPercentage
FROM MonthlyRevenue
ORDER BY Year, Month;
GO

-- =============================================
-- BONUS QUERY 2: Peak Hours Analysis
-- =============================================
PRINT '=== BONUS: Peak Appointment Hours ===';
GO

SELECT 
    DATEPART(HOUR, AppointmentTime) AS AppointmentHour,
    COUNT(*) AS TotalAppointments,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedAppointments,
    SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledAppointments,
    CAST(AVG(CAST(AppointmentTime AS FLOAT)) AS TIME) AS AvgAppointmentTime
FROM Appointments
GROUP BY DATEPART(HOUR, AppointmentTime)
ORDER BY TotalAppointments DESC;
GO

PRINT '=== Hospital Management System Setup Complete ===';
PRINT 'Database: HospitalManagementDB';
PRINT 'Tables Created: 5 (Patients, Doctors, Appointments, Diagnosis, Billing)';
PRINT 'Views Created: 5';
PRINT 'Sample Data Inserted Successfully';
PRINT 'All SQL Tasks Executed Successfully';
GO