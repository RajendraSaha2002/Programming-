-- =============================================
-- Banking System - SQL Server Script
-- Account Management + Transaction Processing
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'BankingSystemDB')
BEGIN
    CREATE DATABASE BankingSystemDB;
END
GO

USE BankingSystemDB;
GO

-- =============================================
-- DROP EXISTING OBJECTS (IF ANY)
-- =============================================
-- Drop triggers first
IF OBJECT_ID('trg_ValidateTransaction', 'TR') IS NOT NULL DROP TRIGGER trg_ValidateTransaction;
IF OBJECT_ID('trg_UpdateAccountBalance', 'TR') IS NOT NULL DROP TRIGGER trg_UpdateAccountBalance;
IF OBJECT_ID('trg_DetectSuspiciousActivity', 'TR') IS NOT NULL DROP TRIGGER trg_DetectSuspiciousActivity;
IF OBJECT_ID('trg_AuditAccountChanges', 'TR') IS NOT NULL DROP TRIGGER trg_AuditAccountChanges;
GO

-- Drop stored procedures
IF OBJECT_ID('sp_Deposit', 'P') IS NOT NULL DROP PROCEDURE sp_Deposit;
IF OBJECT_ID('sp_Withdraw', 'P') IS NOT NULL DROP PROCEDURE sp_Withdraw;
IF OBJECT_ID('sp_Transfer', 'P') IS NOT NULL DROP PROCEDURE sp_Transfer;
IF OBJECT_ID('sp_MonthlyInterestCredit', 'P') IS NOT NULL DROP PROCEDURE sp_MonthlyInterestCredit;
IF OBJECT_ID('sp_GetAccountStatement', 'P') IS NOT NULL DROP PROCEDURE sp_GetAccountStatement;
IF OBJECT_ID('sp_GetDailySummary', 'P') IS NOT NULL DROP PROCEDURE sp_GetDailySummary;
GO

-- Drop views
IF OBJECT_ID('vw_AccountSummary', 'V') IS NOT NULL DROP VIEW vw_AccountSummary;
IF OBJECT_ID('vw_DailyTransactionSummary', 'V') IS NOT NULL DROP VIEW vw_DailyTransactionSummary;
IF OBJECT_ID('vw_SuspiciousTransactions', 'V') IS NOT NULL DROP VIEW vw_SuspiciousTransactions;
GO

-- Drop tables
IF OBJECT_ID('AuditLog', 'U') IS NOT NULL DROP TABLE AuditLog;
IF OBJECT_ID('SuspiciousActivity', 'U') IS NOT NULL DROP TABLE SuspiciousActivity;
IF OBJECT_ID('Transactions', 'U') IS NOT NULL DROP TABLE Transactions;
IF OBJECT_ID('Accounts', 'U') IS NOT NULL DROP TABLE Accounts;
IF OBJECT_ID('AccountTypes', 'U') IS NOT NULL DROP TABLE AccountTypes;
GO

-- =============================================
-- TABLE: AccountTypes
-- =============================================
CREATE TABLE AccountTypes (
    AccountTypeID INT PRIMARY KEY IDENTITY(1,1),
    TypeName NVARCHAR(50) NOT NULL UNIQUE,
    MinimumBalance DECIMAL(18,2) DEFAULT 0,
    InterestRate DECIMAL(5,2) DEFAULT 0,
    Description NVARCHAR(255)
);
GO

-- =============================================
-- TABLE: Accounts
-- =============================================
CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY IDENTITY(1001,1),
    AccountNumber NVARCHAR(20) UNIQUE NOT NULL,
    HolderName NVARCHAR(100) NOT NULL,
    AccountTypeID INT FOREIGN KEY REFERENCES AccountTypes(AccountTypeID),
    Balance DECIMAL(18,2) DEFAULT 0 CHECK (Balance >= 0),
    OpeningDate DATE DEFAULT CAST(GETDATE() AS DATE),
    Status NVARCHAR(20) CHECK (Status IN ('Active', 'Inactive', 'Frozen', 'Closed')) DEFAULT 'Active',
    BranchCode NVARCHAR(10),
    Email NVARCHAR(100),
    PhoneNumber NVARCHAR(15),
    Address NVARCHAR(255),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CreatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,
    ModifiedBy NVARCHAR(50) DEFAULT SYSTEM_USER
);
GO

-- =============================================
-- TABLE: Transactions
-- =============================================
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    TransactionNumber NVARCHAR(30) UNIQUE NOT NULL,
    AccountID INT FOREIGN KEY REFERENCES Accounts(AccountID),
    TransactionType NVARCHAR(20) CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Transfer-Out', 'Transfer-In', 'Interest', 'Fee', 'Reversal')) NOT NULL,
    Amount DECIMAL(18,2) CHECK (Amount > 0) NOT NULL,
    BalanceAfter DECIMAL(18,2),
    TransactionDate DATETIME DEFAULT GETDATE(),
    Description NVARCHAR(255),
    ReferenceNumber NVARCHAR(50),
    RelatedAccountID INT NULL, -- For transfers
    ProcessedBy NVARCHAR(50) DEFAULT SYSTEM_USER,
    Status NVARCHAR(20) CHECK (Status IN ('Pending', 'Completed', 'Failed', 'Reversed')) DEFAULT 'Completed',
    CONSTRAINT FK_RelatedAccount FOREIGN KEY (RelatedAccountID) REFERENCES Accounts(AccountID)
);
GO

-- =============================================
-- TABLE: SuspiciousActivity
-- =============================================
CREATE TABLE SuspiciousActivity (
    AlertID INT PRIMARY KEY IDENTITY(1,1),
    TransactionID INT FOREIGN KEY REFERENCES Transactions(TransactionID),
    AccountID INT FOREIGN KEY REFERENCES Accounts(AccountID),
    AlertType NVARCHAR(50),
    Amount DECIMAL(18,2),
    AlertDate DATETIME DEFAULT GETDATE(),
    Description NVARCHAR(500),
    Reviewed BIT DEFAULT 0,
    ReviewedBy NVARCHAR(50),
    ReviewedDate DATETIME,
    Resolution NVARCHAR(255)
);
GO

-- =============================================
-- TABLE: AuditLog
-- =============================================
CREATE TABLE AuditLog (
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(50),
    RecordID INT,
    Operation NVARCHAR(20),
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX),
    ModifiedBy NVARCHAR(50) DEFAULT SYSTEM_USER,
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

-- Insert Account Types
INSERT INTO AccountTypes (TypeName, MinimumBalance, InterestRate, Description)
VALUES 
    ('Savings', 1000.00, 4.00, 'Regular savings account with 4% annual interest'),
    ('Current', 5000.00, 0.00, 'Current account for business transactions'),
    ('Fixed Deposit', 10000.00, 7.00, 'Fixed deposit account with 7% annual interest'),
    ('Salary', 0.00, 3.50, 'Salary account with 3.5% annual interest');
GO

-- Insert Accounts
INSERT INTO Accounts (AccountNumber, HolderName, AccountTypeID, Balance, OpeningDate, BranchCode, Email, PhoneNumber, Address, Status)
VALUES 
    ('ACC001234567890', 'Rajesh Kumar', 1, 50000.00, '2024-01-15', 'BR001', 'rajesh.kumar@email.com', '9876543210', '123 MG Road, Delhi', 'Active'),
    ('ACC001234567891', 'Priya Sharma', 1, 75000.00, '2024-02-20', 'BR001', 'priya.sharma@email.com', '9876543211', '456 Park Street, Mumbai', 'Active'),
    ('ACC001234567892', 'Amit Patel', 2, 150000.00, '2024-03-10', 'BR002', 'amit.patel@email.com', '9876543212', '789 FC Road, Pune', 'Active'),
    ('ACC001234567893', 'Sneha Reddy', 1, 35000.00, '2024-04-05', 'BR001', 'sneha.reddy@email.com', '9876543213', '321 Brigade Road, Bangalore', 'Active'),
    ('ACC001234567894', 'Vikram Singh', 3, 500000.00, '2024-05-12', 'BR003', 'vikram.singh@email.com', '9876543214', '654 Civil Lines, Jaipur', 'Active'),
    ('ACC001234567895', 'Anita Desai', 4, 45000.00, '2024-06-18', 'BR002', 'anita.desai@email.com', '9876543215', '987 Salt Lake, Kolkata', 'Active'),
    ('ACC001234567896', 'Ravi Verma', 1, 25000.00, '2024-07-22', 'BR001', 'ravi.verma@email.com', '9876543216', '147 Anna Nagar, Chennai', 'Active'),
    ('ACC001234567897', 'Deepika Nair', 2, 200000.00, '2024-08-30', 'BR003', 'deepika.nair@email.com', '9876543217', '258 MG Road, Kochi', 'Active');
GO

-- Insert Sample Transactions
DECLARE @TxnDate DATETIME = '2025-11-01 09:00:00';

-- Account 1001 - Rajesh Kumar
INSERT INTO Transactions (TransactionNumber, AccountID, TransactionType, Amount, BalanceAfter, TransactionDate, Description, Status)
VALUES 
    ('TXN202511010001', 1001, 'Deposit', 10000.00, 60000.00, @TxnDate, 'Cash deposit at branch', 'Completed'),
    ('TXN202511050001', 1001, 'Withdrawal', 5000.00, 55000.00, DATEADD(DAY, 4, @TxnDate), 'ATM withdrawal', 'Completed'),
    ('TXN202511100001', 1001, 'Deposit', 15000.00, 70000.00, DATEADD(DAY, 9, @TxnDate), 'Salary credit', 'Completed');

-- Account 1002 - Priya Sharma
INSERT INTO Transactions (TransactionNumber, AccountID, TransactionType, Amount, BalanceAfter, TransactionDate, Description, Status)
VALUES 
    ('TXN202511020001', 1002, 'Deposit', 25000.00, 100000.00, DATEADD(DAY, 1, @TxnDate), 'Online transfer', 'Completed'),
    ('TXN202511070001', 1002, 'Withdrawal', 10000.00, 90000.00, DATEADD(DAY, 6, @TxnDate), 'Bill payment', 'Completed');

-- Account 1003 - Amit Patel (Business - larger amounts)
INSERT INTO Transactions (TransactionNumber, AccountID, TransactionType, Amount, BalanceAfter, TransactionDate, Description, Status)
VALUES 
    ('TXN202511030001', 1003, 'Deposit', 75000.00, 225000.00, DATEADD(DAY, 2, @TxnDate), 'Business income', 'Completed'),
    ('TXN202511080001', 1003, 'Withdrawal', 125000.00, 100000.00, DATEADD(DAY, 7, @TxnDate), 'Suspicious - Large withdrawal', 'Completed'),
    ('TXN202511120001', 1003, 'Deposit', 150000.00, 250000.00, DATEADD(DAY, 11, @TxnDate), 'Suspicious - Large deposit', 'Completed');

-- Account 1004 - Sneha Reddy
INSERT INTO Transactions (TransactionNumber, AccountID, TransactionType, Amount, BalanceAfter, TransactionDate, Description, Status)
VALUES 
    ('TXN202511040001', 1004, 'Withdrawal', 5000.00, 30000.00, DATEADD(DAY, 3, @TxnDate), 'Shopping', 'Completed'),
    ('TXN202511090001', 1004, 'Deposit', 8000.00, 38000.00, DATEADD(DAY, 8, @TxnDate), 'Freelance payment', 'Completed');

-- Today's transactions (2025-11-20)
DECLARE @Today DATETIME = '2025-11-20 08:00:00';

INSERT INTO Transactions (TransactionNumber, AccountID, TransactionType, Amount, BalanceAfter, TransactionDate, Description, Status)
VALUES 
    ('TXN202511200001', 1001, 'Deposit', 20000.00, 90000.00, @Today, 'Cash deposit', 'Completed'),
    ('TXN202511200002', 1002, 'Withdrawal', 15000.00, 75000.00, DATEADD(HOUR, 1, @Today), 'ATM withdrawal', 'Completed'),
    ('TXN202511200003', 1003, 'Deposit', 200000.00, 450000.00, DATEADD(HOUR, 2, @Today), 'Suspicious - Large deposit today', 'Completed'),
    ('TXN202511200004', 1004, 'Transfer-Out', 10000.00, 28000.00, DATEADD(HOUR, 3, @Today), 'Transfer to friend', 'Completed'),
    ('TXN202511200005', 1006, 'Transfer-In', 10000.00, 55000.00, DATEADD(HOUR, 3, @Today), 'Transfer from ACC001234567893', 'Completed'),
    ('TXN202511200006', 1007, 'Withdrawal', 3000.00, 22000.00, DATEADD(HOUR, 4, @Today), 'Bill payment', 'Completed');
GO

-- Update related account IDs for transfers
UPDATE Transactions SET RelatedAccountID = 1006 WHERE TransactionNumber = 'TXN202511200004';
UPDATE Transactions SET RelatedAccountID = 1004 WHERE TransactionNumber = 'TXN202511200005';
GO

-- =============================================
-- TRIGGER 1: Validate Transaction Before Insert
-- =============================================
CREATE TRIGGER trg_ValidateTransaction
ON Transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AccountID INT, @Type NVARCHAR(20), @Amount DECIMAL(18,2);
    DECLARE @Balance DECIMAL(18,2), @Status NVARCHAR(20), @MinBalance DECIMAL(18,2);
    
    SELECT 
        @AccountID = AccountID,
        @Type = TransactionType,
        @Amount = Amount
    FROM inserted;
    
    -- Get account details
    SELECT 
        @Balance = a.Balance,
        @Status = a.Status,
        @MinBalance = ISNULL(at.MinimumBalance, 0)
    FROM Accounts a
    LEFT JOIN AccountTypes at ON a.AccountTypeID = at.AccountTypeID
    WHERE a.AccountID = @AccountID;
    
    -- Validation checks
    IF @Status != 'Active'
    BEGIN
        RAISERROR('Transaction failed: Account is not active', 16, 1);
        RETURN;
    END
    
    IF @Type IN ('Withdrawal', 'Transfer-Out')
    BEGIN
        IF (@Balance - @Amount) < @MinBalance
        BEGIN
            RAISERROR('Transaction failed: Insufficient balance. Minimum balance requirement not met.', 16, 1);
            RETURN;
        END
    END
    
    -- If validation passes, insert the transaction
    INSERT INTO Transactions (
        TransactionNumber, AccountID, TransactionType, Amount, 
        BalanceAfter, TransactionDate, Description, ReferenceNumber, 
        RelatedAccountID, ProcessedBy, Status
    )
    SELECT 
        TransactionNumber, AccountID, TransactionType, Amount,
        BalanceAfter, TransactionDate, Description, ReferenceNumber,
        RelatedAccountID, ProcessedBy, Status
    FROM inserted;
    
    PRINT 'Transaction validated and inserted successfully.';
END
GO

-- =============================================
-- TRIGGER 2: Update Account Balance After Transaction
-- =============================================
CREATE TRIGGER trg_UpdateAccountBalance
ON Transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AccountID INT, @Type NVARCHAR(20), @Amount DECIMAL(18,2);
    DECLARE @NewBalance DECIMAL(18,2), @TransactionID INT;
    
    SELECT 
        @TransactionID = TransactionID,
        @AccountID = AccountID,
        @Type = TransactionType,
        @Amount = Amount
    FROM inserted;
    
    -- Calculate new balance
    IF @Type IN ('Deposit', 'Transfer-In', 'Interest')
    BEGIN
        UPDATE Accounts 
        SET Balance = Balance + @Amount,
            ModifiedDate = GETDATE(),
            ModifiedBy = SYSTEM_USER
        WHERE AccountID = @AccountID;
    END
    ELSE IF @Type IN ('Withdrawal', 'Transfer-Out', 'Fee')
    BEGIN
        UPDATE Accounts 
        SET Balance = Balance - @Amount,
            ModifiedDate = GETDATE(),
            ModifiedBy = SYSTEM_USER
        WHERE AccountID = @AccountID;
    END
    
    -- Update BalanceAfter in transaction record
    UPDATE t
    SET t.BalanceAfter = a.Balance
    FROM Transactions t
    INNER JOIN Accounts a ON t.AccountID = a.AccountID
    WHERE t.TransactionID = @TransactionID;
    
    PRINT 'Account balance updated successfully.';
END
GO

-- =============================================
-- TRIGGER 3: Detect Suspicious Transactions
-- =============================================
CREATE TRIGGER trg_DetectSuspiciousActivity
ON Transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TransactionID INT, @AccountID INT, @Amount DECIMAL(18,2);
    DECLARE @Type NVARCHAR(20), @Description NVARCHAR(255);
    DECLARE @DailyTotal DECIMAL(18,2);
    DECLARE @SuspiciousThreshold DECIMAL(18,2) = 100000.00; -- 1 Lakh
    DECLARE @DailyLimitThreshold DECIMAL(18,2) = 200000.00; -- 2 Lakhs per day
    
    SELECT 
        @TransactionID = TransactionID,
        @AccountID = AccountID,
        @Amount = Amount,
        @Type = TransactionType
    FROM inserted;
    
    -- Check 1: Single transaction > 1 Lakh
    IF @Amount > @SuspiciousThreshold
    BEGIN
        INSERT INTO SuspiciousActivity (TransactionID, AccountID, AlertType, Amount, Description)
        VALUES (
            @TransactionID, 
            @AccountID, 
            'Large Single Transaction',
            @Amount,
            'Transaction amount exceeds ?1,00,000. Transaction Type: ' + @Type
        );
        
        PRINT 'ALERT: Suspicious transaction detected - Amount exceeds ?1,00,000';
    END
    
    -- Check 2: Daily transaction total > 2 Lakhs
    SELECT @DailyTotal = SUM(Amount)
    FROM Transactions
    WHERE AccountID = @AccountID
      AND CAST(TransactionDate AS DATE) = CAST(GETDATE() AS DATE)
      AND TransactionType IN ('Withdrawal', 'Transfer-Out');
    
    IF @DailyTotal > @DailyLimitThreshold
    BEGIN
        INSERT INTO SuspiciousActivity (TransactionID, AccountID, AlertType, Amount, Description)
        VALUES (
            @TransactionID, 
            @AccountID, 
            'Daily Limit Exceeded',
            @DailyTotal,
            'Total daily withdrawal/transfer exceeds ?2,00,000. Total: ?' + CAST(@DailyTotal AS NVARCHAR(20))
        );
        
        PRINT 'ALERT: Daily transaction limit exceeded - Total: ?' + CAST(@DailyTotal AS NVARCHAR(20));
    END
    
    -- Check 3: Multiple large transactions in short period
    DECLARE @RecentLargeCount INT;
    
    SELECT @RecentLargeCount = COUNT(*)
    FROM Transactions
    WHERE AccountID = @AccountID
      AND TransactionDate >= DATEADD(HOUR, -2, GETDATE())
      AND Amount > 50000.00;
    
    IF @RecentLargeCount >= 3
    BEGIN
        INSERT INTO SuspiciousActivity (TransactionID, AccountID, AlertType, Amount, Description)
        VALUES (
            @TransactionID, 
            @AccountID, 
            'Multiple Large Transactions',
            @Amount,
            'Multiple large transactions (>?50,000) within 2 hours. Count: ' + CAST(@RecentLargeCount AS NVARCHAR(5))
        );
        
        PRINT 'ALERT: Multiple large transactions detected in short period';
    END
END
GO

-- =============================================
-- TRIGGER 4: Audit Account Changes
-- =============================================
CREATE TRIGGER trg_AuditAccountChanges
ON Accounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLog (TableName, RecordID, Operation, OldValue, NewValue, ModifiedBy)
    SELECT 
        'Accounts',
        i.AccountID,
        'UPDATE',
        'Balance: ' + CAST(d.Balance AS NVARCHAR(20)) + ', Status: ' + d.Status,
        'Balance: ' + CAST(i.Balance AS NVARCHAR(20)) + ', Status: ' + i.Status,
        SYSTEM_USER
    FROM inserted i
    INNER JOIN deleted d ON i.AccountID = d.AccountID
    WHERE i.Balance != d.Balance OR i.Status != d.Status;
END
GO

-- =============================================
-- STORED PROCEDURE 1: Deposit Money
-- =============================================
CREATE PROCEDURE sp_Deposit
    @AccountNumber NVARCHAR(20),
    @Amount DECIMAL(18,2),
    @Description NVARCHAR(255) = 'Cash deposit',
    @ReferenceNumber NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @AccountID INT;
        DECLARE @TransactionNumber NVARCHAR(30);
        DECLARE @CurrentBalance DECIMAL(18,2);
        
        -- Validate amount
        IF @Amount <= 0
        BEGIN
            RAISERROR('Amount must be greater than zero', 16, 1);
            RETURN;
        END
        
        -- Get Account ID
        SELECT @AccountID = AccountID, @CurrentBalance = Balance
        FROM Accounts
        WHERE AccountNumber = @AccountNumber AND Status = 'Active';
        
        IF @AccountID IS NULL
        BEGIN
            RAISERROR('Account not found or inactive', 16, 1);
            RETURN;
        END
        
        -- Generate transaction number
        SET @TransactionNumber = 'TXN' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + RIGHT('000' + CAST(@AccountID AS NVARCHAR(10)), 4);
        
        -- Insert transaction
        INSERT INTO Transactions (
            TransactionNumber, AccountID, TransactionType, Amount, 
            TransactionDate, Description, ReferenceNumber, Status
        )
        VALUES (
            @TransactionNumber, @AccountID, 'Deposit', @Amount,
            GETDATE(), @Description, @ReferenceNumber, 'Completed'
        );
        
        COMMIT TRANSACTION;
        
        -- Return success message
        SELECT 
            'Success' AS Status,
            @TransactionNumber AS TransactionNumber,
            @Amount AS Amount,
            @CurrentBalance + @Amount AS NewBalance,
            'Deposit successful' AS Message;
            
        PRINT 'Deposit completed successfully. Transaction: ' + @TransactionNumber;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- STORED PROCEDURE 2: Withdraw Money
-- =============================================
CREATE PROCEDURE sp_Withdraw
    @AccountNumber NVARCHAR(20),
    @Amount DECIMAL(18,2),
    @Description NVARCHAR(255) = 'Cash withdrawal',
    @ReferenceNumber NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @AccountID INT;
        DECLARE @TransactionNumber NVARCHAR(30);
        DECLARE @CurrentBalance DECIMAL(18,2);
        DECLARE @MinBalance DECIMAL(18,2);
        
        -- Validate amount
        IF @Amount <= 0
        BEGIN
            RAISERROR('Amount must be greater than zero', 16, 1);
            RETURN;
        END
        
        -- Get Account details
        SELECT 
            @AccountID = a.AccountID, 
            @CurrentBalance = a.Balance,
            @MinBalance = ISNULL(at.MinimumBalance, 0)
        FROM Accounts a
        LEFT JOIN AccountTypes at ON a.AccountTypeID = at.AccountTypeID
        WHERE a.AccountNumber = @AccountNumber AND a.Status = 'Active';
        
        IF @AccountID IS NULL
        BEGIN
            RAISERROR('Account not found or inactive', 16, 1);
            RETURN;
        END
        
        -- Check sufficient balance
        IF (@CurrentBalance - @Amount) < @MinBalance
        BEGIN
            RAISERROR('Insufficient balance. Minimum balance requirement not met.', 16, 1);
            RETURN;
        END
        
        -- Generate transaction number
        SET @TransactionNumber = 'TXN' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + RIGHT('000' + CAST(@AccountID AS NVARCHAR(10)), 4);
        
        -- Insert transaction
        INSERT INTO Transactions (
            TransactionNumber, AccountID, TransactionType, Amount, 
            TransactionDate, Description, ReferenceNumber, Status
        )
        VALUES (
            @TransactionNumber, @AccountID, 'Withdrawal', @Amount,
            GETDATE(), @Description, @ReferenceNumber, 'Completed'
        );
        
        COMMIT TRANSACTION;
        
        -- Return success message
        SELECT 
            'Success' AS Status,
            @TransactionNumber AS TransactionNumber,
            @Amount AS Amount,
            @CurrentBalance - @Amount AS NewBalance,
            'Withdrawal successful' AS Message;
            
        PRINT 'Withdrawal completed successfully. Transaction: ' + @TransactionNumber;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- STORED PROCEDURE 3: Transfer Money
-- =============================================
CREATE PROCEDURE sp_Transfer
    @FromAccountNumber NVARCHAR(20),
    @ToAccountNumber NVARCHAR(20),
    @Amount DECIMAL(18,2),
    @Description NVARCHAR(255) = 'Fund transfer',
    @ReferenceNumber NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @FromAccountID INT, @ToAccountID INT;
        DECLARE @FromBalance DECIMAL(18,2), @ToBalance DECIMAL(18,2);
        DECLARE @MinBalance DECIMAL(18,2);
        DECLARE @TxnNumberOut NVARCHAR(30), @TxnNumberIn NVARCHAR(30);
        
        -- Validate amount
        IF @Amount <= 0
        BEGIN
            RAISERROR('Amount must be greater than zero', 16, 1);
            RETURN;
        END
        
        -- Validate different accounts
        IF @FromAccountNumber = @ToAccountNumber
        BEGIN
            RAISERROR('Cannot transfer to the same account', 16, 1);
            RETURN;
        END
        
        -- Get From Account details
        SELECT 
            @FromAccountID = a.AccountID, 
            @FromBalance = a.Balance,
            @MinBalance = ISNULL(at.MinimumBalance, 0)
        FROM Accounts a
        LEFT JOIN AccountTypes at ON a.AccountTypeID = at.AccountTypeID
        WHERE a.AccountNumber = @FromAccountNumber AND a.Status = 'Active';
        
        IF @FromAccountID IS NULL
        BEGIN
            RAISERROR('Source account not found or inactive', 16, 1);
            RETURN;
        END
        
        -- Get To Account details
        SELECT @ToAccountID = AccountID, @ToBalance = Balance
        FROM Accounts
        WHERE AccountNumber = @ToAccountNumber AND Status = 'Active';
        
        IF @ToAccountID IS NULL
        BEGIN
            RAISERROR('Destination account not found or inactive', 16, 1);
            RETURN;
        END
        
        -- Check sufficient balance
        IF (@FromBalance - @Amount) < @MinBalance
        BEGIN
            RAISERROR('Insufficient balance in source account', 16, 1);
            RETURN;
        END
        
        -- Generate transaction numbers
        SET @TxnNumberOut = 'TXN' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + RIGHT('000' + CAST(@FromAccountID AS NVARCHAR(10)), 4);
        
        -- Small delay to ensure unique transaction number
        WAITFOR DELAY '00:00:00.100';
        
        SET @TxnNumberIn = 'TXN' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + RIGHT('000' + CAST(@ToAccountID AS NVARCHAR(10)), 4);
        
        -- Debit from source account
        INSERT INTO Transactions (
            TransactionNumber, AccountID, TransactionType, Amount, 
            TransactionDate, Description, ReferenceNumber, RelatedAccountID, Status
        )
        VALUES (
            @TxnNumberOut, @FromAccountID, 'Transfer-Out', @Amount,
            GETDATE(), @Description, @ReferenceNumber, @ToAccountID, 'Completed'
        );
        
        -- Credit to destination account
        INSERT INTO Transactions (
            TransactionNumber, AccountID, TransactionType, Amount, 
            TransactionDate, Description, ReferenceNumber, RelatedAccountID, Status
        )
        VALUES (
            @TxnNumberIn, @ToAccountID, 'Transfer-In', @Amount,
            GETDATE(), 'Transfer from ' + @FromAccountNumber, @ReferenceNumber, @FromAccountID, 'Completed'
        );
        
        COMMIT TRANSACTION;
        
        -- Return success message
        SELECT 
            'Success' AS Status,
            @TxnNumberOut AS DebitTransactionNumber,
            @TxnNumberIn AS CreditTransactionNumber,
            @Amount AS Amount,
            @FromBalance - @Amount AS FromAccountNewBalance,
            @ToBalance + @Amount AS ToAccountNewBalance,
            'Transfer successful' AS Message;
            
        PRINT 'Transfer completed successfully.';
        PRINT 'Debit Transaction: ' + @TxnNumberOut;
        PRINT 'Credit Transaction: ' + @TxnNumberIn;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- STORED PROCEDURE 4: Monthly Interest Credit
-- =============================================
CREATE PROCEDURE sp_MonthlyInterestCredit
    @ProcessMonth INT = NULL,
    @ProcessYear INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Default to current month if not provided
        IF @ProcessMonth IS NULL
            SET @ProcessMonth = MONTH(GETDATE());
        IF @ProcessYear IS NULL
            SET @ProcessYear = YEAR(GETDATE());
        
        DECLARE @ProcessedCount INT = 0;
        DECLARE @TotalInterest DECIMAL(18,2) = 0;
        
        -- Create temp table for interest calculations
        CREATE TABLE #InterestCalculation (
            AccountID INT,
            AccountNumber NVARCHAR(20),
            HolderName NVARCHAR(100),
            Balance DECIMAL(18,2),
            InterestRate DECIMAL(5,2),
            InterestAmount DECIMAL(18,2),
            TransactionNumber NVARCHAR(30)
        );
        
        -- Calculate interest for eligible accounts
        INSERT INTO #InterestCalculation
        SELECT 
            a.AccountID,
            a.AccountNumber,
            a.HolderName,
            a.Balance,
            at.InterestRate,
            ROUND((a.Balance * at.InterestRate / 100 / 12), 2) AS InterestAmount,
            'INT' + FORMAT(GETDATE(), 'yyyyMMdd') + RIGHT('000' + CAST(a.AccountID AS NVARCHAR(10)), 4) AS TransactionNumber
        FROM Accounts a
        INNER JOIN AccountTypes at ON a.AccountTypeID = at.AccountTypeID
        WHERE a.Status = 'Active'
          AND at.InterestRate > 0
          AND a.Balance > 0;
        
        -- Process interest credits
        DECLARE @AccountID INT, @InterestAmount DECIMAL(18,2), @TransactionNumber NVARCHAR(30);
        DECLARE @Description NVARCHAR(255);
        
        DECLARE interest_cursor CURSOR FOR
        SELECT AccountID, InterestAmount, TransactionNumber
        FROM #InterestCalculation;
        
        OPEN interest_cursor;
        FETCH NEXT FROM interest_cursor INTO @AccountID, @InterestAmount, @TransactionNumber;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Description = 'Monthly interest credit for ' + DATENAME(MONTH, DATEFROMPARTS(@ProcessYear, @ProcessMonth, 1)) + ' ' + CAST(@ProcessYear AS NVARCHAR(4));
            
            INSERT INTO Transactions (
                TransactionNumber, AccountID, TransactionType, Amount, 
                TransactionDate, Description, Status
            )
            VALUES (
                @TransactionNumber, @AccountID, 'Interest', @InterestAmount,
                GETDATE(), @Description, 'Completed'
            );
            
            SET @ProcessedCount = @ProcessedCount + 1;
            SET @TotalInterest = @TotalInterest + @InterestAmount;
            
            -- Add small delay to ensure unique timestamps
            WAITFOR DELAY '00:00:00.010';
            
            FETCH NEXT FROM interest_cursor INTO @AccountID, @InterestAmount, @TransactionNumber;
        END
        
        CLOSE interest_cursor;
        DEALLOCATE interest_cursor;
        
        COMMIT TRANSACTION;
        
        -- Return summary
        SELECT 
            @ProcessMonth AS ProcessedMonth,
            @ProcessYear AS ProcessedYear,
            @ProcessedCount AS AccountsProcessed,
            @TotalInterest AS TotalInterestCredited,
            'Interest credited successfully' AS Message;
        
        -- Show detailed report
        SELECT 
            AccountNumber,
            HolderName,
            Balance AS CurrentBalance,
            InterestRate AS AnnualRate,
            InterestAmount AS MonthlInterestCredited
        FROM #InterestCalculation
        ORDER BY InterestAmount DESC;
        
        DROP TABLE #InterestCalculation;
        
        PRINT 'Monthly interest credit completed successfully.';
        PRINT 'Accounts processed: ' + CAST(@ProcessedCount AS NVARCHAR(10));
        PRINT 'Total interest credited: ?' + CAST(@TotalInterest AS NVARCHAR(20));
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        IF CURSOR_STATUS('global', 'interest_cursor') >= 0
        BEGIN
            CLOSE interest_cursor;
            DEALLOCATE interest_cursor;
        END
        
        IF OBJECT_ID('tempdb..#InterestCalculation') IS NOT NULL
            DROP TABLE #InterestCalculation;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- STORED PROCEDURE 5: Get Account Statement
-- =============================================
CREATE PROCEDURE sp_GetAccountStatement
    @AccountNumber NVARCHAR(20),
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @TransactionType NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AccountID INT;
    
    -- Default date range: Last 30 days
    IF @FromDate IS NULL
        SET @FromDate = DATEADD(DAY, -30, GETDATE());
    IF @ToDate IS NULL
        SET @ToDate = CAST(GETDATE() AS DATE);
    
    -- Get Account ID
    SELECT @AccountID = AccountID
    FROM Accounts
    WHERE AccountNumber = @AccountNumber;
    
    IF @AccountID IS NULL
    BEGIN
        RAISERROR('Account not found', 16, 1);
        RETURN;
    END
    
    -- Account summary
    SELECT 
        a.AccountNumber,
        a.HolderName,
        at.TypeName AS AccountType,
        a.Balance AS CurrentBalance,
        a.Status,
        a.OpeningDate
    FROM Accounts a
    LEFT JOIN AccountTypes at ON a.AccountTypeID = at.AccountTypeID
    WHERE a.AccountID = @AccountID;
    
    -- Transaction details
    SELECT 
        t.TransactionDate,
        t.TransactionNumber,
        t.TransactionType,
        CASE 
            WHEN t.TransactionType IN ('Deposit', 'Transfer-In', 'Interest') THEN t.Amount
            ELSE 0
        END AS CreditAmount,
        CASE 
            WHEN t.TransactionType IN ('Withdrawal', 'Transfer-Out', 'Fee') THEN t.Amount
            ELSE 0
        END AS DebitAmount,
        t.BalanceAfter,
        t.Description,
        t.ReferenceNumber,
        CASE 
            WHEN t.RelatedAccountID IS NOT NULL 
            THEN (SELECT AccountNumber FROM Accounts WHERE AccountID = t.RelatedAccountID)
            ELSE NULL
        END AS RelatedAccount,
        t.Status
    FROM Transactions t
    WHERE t.AccountID = @AccountID
      AND CAST(t.TransactionDate AS DATE) BETWEEN @FromDate AND @ToDate
      AND (@TransactionType IS NULL OR t.TransactionType = @TransactionType)
    ORDER BY t.TransactionDate DESC, t.TransactionID DESC;
    
    -- Summary statistics
    SELECT 
        COUNT(*) AS TotalTransactions,
        SUM(CASE WHEN TransactionType IN ('Deposit', 'Transfer-In', 'Interest') THEN Amount ELSE 0 END) AS TotalCredits,
        SUM(CASE WHEN TransactionType IN ('Withdrawal', 'Transfer-Out', 'Fee') THEN Amount ELSE 0 END) AS TotalDebits,
        SUM(CASE WHEN TransactionType IN ('Deposit', 'Transfer-In', 'Interest') THEN Amount ELSE 0 END) -
        SUM(CASE WHEN TransactionType IN ('Withdrawal', 'Transfer-Out', 'Fee') THEN Amount ELSE 0 END) AS NetChange
    FROM Transactions
    WHERE AccountID = @AccountID
      AND CAST(TransactionDate AS DATE) BETWEEN @FromDate AND @ToDate;
END
GO

-- =============================================
-- STORED PROCEDURE 6: Daily Transaction Summary
-- =============================================
CREATE PROCEDURE sp_GetDailySummary
    @SummaryDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to today
    IF @SummaryDate IS NULL
        SET @SummaryDate = CAST(GETDATE() AS DATE);
    
    PRINT '=== Daily Transaction Summary for ' + CAST(@SummaryDate AS NVARCHAR(20)) + ' ===';
    
    -- Overall summary
    SELECT 
        @SummaryDate AS SummaryDate,
        COUNT(DISTINCT AccountID) AS ActiveAccounts,
        COUNT(*) AS TotalTransactions,
        SUM(CASE WHEN TransactionType IN ('Deposit', 'Transfer-In', 'Interest') THEN Amount ELSE 0 END) AS TotalCredits,
        SUM(CASE WHEN TransactionType IN ('Withdrawal', 'Transfer-Out', 'Fee') THEN Amount ELSE 0 END) AS TotalDebits,
        SUM(CASE WHEN TransactionType IN ('Deposit', 'Transfer-In', 'Interest') THEN Amount ELSE 0 END) -
        SUM(CASE WHEN TransactionType IN ('Withdrawal', 'Transfer-Out', 'Fee') THEN Amount ELSE 0 END) AS NetCashFlow
    FROM Transactions
    WHERE CAST(TransactionDate AS DATE) = @SummaryDate;
    
    -- By transaction type
    SELECT 
        TransactionType,
        COUNT(*) AS TransactionCount,
        SUM(Amount) AS TotalAmount,
        AVG(Amount) AS AverageAmount,
        MIN(Amount) AS MinAmount,
        MAX(Amount) AS MaxAmount
    FROM Transactions
    WHERE CAST(TransactionDate AS DATE) = @SummaryDate
    GROUP BY TransactionType
    ORDER BY TotalAmount DESC;
    
    -- Hourly distribution
    SELECT 
        DATEPART(HOUR, TransactionDate) AS Hour,
        COUNT(*) AS TransactionCount,
        SUM(Amount) AS TotalAmount
    FROM Transactions
    WHERE CAST(TransactionDate AS DATE) = @SummaryDate
    GROUP BY DATEPART(HOUR, TransactionDate)
    ORDER BY Hour;
    
    -- Top 5 accounts by transaction volume
    SELECT TOP 5
        a.AccountNumber,
        a.HolderName,
        COUNT(t.TransactionID) AS TransactionCount,
        SUM(t.Amount) AS TotalVolume
    FROM Transactions t
    INNER JOIN Accounts a ON t.AccountID = a.AccountID
    WHERE CAST(t.TransactionDate AS DATE) = @SummaryDate
    GROUP BY a.AccountNumber, a.HolderName
    ORDER BY TotalVolume DESC;
END
GO

-- =============================================
-- VIEWS CREATION
-- =============================================

-- =============================================
-- VIEW 1: Account Summary View
-- =============================================
CREATE VIEW vw_AccountSummary AS
SELECT 
    a.AccountID,
    a.AccountNumber,
    a.HolderName,
    at.TypeName AS AccountType,
    a.Balance,
    a.Status,
    a.OpeningDate,
    DATEDIFF(DAY, a.OpeningDate, GETDATE()) AS AccountAge,
    COUNT(t.TransactionID) AS TotalTransactions,
    MAX(t.TransactionDate) AS LastTransactionDate,
    SUM(CASE WHEN t.TransactionType IN ('Deposit', 'Transfer-In', 'Interest') THEN t.Amount ELSE 0 END) AS TotalCredits,
    SUM(CASE WHEN t.TransactionType IN ('Withdrawal', 'Transfer-Out', 'Fee') THEN t.Amount ELSE 0 END) AS TotalDebits,
    a.Email,
    a.PhoneNumber,
    a.BranchCode
FROM Accounts a
LEFT JOIN AccountTypes at ON a.AccountTypeID = at.AccountTypeID
LEFT JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY a.AccountID, a.AccountNumber, a.HolderName, at.TypeName, a.Balance, 
         a.Status, a.OpeningDate, a.Email, a.PhoneNumber, a.BranchCode;
GO

-- =============================================
-- VIEW 2: Daily Transaction Summary View
-- =============================================
CREATE VIEW vw_DailyTransactionSummary AS
SELECT 
    CAST(TransactionDate AS DATE) AS TransactionDate,
    COUNT(*) AS TotalTransactions,
    COUNT(DISTINCT AccountID) AS UniqueAccounts,
    SUM(CASE WHEN TransactionType IN ('Deposit', 'Transfer-In', 'Interest') THEN Amount ELSE 0 END) AS TotalCredits,
    SUM(CASE WHEN TransactionType IN ('Withdrawal', 'Transfer-Out', 'Fee') THEN Amount ELSE 0 END) AS TotalDebits,
    SUM(CASE WHEN TransactionType = 'Deposit' THEN Amount ELSE 0 END) AS DepositAmount,
    SUM(CASE WHEN TransactionType = 'Withdrawal' THEN Amount ELSE 0 END) AS WithdrawalAmount,
    SUM(CASE WHEN TransactionType IN ('Transfer-In', 'Transfer-Out') THEN Amount ELSE 0 END) AS TransferAmount,
    SUM(CASE WHEN TransactionType = 'Interest' THEN Amount ELSE 0 END) AS InterestAmount
FROM Transactions
WHERE Status = 'Completed'
GROUP BY CAST(TransactionDate AS DATE);
GO

-- =============================================
-- VIEW 3: Suspicious Transactions View
-- =============================================
CREATE VIEW vw_SuspiciousTransactions AS
SELECT 
    sa.AlertID,
    sa.AlertDate,
    sa.AlertType,
    a.AccountNumber,
    a.HolderName,
    t.TransactionNumber,
    t.TransactionType,
    sa.Amount,
    t.TransactionDate,
    t.Description AS TransactionDescription,
    sa.Description AS AlertDescription,
    sa.Reviewed,
    sa.ReviewedBy,
    sa.ReviewedDate,
    sa.Resolution,
    DATEDIFF(HOUR, sa.AlertDate, GETDATE()) AS HoursSinceAlert
FROM SuspiciousActivity sa
INNER JOIN Accounts a ON sa.AccountID = a.AccountID
LEFT JOIN Transactions t ON sa.TransactionID = t.TransactionID;
GO

-- =============================================
-- DEMONSTRATE ALL FEATURES
-- =============================================

PRINT '=============================================================';
PRINT '=== BANKING SYSTEM - DEMONSTRATION ===';
PRINT '=============================================================';
PRINT '';

-- =============================================
-- DEMO 1: View Account Summary
-- =============================================
PRINT '=== DEMO 1: Account Summary ===';
SELECT TOP 5 * FROM vw_AccountSummary ORDER BY Balance DESC;
PRINT '';
GO

-- =============================================
-- DEMO 2: Daily Summary for Today (2025-11-20)
-- =============================================
PRINT '=== DEMO 2: Daily Transaction Summary ===';
EXEC sp_GetDailySummary @SummaryDate = '2025-11-20';
PRINT '';
GO

-- =============================================
-- DEMO 3: View Daily Summary from View
-- =============================================
PRINT '=== DEMO 3: Daily Summary from View ===';
SELECT * FROM vw_DailyTransactionSummary ORDER BY TransactionDate DESC;
PRINT '';
GO

-- =============================================
-- DEMO 4: Suspicious Transactions Report
-- =============================================
PRINT '=== DEMO 4: Suspicious Transactions (> 1 Lakh) ===';
SELECT 
    AlertDate,
    AlertType,
    AccountNumber,
    HolderName,
    TransactionNumber,
    TransactionType,
    Amount,
    AlertDescription,
    Reviewed
FROM vw_SuspiciousTransactions
WHERE Reviewed = 0
ORDER BY Amount DESC;
PRINT '';
GO

-- =============================================
-- DEMO 5: Account Statement
-- =============================================
PRINT '=== DEMO 5: Account Statement for Rajesh Kumar ===';
EXEC sp_GetAccountStatement 
    @AccountNumber = 'ACC001234567890',
    @FromDate = '2025-11-01',
    @ToDate = '2025-11-20';
PRINT '';
GO

-- =============================================
-- DEMO 6: Perform Deposit Transaction
-- =============================================
PRINT '=== DEMO 6: Deposit Transaction ===';
EXEC sp_Deposit 
    @AccountNumber = 'ACC001234567896',
    @Amount = 5000.00,
    @Description = 'Cash deposit at branch',
    @ReferenceNumber = 'REF12345';
PRINT '';
GO

-- =============================================
-- DEMO 7: Perform Withdrawal Transaction
-- =============================================
PRINT '=== DEMO 7: Withdrawal Transaction ===';
EXEC sp_Withdraw 
    @AccountNumber = 'ACC001234567891',
    @Amount = 3000.00,
    @Description = 'ATM withdrawal',
    @ReferenceNumber = 'ATM67890';
PRINT '';
GO

-- =============================================
-- DEMO 8: Perform Transfer Transaction
-- =============================================
PRINT '=== DEMO 8: Fund Transfer ===';
EXEC sp_Transfer 
    @FromAccountNumber = 'ACC001234567892',
    @ToAccountNumber = 'ACC001234567893',
    @Amount = 25000.00,
    @Description = 'Business payment',
    @ReferenceNumber = 'TRANS2025';
PRINT '';
GO

-- =============================================
-- DEMO 9: Monthly Interest Credit
-- =============================================
PRINT '=== DEMO 9: Monthly Interest Credit ===';
EXEC sp_MonthlyInterestCredit 
    @ProcessMonth = 11,
    @ProcessYear = 2025;
PRINT '';
GO

-- =============================================
-- DEMO 10: Test Large Transaction (Suspicious)
-- =============================================
PRINT '=== DEMO 10: Large Transaction (Should Trigger Alert) ===';
EXEC sp_Deposit 
    @AccountNumber = 'ACC001234567892',
    @Amount = 150000.00,
    @Description = 'Large business deposit - Should trigger suspicious activity alert',
    @ReferenceNumber = 'LARGE001';
PRINT '';

-- Check if alert was created
SELECT TOP 5 * FROM vw_SuspiciousTransactions ORDER BY AlertDate DESC;
PRINT '';
GO

-- =============================================
-- DEMO 11: Audit Log Review
-- =============================================
PRINT '=== DEMO 11: Recent Audit Log ===';
SELECT TOP 10 
    AuditID,
    TableName,
    Operation,
    ModifiedBy,
    ModifiedDate,
    LEFT(OldValue, 50) + '...' AS OldValue,
    LEFT(NewValue, 50) + '...' AS NewValue
FROM AuditLog
ORDER BY ModifiedDate DESC;
PRINT '';
GO

-- =============================================
-- DEMO 12: Test Insufficient Balance
-- =============================================
PRINT '=== DEMO 12: Test Insufficient Balance (Should Fail) ===';
BEGIN TRY
    EXEC sp_Withdraw 
        @AccountNumber = 'ACC001234567896',
        @Amount = 500000.00,
        @Description = 'This should fail - Insufficient balance';
END TRY
BEGIN CATCH
    PRINT 'Expected Error: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO

-- =============================================
-- FINAL SUMMARY
-- =============================================
PRINT '=============================================================';
PRINT '=== BANKING SYSTEM SETUP COMPLETE ===';
PRINT '=============================================================';
PRINT '';
PRINT 'Database: BankingSystemDB';
PRINT '';
PRINT 'TABLES CREATED:';
PRINT '  - AccountTypes (4 types)';
PRINT '  - Accounts (8 accounts with sample data)';
PRINT '  - Transactions (with historical and today''s data)';
PRINT '  - SuspiciousActivity (fraud detection)';
PRINT '  - AuditLog (change tracking)';
PRINT '';
PRINT 'STORED PROCEDURES:';
PRINT '  1. sp_Deposit - Deposit money with validation';
PRINT '  2. sp_Withdraw - Withdraw money with balance check';
PRINT '  3. sp_Transfer - Transfer between accounts';
PRINT '  4. sp_MonthlyInterestCredit - Automated interest calculation';
PRINT '  5. sp_GetAccountStatement - Generate detailed statement';
PRINT '  6. sp_GetDailySummary - Daily transaction report';
PRINT '';
PRINT 'TRIGGERS:';
PRINT '  1. trg_ValidateTransaction - Validate before insert';
PRINT '  2. trg_UpdateAccountBalance - Auto-update balance';
PRINT '  3. trg_DetectSuspiciousActivity - Fraud detection (>1 Lakh)';
PRINT '  4. trg_AuditAccountChanges - Track all changes';
PRINT '';
PRINT 'VIEWS:';
PRINT '  1. vw_AccountSummary - Complete account overview';
PRINT '  2. vw_DailyTransactionSummary - Daily credits/debits';
PRINT '  3. vw_SuspiciousTransactions - Fraud monitoring';
PRINT '';
PRINT 'SKILLS DEMONSTRATED:';
PRINT '  ? BEGIN TRANSACTION / COMMIT / ROLLBACK';
PRINT '  ? Stored Procedures with parameters';
PRINT '  ? INSTEAD OF and AFTER Triggers';
PRINT '  ? TRY-CATCH error handling';
PRINT '  ? Cursors for batch processing';
PRINT '  ? Dynamic SQL generation';
PRINT '  ? CTEs and Subqueries';
PRINT '  ? Window Functions';
PRINT '  ? Constraints and Validations';
PRINT '  ? Audit Trail Implementation';
PRINT '  ? Fraud Detection Logic';
PRINT '';
PRINT '=== All demonstrations completed successfully! ===';
PRINT '=============================================================';
GO