-- =============================================
-- Employee Payroll Management System - COMPLETE
-- Salary + Allowances + Tax Calculation
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PayrollManagementDB')
BEGIN
    CREATE DATABASE PayrollManagementDB;
END
GO

USE PayrollManagementDB;
GO

-- =============================================
-- DROP EXISTING OBJECTS (IF ANY)
-- =============================================

-- Drop stored procedures
IF OBJECT_ID('sp_CalculateMonthlySalary', 'P') IS NOT NULL DROP PROCEDURE sp_CalculateMonthlySalary;
IF OBJECT_ID('sp_GeneratePayslip', 'P') IS NOT NULL DROP PROCEDURE sp_GeneratePayslip;
IF OBJECT_ID('sp_ProcessMonthlyPayroll', 'P') IS NOT NULL DROP PROCEDURE sp_ProcessMonthlyPayroll;
IF OBJECT_ID('sp_GetEmployeePerformance', 'P') IS NOT NULL DROP PROCEDURE sp_GetEmployeePerformance;
GO

-- Drop views
IF OBJECT_ID('vw_EmployeeSalaryDetails', 'V') IS NOT NULL DROP VIEW vw_EmployeeSalaryDetails;
IF OBJECT_ID('vw_AttendanceReport', 'V') IS NOT NULL DROP VIEW vw_AttendanceReport;
IF OBJECT_ID('vw_LowPerformingEmployees', 'V') IS NOT NULL DROP VIEW vw_LowPerformingEmployees;
IF OBJECT_ID('vw_MonthlySalarySummary', 'V') IS NOT NULL DROP VIEW vw_MonthlySalarySummary;
GO

-- Drop tables
IF OBJECT_ID('Payslips', 'U') IS NOT NULL DROP TABLE Payslips;
IF OBJECT_ID('Attendance', 'U') IS NOT NULL DROP TABLE Attendance;
IF OBJECT_ID('Salary', 'U') IS NOT NULL DROP TABLE Salary;
IF OBJECT_ID('TaxSlab', 'U') IS NOT NULL DROP TABLE TaxSlab;
IF OBJECT_ID('Employees', 'U') IS NOT NULL DROP TABLE Employees;
IF OBJECT_ID('Departments', 'U') IS NOT NULL DROP TABLE Departments;
GO

-- =============================================
-- CREATE TABLES
-- =============================================

CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100) NOT NULL UNIQUE,
    DepartmentHead NVARCHAR(100),
    Location NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1001,1),
    EmployeeCode NVARCHAR(20) UNIQUE NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    PhoneNumber NVARCHAR(15),
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID),
    Designation NVARCHAR(100),
    DateOfJoining DATE NOT NULL,
    DateOfBirth DATE,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F', 'O')),
    Address NVARCHAR(255),
    BankAccountNumber NVARCHAR(20),
    PANNumber NVARCHAR(10),
    Status NVARCHAR(20) CHECK (Status IN ('Active', 'Inactive', 'On Leave', 'Terminated')) DEFAULT 'Active',
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Salary (
    SalaryID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT FOREIGN KEY REFERENCES Employees(EmployeeID),
    BasicSalary DECIMAL(12,2) NOT NULL CHECK (BasicSalary >= 0),
    HRA DECIMAL(12,2) DEFAULT 0,
    DA DECIMAL(12,2) DEFAULT 0,
    TA DECIMAL(12,2) DEFAULT 0,
    MedicalAllowance DECIMAL(12,2) DEFAULT 0,
    SpecialAllowance DECIMAL(12,2) DEFAULT 0,
    ProvidentFund DECIMAL(12,2) DEFAULT 0,
    ProfessionalTax DECIMAL(12,2) DEFAULT 200,
    EffectiveFrom DATE NOT NULL,
    EffectiveTo DATE,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE TaxSlab (
    TaxSlabID INT PRIMARY KEY IDENTITY(1,1),
    MinIncome DECIMAL(12,2) NOT NULL,
    MaxIncome DECIMAL(12,2),
    TaxRate DECIMAL(5,2) NOT NULL,
    Description NVARCHAR(255),
    FinancialYear NVARCHAR(10),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Attendance (
    AttendanceID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT FOREIGN KEY REFERENCES Employees(EmployeeID),
    AttendanceDate DATE NOT NULL,
    CheckInTime TIME,
    CheckOutTime TIME,
    Status NVARCHAR(20) CHECK (Status IN ('Present', 'Absent', 'Half-Day', 'Leave', 'Holiday', 'Week-Off')) DEFAULT 'Present',
    WorkingHours AS (
        CASE 
            WHEN CheckInTime IS NOT NULL AND CheckOutTime IS NOT NULL 
            THEN DATEDIFF(MINUTE, CheckInTime, CheckOutTime) / 60.0
            ELSE 0
        END
    ) PERSISTED,
    Remarks NVARCHAR(255),
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_EmployeeDate UNIQUE (EmployeeID, AttendanceDate)
);
GO

CREATE TABLE Payslips (
    PayslipID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT FOREIGN KEY REFERENCES Employees(EmployeeID),
    PayslipNumber NVARCHAR(30) UNIQUE NOT NULL,
    PayrollMonth INT NOT NULL CHECK (PayrollMonth BETWEEN 1 AND 12),
    PayrollYear INT NOT NULL CHECK (PayrollYear >= 2000),
    WorkingDays INT NOT NULL,
    PresentDays DECIMAL(5,2) NOT NULL,
    AbsentDays DECIMAL(5,2) NOT NULL,
    LeaveDays DECIMAL(5,2) DEFAULT 0,
    BasicSalary DECIMAL(12,2) NOT NULL,
    HRA DECIMAL(12,2) DEFAULT 0,
    DA DECIMAL(12,2) DEFAULT 0,
    TA DECIMAL(12,2) DEFAULT 0,
    MedicalAllowance DECIMAL(12,2) DEFAULT 0,
    SpecialAllowance DECIMAL(12,2) DEFAULT 0,
    GrossSalary DECIMAL(12,2) NOT NULL,
    ProvidentFund DECIMAL(12,2) DEFAULT 0,
    ProfessionalTax DECIMAL(12,2) DEFAULT 0,
    IncomeTax DECIMAL(12,2) DEFAULT 0,
    AbsentDeduction DECIMAL(12,2) DEFAULT 0,
    TotalDeductions DECIMAL(12,2) NOT NULL,
    NetSalary DECIMAL(12,2) NOT NULL,
    PaymentDate DATE,
    PaymentStatus NVARCHAR(20) CHECK (PaymentStatus IN ('Pending', 'Processed', 'Paid', 'On Hold')) DEFAULT 'Pending',
    GeneratedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_EmployeePayroll UNIQUE (EmployeeID, PayrollMonth, PayrollYear)
);
GO

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

INSERT INTO Departments (DepartmentName, DepartmentHead, Location)
VALUES 
    ('IT & Development', 'Rajendra Saha', 'Bangalore'),
    ('Human Resources', 'Priya Sharma', 'Mumbai'),
    ('Finance & Accounts', 'Amit Patel', 'Delhi'),
    ('Sales & Marketing', 'Sneha Reddy', 'Pune'),
    ('Operations', 'Vikram Singh', 'Chennai');
GO

INSERT INTO Employees (EmployeeCode, FirstName, LastName, Email, PhoneNumber, DepartmentID, Designation, DateOfJoining, DateOfBirth, Gender, BankAccountNumber, PANNumber, Status)
VALUES 
    ('EMP001', 'Rajendra', 'Saha', 'rajendra.saha@company.com', '9876543210', 1, 'Senior Developer', '2022-01-15', '1990-05-20', 'M', 'BANK12345001', 'ABCDE1234F', 'Active'),
    ('EMP002', 'Anita', 'Verma', 'anita.verma@company.com', '9876543211', 1, 'Software Engineer', '2023-03-10', '1995-08-15', 'F', 'BANK12345002', 'BCDEF2345G', 'Active'),
    ('EMP003', 'Rahul', 'Kumar', 'rahul.kumar@company.com', '9876543212', 2, 'HR Manager', '2021-06-01', '1988-12-10', 'M', 'BANK12345003', 'CDEFG3456H', 'Active'),
    ('EMP004', 'Priya', 'Nair', 'priya.nair@company.com', '9876543213', 3, 'Senior Accountant', '2022-09-20', '1992-03-25', 'F', 'BANK12345004', 'DEFGH4567I', 'Active'),
    ('EMP005', 'Suresh', 'Reddy', 'suresh.reddy@company.com', '9876543214', 4, 'Sales Executive', '2023-01-05', '1993-07-18', 'M', 'BANK12345005', 'EFGHI5678J', 'Active'),
    ('EMP006', 'Kavita', 'Desai', 'kavita.desai@company.com', '9876543215', 1, 'Junior Developer', '2024-02-15', '1997-11-30', 'F', 'BANK12345006', 'FGHIJ6789K', 'Active'),
    ('EMP007', 'Amit', 'Sharma', 'amit.sharma@company.com', '9876543216', 5, 'Operations Manager', '2020-04-10', '1985-09-05', 'M', 'BANK12345007', 'GHIJK7890L', 'Active'),
    ('EMP008', 'Deepa', 'Joshi', 'deepa.joshi@company.com', '9876543217', 2, 'HR Executive', '2023-08-22', '1996-01-14', 'F', 'BANK12345008', 'HIJKL8901M', 'Active'),
    ('EMP009', 'Ravi', 'Patel', 'ravi.patel@company.com', '9876543218', 4, 'Marketing Head', '2021-11-30', '1987-04-08', 'M', 'BANK12345009', 'IJKLM9012N', 'Active'),
    ('EMP010', 'Neha', 'Singh', 'neha.singh@company.com', '9876543219', 3, 'Junior Accountant', '2024-05-01', '1998-06-22', 'F', 'BANK12345010', 'JKLMN0123O', 'Active');
GO

INSERT INTO Salary (EmployeeID, BasicSalary, HRA, DA, TA, MedicalAllowance, SpecialAllowance, ProvidentFund, ProfessionalTax, EffectiveFrom, IsActive)
VALUES 
    (1001, 60000, 18000, 6000, 3000, 2000, 5000, 7200, 200, '2024-01-01', 1),
    (1002, 45000, 13500, 4500, 2000, 1500, 3500, 5400, 200, '2024-01-01', 1),
    (1003, 55000, 16500, 5500, 2500, 2000, 4500, 6600, 200, '2024-01-01', 1),
    (1004, 50000, 15000, 5000, 2500, 1500, 4000, 6000, 200, '2024-01-01', 1),
    (1005, 40000, 12000, 4000, 2000, 1500, 3000, 4800, 200, '2024-01-01', 1),
    (1006, 35000, 10500, 3500, 1500, 1000, 2500, 4200, 200, '2024-01-01', 1),
    (1007, 65000, 19500, 6500, 3000, 2500, 5500, 7800, 200, '2024-01-01', 1),
    (1008, 38000, 11400, 3800, 1800, 1200, 2800, 4560, 200, '2024-01-01', 1),
    (1009, 58000, 17400, 5800, 2800, 2000, 5000, 6960, 200, '2024-01-01', 1),
    (1010, 32000, 9600, 3200, 1500, 1000, 2200, 3840, 200, '2024-01-01', 1);
GO

INSERT INTO TaxSlab (MinIncome, MaxIncome, TaxRate, Description, FinancialYear, IsActive)
VALUES 
    (0, 300000, 0, 'No tax up to 3 lakhs', '2024-25', 1),
    (300001, 600000, 5, '5% tax on 3-6 lakhs', '2024-25', 1),
    (600001, 900000, 10, '10% tax on 6-9 lakhs', '2024-25', 1),
    (900001, 1200000, 15, '15% tax on 9-12 lakhs', '2024-25', 1),
    (1200001, 1500000, 20, '20% tax on 12-15 lakhs', '2024-25', 1),
    (1500001, NULL, 30, '30% tax above 15 lakhs', '2024-25', 1);
GO

-- =============================================
-- INSERT ATTENDANCE DATA (Nov 2025)
-- =============================================

DECLARE @StartDate DATE = '2025-11-01';
DECLARE @EndDate DATE = '2025-11-20';
DECLARE @CurrentDate DATE = @StartDate;
DECLARE @EmpID INT;

WHILE @CurrentDate <= @EndDate
BEGIN
    IF DATEPART(WEEKDAY, @CurrentDate) != 1  -- Skip Sundays
    BEGIN
        -- Employee 1001 - Excellent (100%)
        INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
        VALUES (1001, @CurrentDate, '09:00', '18:00', 'Present');
        
        -- Employee 1002 - Good (2 leaves)
        IF @CurrentDate NOT IN ('2025-11-05', '2025-11-15')
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1002, @CurrentDate, '09:15', '18:15', 'Present');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, Status, Remarks)
            VALUES (1002, @CurrentDate, 'Leave', 'Planned Leave');
        
        -- Employee 1003 - Average (3 absents)
        IF @CurrentDate NOT IN ('2025-11-08', '2025-11-12', '2025-11-18')
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1003, @CurrentDate, '09:30', '18:30', 'Present');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, Status)
            VALUES (1003, @CurrentDate, 'Absent');
        
        -- Employee 1004 - Good (1 half-day)
        IF @CurrentDate = '2025-11-10'
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1004, @CurrentDate, '09:00', '13:00', 'Half-Day');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1004, @CurrentDate, '09:00', '18:00', 'Present');
        
        -- Employee 1005 - POOR (5 absents, 2 half-days) - LOW PERFORMER
        IF @CurrentDate IN ('2025-11-04', '2025-11-06', '2025-11-11', '2025-11-13', '2025-11-19')
            INSERT INTO Attendance (EmployeeID, AttendanceDate, Status)
            VALUES (1005, @CurrentDate, 'Absent');
        ELSE IF @CurrentDate IN ('2025-11-07', '2025-11-14')
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1005, @CurrentDate, '09:00', '13:00', 'Half-Day');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1005, @CurrentDate, '10:00', '17:00', 'Present');
        
        -- Employee 1006 - Good (1 leave)
        IF @CurrentDate = '2025-11-16'
            INSERT INTO Attendance (EmployeeID, AttendanceDate, Status, Remarks)
            VALUES (1006, @CurrentDate, 'Leave', 'Sick Leave');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1006, @CurrentDate, '09:00', '18:00', 'Present');
        
        -- Employee 1007 - Excellent (100%)
        INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
        VALUES (1007, @CurrentDate, '08:45', '18:30', 'Present');
        
        -- Employee 1008 - POOR (6 absents) - LOW PERFORMER
        IF @CurrentDate IN ('2025-11-05', '2025-11-09', '2025-11-12', '2025-11-15', '2025-11-19', '2025-11-20')
            INSERT INTO Attendance (EmployeeID, AttendanceDate, Status)
            VALUES (1008, @CurrentDate, 'Absent');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1008, @CurrentDate, '10:30', '17:30', 'Present');
        
        -- Employee 1009 - Good (2 leaves)
        IF @CurrentDate IN ('2025-11-11', '2025-11-18')
            INSERT INTO Attendance (EmployeeID, AttendanceDate, Status, Remarks)
            VALUES (1009, @CurrentDate, 'Leave', 'Personal Work');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1009, @CurrentDate, '09:15', '18:15', 'Present');
        
        -- Employee 1010 - Good (1 half-day)
        IF @CurrentDate = '2025-11-14'
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1010, @CurrentDate, '09:00', '14:00', 'Half-Day');
        ELSE
            INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckInTime, CheckOutTime, Status)
            VALUES (1010, @CurrentDate, '09:00', '18:00', 'Present');
    END
    
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END
GO

-- =============================================
-- STORED PROCEDURE 1: Calculate Monthly Salary
-- =============================================
CREATE PROCEDURE sp_CalculateMonthlySalary
    @EmployeeID INT,
    @Month INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calculate working days
    DECLARE @WorkingDays INT = (
        SELECT COUNT(*)
        FROM (
            SELECT DATEADD(DAY, number, DATEFROMPARTS(@Year, @Month, 1)) AS CalendarDate
            FROM master..spt_values
            WHERE type = 'P'
              AND DATEADD(DAY, number, DATEFROMPARTS(@Year, @Month, 1)) < DATEADD(MONTH, 1, DATEFROMPARTS(@Year, @Month, 1))
        ) AS AllDays
        WHERE DATEPART(WEEKDAY, CalendarDate) != 1
    );
    
    -- Get salary and attendance using CTE
    WITH SalaryData AS (
        SELECT 
            BasicSalary, HRA, DA, TA, MedicalAllowance, SpecialAllowance,
            ProvidentFund, ProfessionalTax,
            (BasicSalary + HRA + DA + TA + MedicalAllowance + SpecialAllowance) AS GrossSalary
        FROM Salary
        WHERE EmployeeID = @EmployeeID AND IsActive = 1
    ),
    AttendanceData AS (
        SELECT 
            SUM(CASE 
                WHEN Status = 'Present' THEN 1
                WHEN Status = 'Half-Day' THEN 0.5
                WHEN Status = 'Leave' THEN 1
                ELSE 0
            END) AS PresentDays,
            SUM(CASE WHEN Status = 'Absent' THEN 1 ELSE 0 END) AS AbsentDays,
            SUM(CASE WHEN Status = 'Leave' THEN 1 ELSE 0 END) AS LeaveDays
        FROM Attendance
        WHERE EmployeeID = @EmployeeID
          AND YEAR(AttendanceDate) = @Year
          AND MONTH(AttendanceDate) = @Month
    )
    SELECT 
        @EmployeeID AS EmployeeID,
        @Month AS PayrollMonth,
        @Year AS PayrollYear,
        @WorkingDays AS WorkingDays,
        ISNULL(a.PresentDays, 0) AS PresentDays,
        ISNULL(a.AbsentDays, 0) AS AbsentDays,
        ISNULL(a.LeaveDays, 0) AS LeaveDays,
        s.BasicSalary,
        s.HRA,
        s.DA,
        s.TA,
        s.MedicalAllowance,
        s.SpecialAllowance,
        s.GrossSalary,
        s.GrossSalary * 12 AS AnnualGross,
        s.ProvidentFund,
        s.ProfessionalTax,
        
        -- Tax calculation using subquery and CASE WHEN
        (SELECT SUM(
            CASE 
                WHEN s.GrossSalary * 12 > MinIncome THEN
                    (CASE 
                        WHEN MaxIncome IS NULL THEN (s.GrossSalary * 12 - MinIncome)
                        WHEN s.GrossSalary * 12 > MaxIncome THEN (MaxIncome - MinIncome)
                        ELSE (s.GrossSalary * 12 - MinIncome)
                    END) * (TaxRate / 100.0)
                ELSE 0
            END
        ) / 12.0 FROM TaxSlab WHERE IsActive = 1) AS IncomeTax,
        
        -- Absent deduction
        CASE 
            WHEN @WorkingDays > 0 THEN (s.GrossSalary / @WorkingDays) * ISNULL(a.AbsentDays, 0)
            ELSE 0
        END AS AbsentDeduction,
        
        -- Total deductions
        s.ProvidentFund + s.ProfessionalTax + 
        (SELECT SUM(
            CASE 
                WHEN s.GrossSalary * 12 > MinIncome THEN
                    (CASE 
                        WHEN MaxIncome IS NULL THEN (s.GrossSalary * 12 - MinIncome)
                        WHEN s.GrossSalary * 12 > MaxIncome THEN (MaxIncome - MinIncome)
                        ELSE (s.GrossSalary * 12 - MinIncome)
                    END) * (TaxRate / 100.0)
                ELSE 0
            END
        ) / 12.0 FROM TaxSlab WHERE IsActive = 1) +
        CASE 
            WHEN @WorkingDays > 0 THEN (s.GrossSalary / @WorkingDays) * ISNULL(a.AbsentDays, 0)
            ELSE 0
        END AS TotalDeductions,
        
        -- Net salary
        s.GrossSalary - 
        CASE 
            WHEN @WorkingDays > 0 THEN (s.GrossSalary / @WorkingDays) * ISNULL(a.AbsentDays, 0)
            ELSE 0
        END - s.ProvidentFund - s.ProfessionalTax -
        (SELECT SUM(
            CASE 
                WHEN s.GrossSalary * 12 > MinIncome THEN
                    (CASE 
                        WHEN MaxIncome IS NULL THEN (s.GrossSalary * 12 - MinIncome)
                        WHEN s.GrossSalary * 12 > MaxIncome THEN (MaxIncome - MinIncome)
                        ELSE (s.GrossSalary * 12 - MinIncome)
                    END) * (TaxRate / 100.0)
                ELSE 0
            END
        ) / 12.0 FROM TaxSlab WHERE IsActive = 1) AS NetSalary,
        
        -- Attendance percentage
        CAST((ISNULL(a.PresentDays, 0) * 100.0 / @WorkingDays) AS DECIMAL(5,2)) AS AttendancePercentage
    FROM SalaryData s
    CROSS JOIN AttendanceData a;
END
GO

-- =============================================
-- STORED PROCEDURE 2: Generate Payslip
-- =============================================
CREATE PROCEDURE sp_GeneratePayslip
    @EmployeeID INT,
    @Month INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF EXISTS (SELECT 1 FROM Payslips WHERE EmployeeID = @EmployeeID AND PayrollMonth = @Month AND PayrollYear = @Year)
        BEGIN
            RAISERROR('Payslip already exists', 16, 1);
            RETURN;
        END
        
        CREATE TABLE #SalaryCalc (
            EmployeeID INT, PayrollMonth INT, PayrollYear INT, WorkingDays INT,
            PresentDays DECIMAL(5,2), AbsentDays DECIMAL(5,2), LeaveDays DECIMAL(5,2),
            BasicSalary DECIMAL(12,2), HRA DECIMAL(12,2), DA DECIMAL(12,2), 
            TA DECIMAL(12,2), MedicalAllowance DECIMAL(12,2), SpecialAllowance DECIMAL(12,2),
            GrossSalary DECIMAL(12,2), ProvidentFund DECIMAL(12,2), ProfessionalTax DECIMAL(12,2),
            IncomeTax DECIMAL(12,2), AbsentDeduction DECIMAL(12,2), TotalDeductions DECIMAL(12,2),
            NetSalary DECIMAL(12,2)
        );
        
        INSERT INTO #SalaryCalc
        EXEC sp_CalculateMonthlySalary @EmployeeID, @Month, @Year;
        
        DECLARE @PayslipNumber NVARCHAR(30) = 'PAY' + CAST(@Year AS NVARCHAR(4)) + 
                                               RIGHT('0' + CAST(@Month AS NVARCHAR(2)), 2) + 
                                               RIGHT('0000' + CAST(@EmployeeID AS NVARCHAR(10)), 4);
        
        INSERT INTO Payslips (
            EmployeeID, PayslipNumber, PayrollMonth, PayrollYear, WorkingDays, PresentDays, AbsentDays, LeaveDays,
            BasicSalary, HRA, DA, TA, MedicalAllowance, SpecialAllowance, GrossSalary,
            ProvidentFund, ProfessionalTax, IncomeTax, AbsentDeduction, TotalDeductions, NetSalary, PaymentStatus
        )
        SELECT 
            EmployeeID, @PayslipNumber, PayrollMonth, PayrollYear, WorkingDays, PresentDays, AbsentDays, LeaveDays,
            BasicSalary, HRA, DA, TA, MedicalAllowance, SpecialAllowance, GrossSalary,
            ProvidentFund, ProfessionalTax, IncomeTax, AbsentDeduction, TotalDeductions, NetSalary, 'Pending'
        FROM #SalaryCalc;
        
        DROP TABLE #SalaryCalc;
        COMMIT TRANSACTION;
        
        -- Display payslip with Window Functions
        WITH PayslipDetails AS (
            SELECT 
                p.*, e.EmployeeCode, e.FirstName + ' ' + e.LastName AS EmployeeName,
                e.Designation, d.DepartmentName, e.BankAccountNumber, e.PANNumber,
                RANK() OVER (PARTITION BY p.PayrollMonth, p.PayrollYear ORDER BY p.NetSalary DESC) AS SalaryRank
            FROM Payslips p
            INNER JOIN Employees e ON p.EmployeeID = e.EmployeeID
            LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
            WHERE p.PayslipNumber = @PayslipNumber
        )
        SELECT * FROM PayslipDetails;
        
        PRINT 'Payslip generated: ' + @PayslipNumber;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- =============================================
-- STORED PROCEDURE 3: Process Monthly Payroll
-- =============================================
CREATE PROCEDURE sp_ProcessMonthlyPayroll
    @Month INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @EmployeeID INT, @ProcessedCount INT = 0;
        
        DECLARE emp_cursor CURSOR FOR
        SELECT EmployeeID FROM Employees WHERE Status = 'Active';
        
        OPEN emp_cursor;
        FETCH NEXT FROM emp_cursor INTO @EmployeeID;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                EXEC sp_GeneratePayslip @EmployeeID, @Month, @Year;
                SET @ProcessedCount = @ProcessedCount + 1;
            END TRY
            BEGIN CATCH
                PRINT 'Failed for Employee: ' + CAST(@EmployeeID AS NVARCHAR(10));
            END CATCH
            
            FETCH NEXT FROM emp_cursor INTO @EmployeeID;
        END
        
        CLOSE emp_cursor;
        DEALLOCATE emp_cursor;
        
        COMMIT TRANSACTION;
        
        SELECT 
            @Month AS PayrollMonth,
            @Year AS PayrollYear,
            @ProcessedCount AS EmployeesProcessed,
            SUM(NetSalary) AS TotalPayroll
        FROM Payslips
        WHERE PayrollMonth = @Month AND PayrollYear = @Year;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF CURSOR_STATUS('global', 'emp_cursor') >= 0
        BEGIN
            CLOSE emp_cursor;
            DEALLOCATE emp_cursor;
        END
        THROW;
    END CATCH
END
GO

-- =============================================
-- STORED PROCEDURE 4: Employee Performance
-- =============================================
CREATE PROCEDURE sp_GetEmployeePerformance
    @Month INT = NULL,
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Month IS NULL SET @Month = 11;
    IF @Year IS NULL SET @Year = 2025;
    
    WITH AttendanceStats AS (
        SELECT 
            e.EmployeeID, e.EmployeeCode,
            e.FirstName + ' ' + e.LastName AS EmployeeName,
            e.Designation, d.DepartmentName,
            COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END) AS WorkingDays,
            SUM(CASE 
                WHEN a.Status = 'Present' THEN 1
                WHEN a.Status = 'Half-Day' THEN 0.5
                WHEN a.Status = 'Leave' THEN 1
                ELSE 0
            END) AS PresentDays,
            SUM(CASE WHEN a.Status = 'Absent' THEN 1 ELSE 0 END) AS AbsentDays
        FROM Employees e
        LEFT JOIN Attendance a ON e.EmployeeID = a.EmployeeID
            AND YEAR(a.AttendanceDate) = @Year
            AND MONTH(a.AttendanceDate) = @Month
        LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
        WHERE e.Status = 'Active'
        GROUP BY e.EmployeeID, e.EmployeeCode, e.FirstName, e.LastName, e.Designation, d.DepartmentName
    )
    SELECT 
        EmployeeCode,
        EmployeeName,
        Designation,
        DepartmentName,
        WorkingDays,
        PresentDays,
        AbsentDays,
        CAST((PresentDays * 100.0 / NULLIF(WorkingDays, 0)) AS DECIMAL(5,2)) AS AttendancePercentage,
        CASE 
            WHEN (PresentDays * 100.0 / NULLIF(WorkingDays, 0)) >= 95 THEN 'Excellent'
            WHEN (PresentDays * 100.0 / NULLIF(WorkingDays, 0)) >= 85 THEN 'Good'
            WHEN (PresentDays * 100.0 / NULLIF(WorkingDays, 0)) >= 75 THEN 'Average'
            WHEN (PresentDays * 100.0 / NULLIF(WorkingDays, 0)) >= 60 THEN 'Below Average'
            ELSE 'Poor'
        END AS Performance,
        RANK() OVER (ORDER BY (PresentDays * 100.0 / NULLIF(WorkingDays, 0)) DESC) AS PerformanceRank,
        CASE 
            WHEN (PresentDays * 100.0 / NULLIF(WorkingDays, 0)) < 75 THEN 'Warning Required'
            WHEN (PresentDays * 100.0 / NULLIF(WorkingDays, 0)) < 85 THEN 'Monitor'
            ELSE 'No Action'
        END AS ActionRequired
    FROM AttendanceStats
    ORDER BY AttendancePercentage ASC;
END
GO

-- =============================================
-- CREATE VIEWS
-- =============================================

CREATE VIEW vw_EmployeeSalaryDetails AS
SELECT 
    e.EmployeeID, e.EmployeeCode,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    e.Designation, d.DepartmentName,
    s.BasicSalary, s.HRA, s.DA, s.TA, s.MedicalAllowance, s.SpecialAllowance,
    (s.BasicSalary + s.HRA + s.DA + s.TA + s.MedicalAllowance + s.SpecialAllowance) AS MonthlyGross,
    (s.BasicSalary + s.HRA + s.DA + s.TA + s.MedicalAllowance + s.SpecialAllowance) * 12 AS AnnualGross,
    s.ProvidentFund, s.ProfessionalTax,
    CASE 
        WHEN (s.BasicSalary + s.HRA + s.DA + s.TA + s.MedicalAllowance + s.SpecialAllowance) * 12 <= 300000 THEN '0%'
        WHEN (s.BasicSalary + s.HRA + s.DA + s.TA + s.MedicalAllowance + s.SpecialAllowance) * 12 <= 600000 THEN '5%'
        WHEN (s.BasicSalary + s.HRA + s.DA + s.TA + s.MedicalAllowance + s.SpecialAllowance) * 12 <= 900000 THEN '10%'
        WHEN (s.BasicSalary + s.HRA + s.DA + s.TA + s.MedicalAllowance + s.SpecialAllowance) * 12 <= 1200000 THEN '15%'
        WHEN (s.BasicSalary + s.HRA + s.DA + s.TA + s.MedicalAllowance + s.SpecialAllowance) * 12 <= 1500000 THEN '20%'
        ELSE '30%'
    END AS TaxSlab
FROM Employees e
INNER JOIN Salary s ON e.EmployeeID = s.EmployeeID AND s.IsActive = 1
LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID;
GO

CREATE VIEW vw_AttendanceReport AS
SELECT 
    e.EmployeeCode, e.FirstName + ' ' + e.LastName AS EmployeeName,
    d.DepartmentName, YEAR(a.AttendanceDate) AS Year, MONTH(a.AttendanceDate) AS Month,
    COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END) AS WorkingDays,
    SUM(CASE WHEN a.Status = 'Present' THEN 1 WHEN a.Status = 'Half-Day' THEN 0.5 WHEN a.Status = 'Leave' THEN 1 ELSE 0 END) AS PresentDays,
    SUM(CASE WHEN a.Status = 'Absent' THEN 1 ELSE 0 END) AS AbsentDays,
    CAST((SUM(CASE WHEN a.Status = 'Present' THEN 1 WHEN a.Status = 'Half-Day' THEN 0.5 WHEN a.Status = 'Leave' THEN 1 ELSE 0 END) * 100.0 / 
    NULLIF(COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END), 0)) AS DECIMAL(5,2)) AS AttendancePercentage
FROM Employees e
LEFT JOIN Attendance a ON e.EmployeeID = a.EmployeeID
LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
GROUP BY e.EmployeeCode, e.FirstName, e.LastName, d.DepartmentName, YEAR(a.AttendanceDate), MONTH(a.AttendanceDate);
GO

CREATE VIEW vw_LowPerformingEmployees AS
SELECT 
    e.EmployeeCode, e.FirstName + ' ' + e.LastName AS EmployeeName,
    e.Email, e.PhoneNumber, e.Designation, d.DepartmentName,
    YEAR(a.AttendanceDate) AS Year, MONTH(a.AttendanceDate) AS Month,
    COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END) AS WorkingDays,
    SUM(CASE WHEN a.Status = 'Present' THEN 1 WHEN a.Status = 'Half-Day' THEN 0.5 WHEN a.Status = 'Leave' THEN 1 ELSE 0 END) AS PresentDays,
    SUM(CASE WHEN a.Status = 'Absent' THEN 1 ELSE 0 END) AS AbsentDays,
    CAST((SUM(CASE WHEN a.Status = 'Present' THEN 1 WHEN a.Status = 'Half-Day' THEN 0.5 WHEN a.Status = 'Leave' THEN 1 ELSE 0 END) * 100.0 / 
    NULLIF(COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END), 0)) AS DECIMAL(5,2)) AS AttendancePercentage,
    CASE 
        WHEN (SUM(CASE WHEN a.Status = 'Present' THEN 1 WHEN a.Status = 'Half-Day' THEN 0.5 WHEN a.Status = 'Leave' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END), 0)) < 50 THEN 'Critical'
        WHEN (SUM(CASE WHEN a.Status = 'Present' THEN 1 WHEN a.Status = 'Half-Day' THEN 0.5 WHEN a.Status = 'Leave' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END), 0)) < 60 THEN 'Severe'
        ELSE 'Medium'
    END AS Severity
FROM Employees e
INNER JOIN Attendance a ON e.EmployeeID = a.EmployeeID
LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.Status = 'Active'
GROUP BY e.EmployeeCode, e.FirstName, e.LastName, e.Email, e.PhoneNumber, e.Designation, d.DepartmentName, YEAR(a.AttendanceDate), MONTH(a.AttendanceDate)
HAVING (SUM(CASE WHEN a.Status = 'Present' THEN 1 WHEN a.Status = 'Half-Day' THEN 0.5 WHEN a.Status = 'Leave' THEN 1 ELSE 0 END) * 100.0 / 
NULLIF(COUNT(CASE WHEN DATEPART(WEEKDAY, a.AttendanceDate) != 1 THEN 1 END), 0)) < 75;
GO

CREATE VIEW vw_MonthlySalarySummary AS
SELECT 
    PayrollMonth, PayrollYear,
    COUNT(*) AS TotalEmployees,
    SUM(GrossSalary) AS TotalGross,
    SUM(TotalDeductions) AS TotalDeductions,
    SUM(NetSalary) AS TotalNetSalary,
    AVG(CAST((PresentDays * 100.0 / WorkingDays) AS DECIMAL(5,2))) AS AvgAttendance
FROM Payslips
GROUP BY PayrollMonth, PayrollYear;
GO

-- =============================================
-- DEMONSTRATIONS
-- =============================================

PRINT '=== DEMO 1: Employee Salary Details ===';
SELECT TOP 5 * FROM vw_EmployeeSalaryDetails ORDER BY AnnualGross DESC;
GO

PRINT '=== DEMO 2: Attendance Report (Nov 2025) ===';
SELECT * FROM vw_AttendanceReport WHERE Year = 2025 AND Month = 11 ORDER BY AttendancePercentage;
GO

PRINT '=== DEMO 3: Low Performing Employees ===';
SELECT * FROM vw_LowPerformingEmployees WHERE Year = 2025 AND Month = 11;
GO

PRINT '=== DEMO 4: Monthly Salary Calculation for Rajendra ===';
EXEC sp_CalculateMonthlySalary @EmployeeID = 1001, @Month = 11, @Year = 2025;
GO

PRINT '=== DEMO 5: Generate Payslip for Rajendra ===';
EXEC sp_GeneratePayslip @EmployeeID = 1001, @Month = 11, @Year = 2025;
GO

PRINT '=== DEMO 6: Process Complete Payroll for November 2025 ===';
EXEC sp_ProcessMonthlyPayroll @Month = 11, @Year = 2025;
GO

PRINT '=== DEMO 7: Employee Performance Analysis ===';
EXEC sp_GetEmployeePerformance @Month = 11, @Year = 2025;
GO

PRINT '=== DEMO 8: Monthly Salary Summary ===';
SELECT * FROM vw_MonthlySalarySummary;
GO

PRINT '=============================================================';
PRINT '=== PAYROLL SYSTEM SETUP COMPLETE ===';
PRINT '=============================================================';
PRINT 'Database: PayrollManagementDB';
PRINT 'Tables: 6 (Departments, Employees, Salary, TaxSlab, Attendance, Payslips)';
PRINT 'Stored Procedures: 4';
PRINT 'Views: 4';
PRINT 'Skills: CASE WHEN, Window Functions, CTEs, Subqueries, Cursors';
PRINT '=============================================================';
GO