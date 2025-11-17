/*
================================================================================
Banking System (Accounts + Transactions) - Microsoft SQL Server Script
================================================================================
This script creates the full schema, populates it with sample data,
and implements triggers and stored procedures as requested.

Sections:
1. Database & Schema Creation
2. Triggers (Suspicious Transaction Detection)
3. Sample Data Insertion
4. Stored Procedures (Reports & Tasks)
5. Demonstration
================================================================================
*/

-- Use master to check/create the database
USE master;
GO

-- Create the database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'BankingDB')
BEGIN
    CREATE DATABASE BankingDB;
END
GO

-- Switch to the newly created database
USE BankingDB;
GO

/*
================================================================================
1. DATABASE & SCHEMA CREATION
   - Dropping tables in reverse order of creation to handle foreign keys
================================================================================
*/

-- Drop existing tables if they exist (in reverse order of dependency)
DROP TABLE IF EXISTS SuspiciousTransactionsLog;
DROP TABLE IF EXISTS Transactions;
DROP TABLE IF EXISTS Accounts;
GO

-- Table: Accounts
CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY IDENTITY(1,1),
    HolderName NVARCHAR(100) NOT NULL,
    Balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00
        CHECK (Balance >= 0), -- Disallow overdrafts by default
    Status NVARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (Status IN ('Active', 'Frozen', 'Closed'))
);
GO

-- Table: Transactions
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    AccountID INT NOT NULL REFERENCES Accounts(AccountID),
    TransactionType NVARCHAR(20) NOT NULL 
        CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Transfer-Out', 'Transfer-In', 'Interest')),
    Amount DECIMAL(15, 2) NOT NULL 
        CHECK (Amount > 0), -- Amount must be positive
    TransactionDate DATETIME DEFAULT GETDATE(),
    RelatedAccountID INT NULL -- For transfers, links to the other account
);
GO

-- Table: SuspiciousTransactionsLog
CREATE TABLE SuspiciousTransactionsLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    TransactionID INT NOT NULL,
    AccountID INT NOT NULL,
    Amount DECIMAL(15, 2) NOT NULL,
    LogDate DATETIME DEFAULT GETDATE(),
    Note NVARCHAR(255)
);
GO

PRINT 'Section 1: Database and Schema created successfully.';
GO

/*
================================================================================
2. TRIGGERS (Suspicious Transaction Detection)
   - This trigger fires *after* a transaction is inserted.
   - It checks if the amount is > 100,000 (1 Lakh).
================================================================================
*/

CREATE OR ALTER TRIGGER tr_CheckSuspiciousTransaction
ON Transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SuspiciousLimit DECIMAL(15, 2) = 100000.00;
    
    -- Insert into the log table if any inserted rows exceed the limit
    INSERT INTO SuspiciousTransactionsLog (TransactionID, AccountID, Amount, Note)
    SELECT
        i.TransactionID,
        i.AccountID,
        i.Amount,
        'Transaction exceeded 1 Lakh limit.'
    FROM inserted i
    WHERE
        i.Amount > @SuspiciousLimit;
END
GO

PRINT 'Section 2: Suspicious Transaction trigger created successfully.';
GO

/*
================================================================================
3. SAMPLE DATA INSERTION
   - Populating tables with initial data.
   - Note: Charlie's deposit will FIRE the trigger created in Section 2.
================================================================================
*/

BEGIN TRANSACTION;
PRINT 'Inserting sample data...';

-- Insert Accounts
INSERT INTO Accounts (HolderName, Balance)
VALUES
('Alice Smith', 50000.00),  -- AccountID 1
('Bob Johnson', 10000.00),  -- AccountID 2
('Charlie Brown', 0.00);    -- AccountID 3

-- Insert Transactions
-- Alice's initial deposit
INSERT INTO Transactions (AccountID, TransactionType, Amount)
VALUES (1, 'Deposit', 50000.00);

-- Bob's initial deposit
INSERT INTO Transactions (AccountID, TransactionType, Amount)
VALUES (2, 'Deposit', 10000.00);

-- Charlie's initial deposit (This IS suspicious and WILL fire the trigger)
PRINT 'Inserting a large transaction for Charlie (this will fire the trigger)...';
INSERT INTO Transactions (AccountID, TransactionType, Amount)
VALUES (3, 'Deposit', 1500000.00);
-- Update Charlie's balance (since the trigger doesn't update the account)
UPDATE Accounts SET Balance = 1500000.00 WHERE AccountID = 3;

-- Some smaller transactions
INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate)
VALUES (1, 'Withdrawal', 1000.00, GETDATE() - 2);
UPDATE Accounts SET Balance = Balance - 1000.00 WHERE AccountID = 1;

INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate)
VALUES (2, 'Withdrawal', 500.00, GETDATE() - 1);
UPDATE Accounts SET Balance = Balance - 500.00 WHERE AccountID = 2;

COMMIT TRANSACTION;
PRINT 'Section 3: Sample data inserted. Trigger was fired for Charlie''s deposit.';
GO

/*
================================================================================
4. STORED PROCEDURES (Reports & Tasks)
   - sp_TransferFunds (Uses BEGIN/COMMIT Transaction)
   - sp_GetDailySummary
   - sp_GetAccountStatement
   - sp_GetSuspiciousTransactions
   - sp_CreditMonthlyInterest
================================================================================
*/

-- Procedure: Transfer Funds (Demonstrates BEGIN/COMMIT)
CREATE OR ALTER PROCEDURE sp_TransferFunds
    @FromAccountID INT,
    @ToAccountID INT,
    @Amount DECIMAL(15, 2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check for self-transfer
    IF @FromAccountID = @ToAccountID
    BEGIN
        RAISERROR('Cannot transfer funds to the same account.', 16, 1);
        RETURN;
    END

    -- Check for positive amount
    IF @Amount <= 0
    BEGIN
        RAISERROR('Transfer amount must be positive.', 16, 1);
        RETURN;
    END

    -- Use UPDLOCK to prevent other transactions from modifying this row
    DECLARE @FromBalance DECIMAL(15, 2);
    SELECT @FromBalance = Balance FROM Accounts WITH (UPDLOCK) WHERE AccountID = @FromAccountID;

    -- Check for sufficient funds
    IF @FromBalance < @Amount
    BEGIN
        RAISERROR('Insufficient funds. Transaction rolled back.', 16, 1);
        RETURN;
    END

    -- Start the transaction
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Debit from the sender
        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromAccountID;

        -- Credit to the receiver
        UPDATE Accounts
        SET Balance = Balance + @Amount
        WHERE AccountID = @ToAccountID;

        -- Log the 'Out' transaction
        INSERT INTO Transactions (AccountID, TransactionType, Amount, RelatedAccountID)
        VALUES (@FromAccountID, 'Transfer-Out', @Amount, @ToAccountID);

        -- Log the 'In' transaction
        INSERT INTO Transactions (AccountID, TransactionType, Amount, RelatedAccountID)
        VALUES (@ToAccountID, 'Transfer-In', @Amount, @FromAccountID);

        -- Commit the transaction if all steps are successful
        COMMIT TRANSACTION;
        PRINT 'Transfer successful.';
    END TRY
    BEGIN CATCH
        -- Roll back the transaction if any error occurs
        ROLLBACK TRANSACTION;
        
        -- Re-throw the original error
        THROW;
    END CATCH
END
GO

-- Procedure: Daily Summary of Credits/Debits
CREATE OR ALTER PROCEDURE sp_GetDailySummary
    @SummaryDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to today if no date is provided
    IF @SummaryDate IS NULL
    BEGIN
        SET @SummaryDate = CONVERT(DATE, GETDATE());
    END

    -- Get all credits
    SELECT 
        'Credits' AS TransactionCategory,
        TransactionType,
        SUM(Amount) AS TotalAmount
    FROM Transactions
    WHERE 
        CONVERT(DATE, TransactionDate) = @SummaryDate
        AND TransactionType IN ('Deposit', 'Transfer-In', 'Interest')
    GROUP BY TransactionType

    UNION ALL

    -- Get all debits
    SELECT 
        'Debits' AS TransactionCategory,
        TransactionType,
        SUM(Amount) AS TotalAmount
    FROM Transactions
    WHERE 
        CONVERT(DATE, TransactionDate) = @SummaryDate
        AND TransactionType IN ('Withdrawal', 'Transfer-Out')
    GROUP BY TransactionType;
END
GO

-- Procedure: Generate Account Statement
CREATE OR ALTER PROCEDURE sp_GetAccountStatement
    @AccountID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '--- Account Statement ---';
    PRINT 'Account Holder: ' + (SELECT HolderName FROM Accounts WHERE AccountID = @AccountID);
    PRINT 'Statement Period: ' + CONVERT(NVARCHAR, @StartDate) + ' to ' + CONVERT(NVARCHAR, @EndDate);
    PRINT '---------------------------------';

    SELECT
        t.TransactionDate,
        t.TransactionType,
        -- Show debits as negative, credits as positive
        CASE 
            WHEN t.TransactionType IN ('Withdrawal', 'Transfer-Out') THEN -t.Amount
            ELSE t.Amount 
        END AS SignedAmount,
        t.RelatedAccountID
    FROM Transactions t
    WHERE
        t.AccountID = @AccountID
        AND CONVERT(DATE, t.TransactionDate) BETWEEN @StartDate AND @EndDate
    ORDER BY
        t.TransactionDate DESC;
END
GO

-- Procedure: Detect (Report) Suspicious Transactions
CREATE OR ALTER PROCEDURE sp_GetSuspiciousTransactions
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        l.LogDate,
        l.TransactionID,
        a.HolderName,
        l.Amount,
        l.Note
    FROM SuspiciousTransactionsLog l
    JOIN Accounts a ON l.AccountID = a.AccountID
    ORDER BY
        l.LogDate DESC;
END
GO

-- Procedure: Monthly Interest Credit
CREATE OR ALTER PROCEDURE sp_CreditMonthlyInterest
    @InterestRate DECIMAL(5, 4) -- e.g., 0.01 for 1%
AS
BEGIN
    SET NOCOUNT ON;

    -- Use a table variable to hold payments before committing
    DECLARE @InterestPayments TABLE (
        AccountID INT,
        InterestAmount DECIMAL(15, 2)
    );

    -- Calculate interest for all active, positive-balance accounts
    INSERT INTO @InterestPayments (AccountID, InterestAmount)
    SELECT
        AccountID,
        Balance * @InterestRate
    FROM Accounts
    WHERE 
        Status = 'Active' 
        AND Balance > 0;

    -- Start transaction
    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- Update balances
        UPDATE a
        SET a.Balance = a.Balance + ip.InterestAmount
        FROM Accounts a
        JOIN @InterestPayments ip ON a.AccountID = ip.AccountID;

        -- Insert transaction records
        INSERT INTO Transactions (AccountID, TransactionType, Amount)
        SELECT 
            AccountID, 
            'Interest', 
            InterestAmount 
        FROM @InterestPayments;

        COMMIT TRANSACTION;
        PRINT 'Monthly interest credited successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error crediting interest. Transaction rolled back.';
        THROW;
    END CATCH
END
GO

PRINT 'Section 4: Stored Procedures created successfully.';
GO

/*
================================================================================
5. DEMONSTRATION
   - Executing the procedures and firing the trigger
================================================================================
*/

PRINT '========================================';
PRINT 'RUNNING DEMONSTRATION...';
PRINT '========================================';

PRINT '--- Initial Account Balances ---';
SELECT AccountID, HolderName, Balance FROM Accounts;
GO

PRINT '--- Report: Suspicious Transactions (Should show Charlie''s initial deposit) ---';
EXEC sp_GetSuspiciousTransactions;
GO

PRINT '--- Task: Successful Transfer (Alice -> Bob, 5000) ---';
EXEC sp_TransferFunds @FromAccountID = 1, @ToAccountID = 2, @Amount = 5000.00;
GO

PRINT '--- Balances After Successful Transfer ---';
SELECT AccountID, HolderName, Balance FROM Accounts;
GO

PRINT '--- Counter-Example: FAILED Transfer (Bob -> Alice, 15000) ---';
PRINT '(Bob only has 14500, so this will fail)';
-- We use TRY/CATCH here to handle the expected error from RAISERROR
BEGIN TRY
    EXEC sp_TransferFunds @FromAccountID = 2, @ToAccountID = 1, @Amount = 15000.00;
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- Balances After FAILED Transfer (Should be unchanged) ---';
SELECT AccountID, HolderName, Balance FROM Accounts;
GO

PRINT '--- Task: Credit 1% Monthly Interest ---';
EXEC sp_CreditMonthlyInterest @InterestRate = 0.01;
GO

PRINT '--- Balances After Interest ---';
SELECT AccountID, HolderName, Balance FROM Accounts;
GO

PRINT '--- Task: Account Statement for Alice ---';
EXEC sp_GetAccountStatement @AccountID = 1, @StartDate = '2000-01-01', @EndDate = '2099-12-31';
GO

PRINT '--- Task: Daily Summary for Today ---';
EXEC sp_GetDailySummary;
GO

PRINT '--- Task: Firing another suspicious transaction (Alice deposits 200,000) ---';
-- This will fire the trigger again
INSERT INTO Transactions (AccountID, TransactionType, Amount)
VALUES (1, 'Deposit', 200000.00);
UPDATE Accounts SET Balance = Balance + 200000.00 WHERE AccountID = 1;
GO

PRINT '--- Report: Suspicious Transactions (Should now show 2 entries) ---';
EXEC sp_GetSuspiciousTransactions;
GO

PRINT '========================================';
PRINT 'DEMONSTRATION COMPLETE.';
PRINT '========================================';