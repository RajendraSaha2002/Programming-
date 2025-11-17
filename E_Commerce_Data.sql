/*
================================================================================
E-Commerce Order Processing System - Microsoft SQL Server Script
================================================================================
This script creates the full schema, populates it with sample data,
and implements stored procedures and triggers as requested.

Sections:
1. Database & Schema Creation
2. Sample Data Insertion
3. Stored Procedures (Reports & Tasks)
4. Triggers (Inventory Management)
5. Demonstration
================================================================================
*/

-- Use master to check/create the database
USE master;
GO

-- Create the database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MiniEcommerceDB')
BEGIN
    CREATE DATABASE MiniEcommerceDB;
END
GO

-- Switch to the newly created database
USE MiniEcommerceDB;
GO

/*
================================================================================
1. DATABASE & SCHEMA CREATION
   - Dropping tables in reverse order of creation to handle foreign keys
   - Creating the 5 core tables
================================================================================
*/

-- Drop existing tables if they exist
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS OrderItems;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;
GO

-- Table: Customers
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Address NVARCHAR(255),
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Table: Products
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Price DECIMAL(10, 2) NOT NULL CHECK (Price >= 0),
    StockQuantity INT NOT NULL CHECK (StockQuantity >= 0)
);
GO

-- Table: Orders
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL REFERENCES Customers(CustomerID),
    OrderDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending' 
        CHECK (Status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')),
    TotalAmount DECIMAL(10, 2)
);
GO

-- Table: OrderItems (The "bridge" table)
CREATE TABLE OrderItems (
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL REFERENCES Orders(OrderID),
    ProductID INT NOT NULL REFERENCES Products(ProductID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10, 2) NOT NULL -- Price at the time of purchase
);
GO

-- Table: Payments
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL REFERENCES Orders(OrderID),
    PaymentDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentMethod NVARCHAR(50) CHECK (PaymentMethod IN ('Credit Card', 'PayPal', 'Bank Transfer')),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Completed' 
        CHECK (Status IN ('Pending', 'Completed', 'Failed'))
);
GO

PRINT 'Section 1: Database and Schema created successfully.';
GO

/*
================================================================================
2. SAMPLE DATA INSERTION
   - Populating tables with realistic data for reports
================================================================================
*/

BEGIN TRANSACTION;
PRINT 'Inserting sample data...';

-- Insert Customers
INSERT INTO Customers (FirstName, LastName, Email, Address)
VALUES
('Alice', 'Smith', 'alice.smith@email.com', '123 Main St, Anytown, USA'),
('Bob', 'Johnson', 'bob.johnson@email.com', '456 Oak Ave, Othertown, USA'),
('Charlie', 'Brown', 'charlie.brown@email.com', '789 Pine Ln, Sometown, USA'),
('David', 'Lee', 'david.lee@email.com', '101 Maple Dr, Yourtown, USA');

-- Insert Products
INSERT INTO Products (ProductName, Description, Price, StockQuantity)
VALUES
('Laptop Pro 15"', 'High-performance laptop with 16GB RAM, 1TB SSD', 1299.00, 50),
('Wireless Mouse', 'Ergonomic wireless mouse with 5 buttons', 25.50, 200),
('Mechanical Keyboard', 'RGB backlit mechanical keyboard with blue switches', 89.99, 150),
('4K Monitor 27"', 'UHD 27-inch monitor with HDR support', 499.99, 75),
('USB-C Hub', '7-in-1 USB-C hub with HDMI, SD card reader', 39.99, 300);

-- Insert Orders (with varied dates and statuses)
-- Note: TotalAmount will be updated after OrderItems are inserted.
INSERT INTO Orders (CustomerID, OrderDate, Status)
VALUES
(1, '2025-10-10 09:30:00', 'Shipped'),    -- Order 1
(2, '2025-10-11 14:45:00', 'Processing'), -- Order 2
(1, '2025-11-01 11:15:00', 'Pending'),    -- Order 3
(3, '2025-11-02 16:00:00', 'Shipped'),    -- Order 4
(4, '2025-11-03 10:00:00', 'Pending');    -- Order 5

-- Insert OrderItems
-- Order 1 (Laptop)
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (1, 1, 1, 1299.00); 

-- Order 2 (Mouse + Keyboard)
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (2, 2, 1, 25.50), (2, 3, 1, 89.99);

-- Order 3 (Monitor + USB Hub)
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (3, 4, 1, 499.99), (3, 5, 2, 39.99);

-- Order 4 (Keyboard x2)
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (4, 3, 2, 89.99);

-- Order 5 (Laptop + Mouse)
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (5, 1, 1, 1299.00), (5, 2, 1, 25.50);

-- Update Order TotalAmount based on OrderItems
UPDATE Orders SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM OrderItems WHERE OrderID = 1) WHERE OrderID = 1;
UPDATE Orders SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM OrderItems WHERE OrderID = 2) WHERE OrderID = 2;
UPDATE Orders SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM OrderItems WHERE OrderID = 3) WHERE OrderID = 3;
UPDATE Orders SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM OrderItems WHERE OrderID = 4) WHERE OrderID = 4;
UPDATE Orders SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM OrderItems WHERE OrderID = 5) WHERE OrderID = 5;

-- Insert Payments
-- Note: Assuming payments are made for orders that are not pending
INSERT INTO Payments (OrderID, PaymentDate, Amount, PaymentMethod, Status)
VALUES
(1, '2025-10-10 09:31:00', 1299.00, 'Credit Card', 'Completed'),
(2, '2025-10-11 14:46:00', 115.49, 'PayPal', 'Completed'),
(4, '2025-11-02 16:01:00', 179.98, 'Credit Card', 'Completed');

COMMIT TRANSACTION;
PRINT 'Section 2: Sample data inserted successfully.';
GO

/*
================================================================================
3. STORED PROCEDURES (Reports & Tasks)
   - sp_GetSalesReport (Daily/Monthly)
   - sp_GetBestSellingProducts
   - sp_GetTopSpendingCustomers (Uses CTE + Window Function)
   - sp_GetPendingOrders
================================================================================
*/

-- Procedure: Daily/Monthly Sales Report
CREATE OR ALTER PROCEDURE sp_GetSalesReport
    @ReportType NVARCHAR(10) -- 'Daily' or 'Monthly'
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportType = 'Daily'
    BEGIN
        SELECT
            CONVERT(date, o.OrderDate) AS ReportDate,
            SUM(oi.Quantity * oi.UnitPrice) AS TotalSales,
            COUNT(DISTINCT o.OrderID) AS TotalOrders,
            SUM(oi.Quantity) AS TotalItemsSold
        FROM Orders o
        JOIN OrderItems oi ON o.OrderID = oi.OrderID
        WHERE o.Status IN ('Shipped', 'Delivered') -- Only count completed sales
        GROUP BY CONVERT(date, o.OrderDate)
        ORDER BY ReportDate DESC;
    END
    ELSE IF @ReportType = 'Monthly'
    BEGIN
        SELECT
            FORMAT(o.OrderDate, 'yyyy-MM') AS ReportMonth,
            SUM(oi.Quantity * oi.UnitPrice) AS TotalSales,
            COUNT(DISTINCT o.OrderID) AS TotalOrders,
            SUM(oi.Quantity) AS TotalItemsSold
        FROM Orders o
        JOIN OrderItems oi ON o.OrderID = oi.OrderID
        WHERE o.Status IN ('Shipped', 'Delivered')
        GROUP BY FORMAT(o.OrderDate, 'yyyy-MM')
        ORDER BY ReportMonth DESC;
    END
    ELSE
    BEGIN
        PRINT 'Invalid report type. Please use ''Daily'' or ''Monthly''.';
    END
END
GO

-- Procedure: Best-Selling Products
CREATE OR ALTER PROCEDURE sp_GetBestSellingProducts
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopN)
        p.ProductName,
        SUM(oi.Quantity) AS TotalUnitsSold,
        SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue
    FROM Products p
    JOIN OrderItems oi ON p.ProductID = oi.ProductID
    JOIN Orders o ON oi.OrderID = o.OrderID
    WHERE o.Status IN ('Shipped', 'Delivered')
    GROUP BY p.ProductName
    ORDER BY TotalRevenue DESC;
END
GO

-- Procedure: Customers with Highest Spending (CTE + Window Function)
CREATE OR ALTER PROCEDURE sp_GetTopSpendingCustomers
    @TopN INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    -- Use a Common Table Expression (CTE) to get total spending per customer
    WITH CustomerSpending AS (
        SELECT
            c.CustomerID,
            c.FirstName,
            c.LastName,
            c.Email,
            SUM(o.TotalAmount) AS TotalSpent
        FROM Customers c
        JOIN Orders o ON c.CustomerID = o.CustomerID
        WHERE o.Status IN ('Shipped', 'Delivered') -- Count only completed/paid orders
        GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email
    ),
    -- Use a second CTE to apply a Window Function (RANK)
    RankedCustomers AS (
        SELECT
            CustomerID,
            FirstName,
            LastName,
            Email,
            TotalSpent,
            RANK() OVER (ORDER BY TotalSpent DESC) AS SpendingRank
        FROM CustomerSpending
    )
    -- Select from the final ranked CTE
    SELECT
        SpendingRank,
        FirstName,
        LastName,
        Email,
        TotalSpent
    FROM RankedCustomers
    WHERE SpendingRank <= @TopN
    ORDER BY SpendingRank ASC;
END
GO

-- Procedure: Pending Orders
CREATE OR ALTER PROCEDURE sp_GetPendingOrders
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderID,
        o.OrderDate,
        c.FirstName,
        c.LastName,
        c.Email,
        o.TotalAmount,
        o.Status
    FROM Orders o
    JOIN Customers c ON o.CustomerID = c.CustomerID
    WHERE o.Status IN ('Pending', 'Processing')
    ORDER BY o.OrderDate ASC;
END
GO

PRINT 'Section 3: Stored Procedures created successfully.';
GO

/*
================================================================================
4. TRIGGERS (Inventory Management)
   - Automatically updates product stock when an order status changes.
================================================================================
*/

CREATE OR ALTER TRIGGER tr_UpdateInventoryOnOrderStatus
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Scenario 1: Order is Shipped or Processing (Subtract from stock)
    -- We check if the status *changed* to Shipped/Processing from something else.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.Status IN ('Processing', 'Shipped') 
          AND d.Status NOT IN ('Processing', 'Shipped')
    )
    BEGIN
        UPDATE p
        SET p.StockQuantity = p.StockQuantity - oi.Quantity
        FROM Products p
        JOIN OrderItems oi ON p.ProductID = oi.ProductID
        JOIN inserted i ON oi.OrderID = i.OrderID
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.Status IN ('Processing', 'Shipped')
          AND d.Status NOT IN ('Processing', 'Shipped');
        
        PRINT 'Trigger: Stock quantity decreased for processed/shipped order(s).';
    END

    -- Scenario 2: Order is Cancelled (Add back to stock)
    -- We check if the status *changed* to Cancelled from something else.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.Status = 'Cancelled' AND d.Status != 'Cancelled'
    )
    BEGIN
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + oi.Quantity
        FROM Products p
        JOIN OrderItems oi ON p.ProductID = oi.ProductID
        JOIN inserted i ON oi.OrderID = i.OrderID
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.Status = 'Cancelled' AND d.Status != 'Cancelled'
          AND d.Status IN ('Pending', 'Processing'); -- Only restock if it was deducted or pending
        
        PRINT 'Trigger: Stock quantity restocked for cancelled order(s).';
    END
END
GO

PRINT 'Section 4: Inventory trigger created successfully.';
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

-- Show initial stock for items in Order 2 (Mouse, Keyboard)
PRINT '--- Initial Stock (Products 2 & 3) ---';
SELECT ProductID, ProductName, StockQuantity FROM Products WHERE ProductID IN (2, 3);
GO

-- Show pending orders
PRINT '--- Report: Pending Orders (Initial) ---';
EXEC sp_GetPendingOrders;
GO

-- Now, update Order 2 status from 'Processing' to 'Shipped'
-- This will fire the trigger 'tr_UpdateInventoryOnOrderStatus'
PRINT '--- Action: Updating Order 2 to ''Shipped'' (Fires Trigger) ---';
UPDATE Orders SET Status = 'Shipped' WHERE OrderID = 2;
GO

-- Show the stock has been updated
PRINT '--- Stock After Update (Products 2 & 3) ---';
SELECT ProductID, ProductName, StockQuantity FROM Products WHERE ProductID IN (2, 3);
GO

-- Show that Order 2 is no longer pending
PRINT '--- Report: Pending Orders (After Update) ---';
EXEC sp_GetPendingOrders;
GO

-- Run the other reports
PRINT '--- Report: Daily Sales ---';
EXEC sp_GetSalesReport @ReportType = 'Daily';
GO

PRINT '--- Report: Monthly Sales ---';
EXEC sp_GetSalesReport @ReportType = 'Monthly';
GO

PRINT '--- Report: Top 3 Best-Selling Products ---';
EXEC sp_GetBestSellingProducts @TopN = 3;
GO

PRINT '--- Report: Top 3 Spending Customers (CTE/Window Function Demo) ---';
EXEC sp_GetTopSpendingCustomers @TopN = 3;
GO

PRINT '========================================';
PRINT 'DEMONSTRATION COMPLETE.';
PRINT '========================================';