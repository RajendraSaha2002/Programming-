-- =============================================
-- E-Commerce Sales Analytics Dashboard
-- Complete System with Graph-Ready Queries
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ECommerceDashboardDB')
BEGIN
    CREATE DATABASE ECommerceDashboardDB;
END
GO

USE ECommerceDashboardDB;
GO

-- =============================================
-- DROP EXISTING OBJECTS (IF ANY)
-- =============================================

-- Drop stored procedures
IF OBJECT_ID('sp_GetDailySalesLineChart', 'P') IS NOT NULL DROP PROCEDURE sp_GetDailySalesLineChart;
IF OBJECT_ID('sp_GetMonthlyRevenueBarChart', 'P') IS NOT NULL DROP PROCEDURE sp_GetMonthlyRevenueBarChart;
IF OBJECT_ID('sp_GetBestSellingProductsPieChart', 'P') IS NOT NULL DROP PROCEDURE sp_GetBestSellingProductsPieChart;
IF OBJECT_ID('sp_GetCustomerGrowthTrend', 'P') IS NOT NULL DROP PROCEDURE sp_GetCustomerGrowthTrend;
IF OBJECT_ID('sp_GetTop10CustomersBarChart', 'P') IS NOT NULL DROP PROCEDURE sp_GetTop10CustomersBarChart;
IF OBJECT_ID('sp_GetOrderStatusDonutChart', 'P') IS NOT NULL DROP PROCEDURE sp_GetOrderStatusDonutChart;
IF OBJECT_ID('sp_GetCompleteDashboard', 'P') IS NOT NULL DROP PROCEDURE sp_GetCompleteDashboard;
GO

-- Drop views
IF OBJECT_ID('vw_SalesOverview', 'V') IS NOT NULL DROP VIEW vw_SalesOverview;
IF OBJECT_ID('vw_ProductPerformance', 'V') IS NOT NULL DROP VIEW vw_ProductPerformance;
IF OBJECT_ID('vw_CustomerInsights', 'V') IS NOT NULL DROP VIEW vw_CustomerInsights;
GO

-- Drop tables
IF OBJECT_ID('Payments', 'U') IS NOT NULL DROP TABLE Payments;
IF OBJECT_ID('OrderItems', 'U') IS NOT NULL DROP TABLE OrderItems;
IF OBJECT_ID('Orders', 'U') IS NOT NULL DROP TABLE Orders;
IF OBJECT_ID('Products', 'U') IS NOT NULL DROP TABLE Products;
IF OBJECT_ID('Categories', 'U') IS NOT NULL DROP TABLE Categories;
IF OBJECT_ID('Customers', 'U') IS NOT NULL DROP TABLE Customers;
GO

-- =============================================
-- CREATE TABLES
-- =============================================

-- Table: Customers
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1001,1),
    CustomerCode NVARCHAR(20) UNIQUE NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber NVARCHAR(15),
    City NVARCHAR(50),
    State NVARCHAR(50),
    Country NVARCHAR(50) DEFAULT 'India',
    PostalCode NVARCHAR(10),
    RegistrationDate DATETIME DEFAULT GETDATE(),
    LastPurchaseDate DATETIME,
    TotalPurchases INT DEFAULT 0,
    TotalSpent DECIMAL(15,2) DEFAULT 0,
    CustomerTier NVARCHAR(20) CHECK (CustomerTier IN ('Bronze', 'Silver', 'Gold', 'Platinum')) DEFAULT 'Bronze',
    IsActive BIT DEFAULT 1,
    CreatedBy NVARCHAR(50) DEFAULT 'RajendraSaha2002',
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

-- Table: Categories
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

-- Table: Products
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(2001,1),
    ProductCode NVARCHAR(20) UNIQUE NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID),
    Description NVARCHAR(1000),
    UnitPrice DECIMAL(12,2) NOT NULL CHECK (UnitPrice >= 0),
    CostPrice DECIMAL(12,2) NOT NULL CHECK (CostPrice >= 0),
    StockQuantity INT DEFAULT 0 CHECK (StockQuantity >= 0),
    ReorderLevel INT DEFAULT 10,
    Brand NVARCHAR(100),
    SKU NVARCHAR(50),
    Weight DECIMAL(8,2), -- in kg
    IsActive BIT DEFAULT 1,
    CreatedBy NVARCHAR(50) DEFAULT 'RajendraSaha2002',
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Table: Orders
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(5001,1),
    OrderNumber NVARCHAR(30) UNIQUE NOT NULL,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate DATETIME DEFAULT GETDATE(),
    ShippingDate DATETIME,
    DeliveryDate DATETIME,
    OrderStatus NVARCHAR(20) CHECK (OrderStatus IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Returned')) DEFAULT 'Pending',
    PaymentStatus NVARCHAR(20) CHECK (PaymentStatus IN ('Pending', 'Paid', 'Failed', 'Refunded')) DEFAULT 'Pending',
    SubTotal DECIMAL(15,2) NOT NULL DEFAULT 0,
    TaxAmount DECIMAL(15,2) DEFAULT 0,
    ShippingCharges DECIMAL(10,2) DEFAULT 0,
    DiscountAmount DECIMAL(10,2) DEFAULT 0,
    TotalAmount DECIMAL(15,2) NOT NULL DEFAULT 0,
    ShippingAddress NVARCHAR(500),
    BillingAddress NVARCHAR(500),
    Notes NVARCHAR(1000),
    CreatedBy NVARCHAR(50) DEFAULT 'RajendraSaha2002',
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Table: OrderItems
CREATE TABLE OrderItems (
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(12,2) NOT NULL,
    Discount DECIMAL(10,2) DEFAULT 0,
    TaxRate DECIMAL(5,2) DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice - Discount) PERSISTED,
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

-- Table: Payments
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    PaymentDate DATETIME DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(50) CHECK (PaymentMethod IN ('Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Cash on Delivery', 'Wallet')) NOT NULL,
    PaymentAmount DECIMAL(15,2) NOT NULL,
    TransactionID NVARCHAR(100) UNIQUE,
    PaymentStatus NVARCHAR(20) CHECK (PaymentStatus IN ('Success', 'Failed', 'Pending', 'Refunded')) DEFAULT 'Success',
    PaymentGateway NVARCHAR(50),
    Remarks NVARCHAR(500),
    CreatedBy NVARCHAR(50) DEFAULT 'RajendraSaha2002',
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

-- Insert Categories
INSERT INTO Categories (CategoryName, Description)
VALUES 
    ('Electronics', 'Electronic devices and gadgets'),
    ('Clothing', 'Apparel and fashion items'),
    ('Books', 'Physical and digital books'),
    ('Home & Kitchen', 'Home appliances and kitchen items'),
    ('Sports & Fitness', 'Sports equipment and fitness gear'),
    ('Beauty & Personal Care', 'Cosmetics and personal care products'),
    ('Toys & Games', 'Toys and gaming items'),
    ('Furniture', 'Home and office furniture');
GO

-- Insert Products
INSERT INTO Products (ProductCode, ProductName, CategoryID, UnitPrice, CostPrice, StockQuantity, Brand, SKU)
VALUES 
    ('PROD001', 'Samsung Galaxy S24 Ultra', 1, 124999.00, 95000.00, 50, 'Samsung', 'SAM-S24U-BLK'),
    ('PROD002', 'Apple iPhone 15 Pro', 1, 134900.00, 105000.00, 30, 'Apple', 'APL-IP15P-BLU'),
    ('PROD003', 'Sony WH-1000XM5 Headphones', 1, 29990.00, 22000.00, 100, 'Sony', 'SNY-WH1000-BLK'),
    ('PROD004', 'Dell XPS 15 Laptop', 1, 159999.00, 125000.00, 25, 'Dell', 'DEL-XPS15-SLV'),
    ('PROD005', 'Levi''s Men Jeans', 2, 2999.00, 1800.00, 200, 'Levis', 'LEV-JNS-BLU-32'),
    ('PROD006', 'Nike Running Shoes', 2, 6499.00, 4500.00, 150, 'Nike', 'NIK-RUN-BLK-9'),
    ('PROD007', 'Atomic Habits Book', 3, 599.00, 350.00, 500, 'Penguin', 'PEN-ATM-HBT'),
    ('PROD008', 'The Psychology of Money', 3, 450.00, 280.00, 300, 'Jaico', 'JAI-PSY-MNY'),
    ('PROD009', 'Prestige Induction Cooktop', 4, 3299.00, 2200.00, 80, 'Prestige', 'PRS-IND-2000'),
    ('PROD010', 'Philips Air Fryer', 4, 8999.00, 6500.00, 60, 'Philips', 'PHL-AF-XL'),
    ('PROD011', 'Yoga Mat Premium', 5, 1299.00, 800.00, 120, 'Lifelong', 'LFL-YOG-PRM'),
    ('PROD012', 'Dumbbells Set 20kg', 5, 2499.00, 1600.00, 70, 'Kore', 'KOR-DB-20KG'),
    ('PROD013', 'Lakme Makeup Kit', 6, 1599.00, 1000.00, 200, 'Lakme', 'LAK-MKP-KIT'),
    ('PROD014', 'Nivea Body Lotion', 6, 299.00, 180.00, 350, 'Nivea', 'NIV-BDY-400ML'),
    ('PROD015', 'LEGO City Building Set', 7, 4999.00, 3500.00, 90, 'LEGO', 'LEG-CTY-SET'),
    ('PROD016', 'PlayStation 5 Console', 1, 54990.00, 45000.00, 20, 'Sony', 'SNY-PS5-STD'),
    ('PROD017', 'Office Chair Ergonomic', 8, 12999.00, 9000.00, 40, 'Featherlite', 'FTL-CHR-ERG'),
    ('PROD018', 'Study Table Wooden', 8, 8999.00, 6500.00, 35, 'Woodness', 'WDN-TBL-STD'),
    ('PROD019', 'Fire-Boltt Smart Watch', 1, 2499.00, 1500.00, 180, 'Fire-Boltt', 'FRB-SMT-BLK'),
    ('PROD020', 'boAt Earbuds', 1, 1299.00, 800.00, 250, 'boAt', 'BOT-ERB-131');
GO

-- Insert Customers (20 customers)
INSERT INTO Customers (CustomerCode, FirstName, LastName, Email, PhoneNumber, City, State, RegistrationDate, CustomerTier)
VALUES 
    ('CUST001', 'Rajendra', 'Saha', 'rajendra.saha@email.com', '9876543210', 'Bangalore', 'Karnataka', '2024-01-15', 'Platinum'),
    ('CUST002', 'Priya', 'Sharma', 'priya.sharma@email.com', '9876543211', 'Mumbai', 'Maharashtra', '2024-02-20', 'Gold'),
    ('CUST003', 'Amit', 'Patel', 'amit.patel@email.com', '9876543212', 'Ahmedabad', 'Gujarat', '2024-03-10', 'Gold'),
    ('CUST004', 'Sneha', 'Reddy', 'sneha.reddy@email.com', '9876543213', 'Hyderabad', 'Telangana', '2024-04-05', 'Silver'),
    ('CUST005', 'Vikram', 'Singh', 'vikram.singh@email.com', '9876543214', 'Delhi', 'Delhi', '2024-05-12', 'Silver'),
    ('CUST006', 'Anita', 'Desai', 'anita.desai@email.com', '9876543215', 'Kolkata', 'West Bengal', '2024-06-18', 'Bronze'),
    ('CUST007', 'Ravi', 'Verma', 'ravi.verma@email.com', '9876543216', 'Chennai', 'Tamil Nadu', '2024-07-22', 'Bronze'),
    ('CUST008', 'Deepika', 'Nair', 'deepika.nair@email.com', '9876543217', 'Kochi', 'Kerala', '2024-08-30', 'Bronze'),
    ('CUST009', 'Rahul', 'Kumar', 'rahul.kumar@email.com', '9876543218', 'Pune', 'Maharashtra', '2024-09-05', 'Silver'),
    ('CUST010', 'Kavita', 'Joshi', 'kavita.joshi@email.com', '9876543219', 'Jaipur', 'Rajasthan', '2024-10-10', 'Bronze'),
    ('CUST011', 'Suresh', 'Gupta', 'suresh.gupta@email.com', '9876543220', 'Lucknow', 'Uttar Pradesh', '2024-10-15', 'Bronze'),
    ('CUST012', 'Neha', 'Mehta', 'neha.mehta@email.com', '9876543221', 'Surat', 'Gujarat', '2024-10-20', 'Bronze'),
    ('CUST013', 'Arjun', 'Malhotra', 'arjun.malhotra@email.com', '9876543222', 'Chandigarh', 'Punjab', '2024-10-25', 'Bronze'),
    ('CUST014', 'Pooja', 'Iyer', 'pooja.iyer@email.com', '9876543223', 'Bangalore', 'Karnataka', '2024-11-01', 'Bronze'),
    ('CUST015', 'Karthik', 'Ramesh', 'karthik.ramesh@email.com', '9876543224', 'Chennai', 'Tamil Nadu', '2024-11-05', 'Bronze'),
    ('CUST016', 'Divya', 'Shah', 'divya.shah@email.com', '9876543225', 'Mumbai', 'Maharashtra', '2024-11-08', 'Bronze'),
    ('CUST017', 'Arun', 'Prasad', 'arun.prasad@email.com', '9876543226', 'Hyderabad', 'Telangana', '2024-11-10', 'Bronze'),
    ('CUST018', 'Meera', 'Pillai', 'meera.pillai@email.com', '9876543227', 'Kochi', 'Kerala', '2024-11-12', 'Bronze'),
    ('CUST019', 'Sanjay', 'Rao', 'sanjay.rao@email.com', '9876543228', 'Bangalore', 'Karnataka', '2024-11-15', 'Bronze'),
    ('CUST020', 'Anjali', 'Kapoor', 'anjali.kapoor@email.com', '9876543229', 'Delhi', 'Delhi', '2024-11-18', 'Bronze');
GO

-- Insert Orders (100+ orders from Oct 1 to Nov 20, 2025)
DECLARE @OrderDate DATETIME = '2025-10-01';
DECLARE @OrderCounter INT = 1;
DECLARE @CustomerID INT;
DECLARE @OrderNumber NVARCHAR(30);
DECLARE @OrderStatus NVARCHAR(20);
DECLARE @PaymentStatus NVARCHAR(20);

WHILE @OrderDate <= '2025-11-20'
BEGIN
    -- Generate 1-3 orders per day
    DECLARE @OrdersPerDay INT = FLOOR(RAND() * 3) + 1;
    DECLARE @DailyOrder INT = 1;
    
    WHILE @DailyOrder <= @OrdersPerDay
    BEGIN
        SET @CustomerID = 1001 + FLOOR(RAND() * 20);
        SET @OrderNumber = 'ORD' + FORMAT(@OrderDate, 'yyyyMMdd') + RIGHT('000' + CAST(@OrderCounter AS NVARCHAR(10)), 3);
        
        -- Determine order status based on date
        SET @OrderStatus = CASE 
            WHEN @OrderDate < '2025-11-15' THEN 'Delivered'
            WHEN @OrderDate < '2025-11-18' THEN 'Shipped'
            WHEN RAND() > 0.8 THEN 'Cancelled'
            WHEN RAND() > 0.5 THEN 'Processing'
            ELSE 'Pending'
        END;
        
        SET @PaymentStatus = CASE 
            WHEN @OrderStatus IN ('Delivered', 'Shipped', 'Processing') THEN 'Paid'
            WHEN @OrderStatus = 'Cancelled' THEN 'Refunded'
            ELSE 'Pending'
        END;
        
        INSERT INTO Orders (OrderNumber, CustomerID, OrderDate, OrderStatus, PaymentStatus, SubTotal, TaxAmount, ShippingCharges, DiscountAmount, TotalAmount)
        VALUES (
            @OrderNumber,
            @CustomerID,
            @OrderDate,
            @OrderStatus,
            @PaymentStatus,
            0, -- Will be updated later
            0,
            FLOOR(RAND() * 100) + 50,
            FLOOR(RAND() * 500),
            0  -- Will be calculated
        );
        
        SET @OrderCounter = @OrderCounter + 1;
        SET @DailyOrder = @DailyOrder + 1;
    END
    
    SET @OrderDate = DATEADD(DAY, 1, @OrderDate);
END
GO

-- Insert Order Items (2-5 items per order)
DECLARE @OrderID INT;
DECLARE @ItemCount INT;
DECLARE @ProductID INT;
DECLARE @Quantity INT;
DECLARE @UnitPrice DECIMAL(12,2);

DECLARE order_cursor CURSOR FOR
SELECT OrderID FROM Orders;

OPEN order_cursor;
FETCH NEXT FROM order_cursor INTO @OrderID;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @ItemCount = FLOOR(RAND() * 4) + 2; -- 2-5 items
    
    DECLARE @Item INT = 1;
    WHILE @Item <= @ItemCount
    BEGIN
        SET @ProductID = 2001 + FLOOR(RAND() * 20);
        SET @Quantity = FLOOR(RAND() * 3) + 1;
        
        SELECT @UnitPrice = UnitPrice FROM Products WHERE ProductID = @ProductID;
        
        INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice, Discount, TaxRate)
        VALUES (
            @OrderID,
            @ProductID,
            @Quantity,
            @UnitPrice,
            FLOOR(RAND() * 500),
            18.00 -- 18% GST
        );
        
        SET @Item = @Item + 1;
    END
    
    FETCH NEXT FROM order_cursor INTO @OrderID;
END

CLOSE order_cursor;
DEALLOCATE order_cursor;
GO

-- Update Order Totals
UPDATE o
SET 
    o.SubTotal = ISNULL(items.TotalAmount, 0),
    o.TaxAmount = ISNULL(items.TotalAmount, 0) * 0.18,
    o.TotalAmount = ISNULL(items.TotalAmount, 0) + (ISNULL(items.TotalAmount, 0) * 0.18) + o.ShippingCharges - o.DiscountAmount
FROM Orders o
CROSS APPLY (
    SELECT SUM(LineTotal) AS TotalAmount
    FROM OrderItems
    WHERE OrderID = o.OrderID
) items;
GO

-- Insert Payments
INSERT INTO Payments (OrderID, PaymentDate, PaymentMethod, PaymentAmount, TransactionID, PaymentStatus, PaymentGateway)
SELECT 
    OrderID,
    OrderDate,
    CASE FLOOR(RAND() * 6)
        WHEN 0 THEN 'Credit Card'
        WHEN 1 THEN 'Debit Card'
        WHEN 2 THEN 'UPI'
        WHEN 3 THEN 'Net Banking'
        WHEN 4 THEN 'Cash on Delivery'
        ELSE 'Wallet'
    END,
    TotalAmount,
    'TXN' + CAST(OrderID AS NVARCHAR(10)) + FORMAT(GETDATE(), 'yyyyMMddHHmmss'),
    CASE PaymentStatus
        WHEN 'Paid' THEN 'Success'
        WHEN 'Refunded' THEN 'Refunded'
        WHEN 'Failed' THEN 'Failed'
        ELSE 'Pending'
    END,
    CASE FLOOR(RAND() * 3)
        WHEN 0 THEN 'Razorpay'
        WHEN 1 THEN 'PayTM'
        ELSE 'PhonePe'
    END
FROM Orders
WHERE PaymentStatus IN ('Paid', 'Refunded');
GO

-- Update Customer Statistics
UPDATE c
SET 
    c.TotalPurchases = stats.OrderCount,
    c.TotalSpent = stats.TotalSpent,
    c.LastPurchaseDate = stats.LastOrder,
    c.CustomerTier = CASE 
        WHEN stats.TotalSpent >= 500000 THEN 'Platinum'
        WHEN stats.TotalSpent >= 200000 THEN 'Gold'
        WHEN stats.TotalSpent >= 50000 THEN 'Silver'
        ELSE 'Bronze'
    END
FROM Customers c
CROSS APPLY (
    SELECT 
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent,
        MAX(OrderDate) AS LastOrder
    FROM Orders
    WHERE CustomerID = c.CustomerID AND OrderStatus != 'Cancelled'
) stats;
GO

-- =============================================
-- GRAPH QUERIES - STORED PROCEDURES
-- =============================================

-- =============================================
-- GRAPH 1: Daily Sales Line Chart
-- X-Axis: Date | Y-Axis: Total Sales
-- =============================================
CREATE PROCEDURE sp_GetDailySalesLineChart
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to last 30 days
    IF @StartDate IS NULL SET @StartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    PRINT '========================================';
    PRINT 'GRAPH TYPE: LINE CHART';
    PRINT 'CHART TITLE: Daily Sales Trend';
    PRINT 'X-Axis: Date';
    PRINT 'Y-Axis: Total Sales (?)';
    PRINT '========================================';
    PRINT '';
    
    WITH DateRange AS (
        SELECT CAST(@StartDate AS DATE) AS SaleDate
        UNION ALL
        SELECT DATEADD(DAY, 1, SaleDate)
        FROM DateRange
        WHERE SaleDate < @EndDate
    ),
    DailySales AS (
        SELECT 
            CAST(OrderDate AS DATE) AS SaleDate,
            COUNT(DISTINCT OrderID) AS TotalOrders,
            SUM(TotalAmount) AS TotalSales,
            AVG(TotalAmount) AS AverageSale
        FROM Orders
        WHERE OrderStatus NOT IN ('Cancelled')
          AND CAST(OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY CAST(OrderDate AS DATE)
    )
    SELECT 
        dr.SaleDate AS Date,
        FORMAT(dr.SaleDate, 'dd-MMM-yyyy') AS DateFormatted,
        DATENAME(WEEKDAY, dr.SaleDate) AS DayOfWeek,
        ISNULL(ds.TotalOrders, 0) AS TotalOrders,
        ISNULL(ds.TotalSales, 0) AS TotalSales,
        ISNULL(ds.AverageSale, 0) AS AverageSale,
        -- Running total
        SUM(ISNULL(ds.TotalSales, 0)) OVER (ORDER BY dr.SaleDate) AS CumulativeSales
    FROM DateRange dr
    LEFT JOIN DailySales ds ON dr.SaleDate = ds.SaleDate
    ORDER BY dr.SaleDate
    OPTION (MAXRECURSION 365);
END
GO

-- =============================================
-- GRAPH 2: Monthly Revenue Bar Chart
-- X-Axis: Month | Y-Axis: Revenue
-- =============================================
CREATE PROCEDURE sp_GetMonthlyRevenueBarChart
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Year IS NULL SET @Year = YEAR(GETDATE());
    
    PRINT '========================================';
    PRINT 'GRAPH TYPE: BAR CHART (Vertical)';
    PRINT 'CHART TITLE: Monthly Revenue - ' + CAST(@Year AS NVARCHAR(4));
    PRINT 'X-Axis: Month';
    PRINT 'Y-Axis: Revenue (?)';
    PRINT '========================================';
    PRINT '';
    
    WITH MonthlyData AS (
        SELECT 
            MONTH(OrderDate) AS MonthNumber,
            DATENAME(MONTH, OrderDate) AS MonthName,
            COUNT(OrderID) AS TotalOrders,
            SUM(TotalAmount) AS TotalRevenue,
            SUM(SubTotal) AS GrossRevenue,
            SUM(TaxAmount) AS TotalTax,
            SUM(ShippingCharges) AS ShippingRevenue,
            AVG(TotalAmount) AS AverageOrderValue
        FROM Orders
        WHERE YEAR(OrderDate) = @Year
          AND OrderStatus NOT IN ('Cancelled')
        GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
    )
    SELECT 
        MonthNumber,
        MonthName,
        TotalOrders,
        TotalRevenue,
        GrossRevenue,
        TotalTax,
        ShippingRevenue,
        CAST(AverageOrderValue AS DECIMAL(12,2)) AS AverageOrderValue,
        -- Calculate % of yearly total
        CAST(TotalRevenue * 100.0 / SUM(TotalRevenue) OVER () AS DECIMAL(5,2)) AS PercentOfYearlyRevenue,
        -- Rank months
        RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM MonthlyData
    ORDER BY MonthNumber;
END
GO

-- =============================================
-- GRAPH 3: Best Selling Products Pie Chart
-- Labels: Product Name | Values: Quantity Sold
-- =============================================
CREATE PROCEDURE sp_GetBestSellingProductsPieChart
    @TopN INT = 10,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = '2025-10-01';
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    PRINT '========================================';
    PRINT 'GRAPH TYPE: PIE CHART';
    PRINT 'CHART TITLE: Top ' + CAST(@TopN AS NVARCHAR(10)) + ' Best Selling Products';
    PRINT 'Labels: Product Name';
    PRINT 'Values: Quantity Sold';
    PRINT '========================================';
    PRINT '';
    
    WITH ProductSales AS (
        SELECT 
            p.ProductID,
            p.ProductName,
            c.CategoryName,
            p.Brand,
            SUM(oi.Quantity) AS TotalQuantitySold,
            SUM(oi.LineTotal) AS TotalRevenue,
            COUNT(DISTINCT oi.OrderID) AS NumberOfOrders,
            AVG(oi.UnitPrice) AS AveragePrice
        FROM OrderItems oi
        INNER JOIN Products p ON oi.ProductID = p.ProductID
        INNER JOIN Categories c ON p.CategoryID = c.CategoryID
        INNER JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE o.OrderStatus NOT IN ('Cancelled')
          AND CAST(o.OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Brand
    ),
    TopProducts AS (
        SELECT TOP (@TopN)
            ProductName AS Label,
            TotalQuantitySold AS Value,
            CategoryName,
            Brand,
            TotalRevenue,
            NumberOfOrders,
            CAST(AveragePrice AS DECIMAL(12,2)) AS AveragePrice,
            -- Calculate percentage
            CAST(TotalQuantitySold * 100.0 / SUM(TotalQuantitySold) OVER () AS DECIMAL(5,2)) AS Percentage,
            -- Color coding suggestions
            CASE 
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 1 THEN '#FF6384'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 2 THEN '#36A2EB'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 3 THEN '#FFCE56'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 4 THEN '#4BC0C0'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 5 THEN '#9966FF'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 6 THEN '#FF9F40'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 7 THEN '#FF6384'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 8 THEN '#C9CBCF'
                WHEN ROW_NUMBER() OVER (ORDER BY TotalQuantitySold DESC) = 9 THEN '#4BC0C0'
                ELSE '#36A2EB'
            END AS SuggestedColor
        FROM ProductSales
        ORDER BY TotalQuantitySold DESC
    )
    SELECT 
        Label AS ProductName,
        Value AS QuantitySold,
        Percentage,
        CategoryName,
        Brand,
        TotalRevenue,
        NumberOfOrders,
        AveragePrice,
        SuggestedColor
    FROM TopProducts
    ORDER BY Value DESC;
END
GO

-- =============================================
-- GRAPH 4: Customer Growth Trend (Line Chart)
-- X-Axis: Month | Y-Axis: New Customers
-- =============================================
CREATE PROCEDURE sp_GetCustomerGrowthTrend
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = '2024-01-01';
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    PRINT '========================================';
    PRINT 'GRAPH TYPE: LINE CHART (Area Chart)';
    PRINT 'CHART TITLE: Customer Growth Trend';
    PRINT 'X-Axis: Month-Year';
    PRINT 'Y-Axis: Number of Customers';
    PRINT '========================================';
    PRINT '';
    
    WITH MonthlyRegistrations AS (
        SELECT 
            YEAR(RegistrationDate) AS Year,
            MONTH(RegistrationDate) AS Month,
            DATEFROMPARTS(YEAR(RegistrationDate), MONTH(RegistrationDate), 1) AS MonthStart,
            COUNT(*) AS NewCustomers
        FROM Customers
        WHERE CAST(RegistrationDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY YEAR(RegistrationDate), MONTH(RegistrationDate)
    )
    SELECT 
        Year,
        Month,
        FORMAT(MonthStart, 'MMM-yyyy') AS MonthYear,
        NewCustomers,
        -- Cumulative customers
        SUM(NewCustomers) OVER (ORDER BY Year, Month) AS TotalCustomers,
        -- Running average
        AVG(CAST(NewCustomers AS DECIMAL(10,2))) OVER (
            ORDER BY Year, Month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS ThreeMonthAverage,
        -- Growth rate
        CASE 
            WHEN LAG(NewCustomers) OVER (ORDER BY Year, Month) IS NOT NULL THEN
                CAST((NewCustomers - LAG(NewCustomers) OVER (ORDER BY Year, Month)) * 100.0 / 
                NULLIF(LAG(NewCustomers) OVER (ORDER BY Year, Month), 0) AS DECIMAL(10,2))
            ELSE NULL
        END AS GrowthPercentage
    FROM MonthlyRegistrations
    ORDER BY Year, Month;
END
GO

-- =============================================
-- GRAPH 5: Top 10 Customers Bar Chart
-- X-Axis: Customer Name | Y-Axis: Total Spent
-- =============================================
CREATE PROCEDURE sp_GetTop10CustomersBarChart
    @TopN INT = 10,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = '2025-01-01';
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    PRINT '========================================';
    PRINT 'GRAPH TYPE: HORIZONTAL BAR CHART';
    PRINT 'CHART TITLE: Top ' + CAST(@TopN AS NVARCHAR(10)) + ' Customers by Revenue';
    PRINT 'X-Axis: Total Spent (?)';
    PRINT 'Y-Axis: Customer Name';
    PRINT '========================================';
    PRINT '';
    
    WITH CustomerStats AS (
        SELECT 
            c.CustomerID,
            c.CustomerCode,
            c.FirstName + ' ' + c.LastName AS CustomerName,
            c.City,
            c.State,
            c.CustomerTier,
            COUNT(o.OrderID) AS TotalOrders,
            SUM(o.TotalAmount) AS TotalSpent,
            AVG(o.TotalAmount) AS AverageOrderValue,
            MAX(o.OrderDate) AS LastPurchaseDate,
            MIN(o.OrderDate) AS FirstPurchaseDate,
            DATEDIFF(DAY, MIN(o.OrderDate), MAX(o.OrderDate)) AS CustomerLifetimeDays
        FROM Customers c
        INNER JOIN Orders o ON c.CustomerID = o.CustomerID
        WHERE o.OrderStatus NOT IN ('Cancelled')
          AND CAST(o.OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY c.CustomerID, c.CustomerCode, c.FirstName, c.LastName, c.City, c.State, c.CustomerTier
    )
    SELECT TOP (@TopN)
        CustomerName AS Label,
        TotalSpent AS Value,
        CustomerCode,
        City,
        State,
        CustomerTier,
        TotalOrders,
        CAST(AverageOrderValue AS DECIMAL(12,2)) AS AverageOrderValue,
        FORMAT(LastPurchaseDate, 'dd-MMM-yyyy') AS LastPurchase,
        CustomerLifetimeDays,
        -- Percentage of total revenue
        CAST(TotalSpent * 100.0 / SUM(TotalSpent) OVER () AS DECIMAL(5,2)) AS PercentOfTotalRevenue,
        -- Rank
        ROW_NUMBER() OVER (ORDER BY TotalSpent DESC) AS Rank,
        -- Color based on tier
        CASE CustomerTier
            WHEN 'Platinum' THEN '#E5E4E2'
            WHEN 'Gold' THEN '#FFD700'
            WHEN 'Silver' THEN '#C0C0C0'
            ELSE '#CD7F32'
        END AS SuggestedColor
    FROM CustomerStats
    ORDER BY TotalSpent DESC;
END
GO

-- =============================================
-- GRAPH 6: Order Status Donut Chart
-- Labels: Status | Values: Count
-- =============================================
CREATE PROCEDURE sp_GetOrderStatusDonutChart
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    PRINT '========================================';
    PRINT 'GRAPH TYPE: DONUT CHART';
    PRINT 'CHART TITLE: Order Status Distribution';
    PRINT 'Labels: Order Status';
    PRINT 'Values: Number of Orders';
    PRINT '========================================';
    PRINT '';
    
    WITH StatusStats AS (
        SELECT 
            OrderStatus AS Label,
            COUNT(*) AS Value,
            SUM(TotalAmount) AS TotalRevenue,
            AVG(TotalAmount) AS AverageOrderValue
        FROM Orders
        WHERE CAST(OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY OrderStatus
    )
    SELECT 
        Label AS OrderStatus,
        Value AS OrderCount,
        CAST(Value * 100.0 / SUM(Value) OVER () AS DECIMAL(5,2)) AS Percentage,
        TotalRevenue,
        CAST(AverageOrderValue AS DECIMAL(12,2)) AS AverageOrderValue,
        -- Color coding
        CASE Label
            WHEN 'Delivered' THEN '#28a745'
            WHEN 'Shipped' THEN '#17a2b8'
            WHEN 'Processing' THEN '#ffc107'
            WHEN 'Pending' THEN '#6c757d'
            WHEN 'Cancelled' THEN '#dc3545'
            WHEN 'Returned' THEN '#e83e8c'
            ELSE '#6c757d'
        END AS SuggestedColor,
        -- Icon suggestions
        CASE Label
            WHEN 'Delivered' THEN '?'
            WHEN 'Shipped' THEN '??'
            WHEN 'Processing' THEN '?'
            WHEN 'Pending' THEN '?'
            WHEN 'Cancelled' THEN '?'
            WHEN 'Returned' THEN '?'
            ELSE '?'
        END AS Icon
    FROM StatusStats
    ORDER BY Value DESC;
END
GO

-- =============================================
-- COMPLETE DASHBOARD - All Graphs
-- =============================================
CREATE PROCEDURE sp_GetCompleteDashboard
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=============================================================';
    PRINT '=== E-COMMERCE SALES ANALYTICS DASHBOARD ===';
    PRINT '=============================================================';
    PRINT 'Generated: ' + FORMAT(GETDATE(), 'dd-MMM-yyyy HH:mm:ss');
    PRINT 'User: RajendraSaha2002';
    PRINT '=============================================================';
    PRINT '';
    
    -- Graph 1: Daily Sales
    PRINT '--- GRAPH 1: DAILY SALES (Last 30 Days) ---';
    EXEC sp_GetDailySalesLineChart;
    PRINT '';
    
    -- Graph 2: Monthly Revenue
    PRINT '--- GRAPH 2: MONTHLY REVENUE (Current Year) ---';
    EXEC sp_GetMonthlyRevenueBarChart;
    PRINT '';
    
    -- Graph 3: Best Selling Products
    PRINT '--- GRAPH 3: TOP 10 BEST SELLING PRODUCTS ---';
    EXEC sp_GetBestSellingProductsPieChart @TopN = 10;
    PRINT '';
    
    -- Graph 4: Customer Growth
    PRINT '--- GRAPH 4: CUSTOMER GROWTH TREND ---';
    EXEC sp_GetCustomerGrowthTrend;
    PRINT '';
    
    -- Graph 5: Top Customers
    PRINT '--- GRAPH 5: TOP 10 CUSTOMERS ---';
    EXEC sp_GetTop10CustomersBarChart @TopN = 10;
    PRINT '';
    
    -- Graph 6: Order Status
    PRINT '--- GRAPH 6: ORDER STATUS DISTRIBUTION ---';
    EXEC sp_GetOrderStatusDonutChart;
    PRINT '';
    
    PRINT '=============================================================';
    PRINT '=== DASHBOARD COMPLETE ===';
    PRINT '=============================================================';
END
GO

-- =============================================
-- VIEWS FOR ADDITIONAL INSIGHTS
-- =============================================

CREATE VIEW vw_SalesOverview AS
SELECT 
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    SUM(o.TotalAmount) AS TotalRevenue,
    AVG(o.TotalAmount) AS AverageOrderValue,
    SUM(CASE WHEN o.OrderStatus = 'Delivered' THEN 1 ELSE 0 END) AS DeliveredOrders,
    SUM(CASE WHEN o.OrderStatus = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledOrders,
    CAST(SUM(CASE WHEN o.OrderStatus = 'Delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS DeliveryRate,
    CAST(SUM(CASE WHEN o.OrderStatus = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS CancellationRate
FROM Orders o
WHERE YEAR(o.OrderDate) = YEAR(GETDATE());
GO

CREATE VIEW vw_ProductPerformance AS
SELECT 
    p.ProductID,
    p.ProductCode,
    p.ProductName,
    c.CategoryName,
    p.Brand,
    p.UnitPrice,
    p.StockQuantity,
    ISNULL(SUM(oi.Quantity), 0) AS TotalSold,
    ISNULL(SUM(oi.LineTotal), 0) AS TotalRevenue,
    COUNT(DISTINCT oi.OrderID) AS NumberOfOrders,
    RANK() OVER (ORDER BY ISNULL(SUM(oi.Quantity), 0) DESC) AS SalesRank
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN OrderItems oi ON p.ProductID = oi.ProductID
LEFT JOIN Orders o ON oi.OrderID = o.OrderID AND o.OrderStatus NOT IN ('Cancelled')
GROUP BY p.ProductID, p.ProductCode, p.ProductName, c.CategoryName, p.Brand, p.UnitPrice, p.StockQuantity;
GO

CREATE VIEW vw_CustomerInsights AS
SELECT 
    c.CustomerID,
    c.CustomerCode,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.Email,
    c.City,
    c.State,
    c.CustomerTier,
    c.RegistrationDate,
    c.TotalPurchases,
    c.TotalSpent,
    c.LastPurchaseDate,
    DATEDIFF(DAY, c.LastPurchaseDate, GETDATE()) AS DaysSinceLastPurchase,
    CASE 
        WHEN DATEDIFF(DAY, c.LastPurchaseDate, GETDATE()) > 90 THEN 'At Risk'
        WHEN DATEDIFF(DAY, c.LastPurchaseDate, GETDATE()) > 60 THEN 'Inactive'
        WHEN DATEDIFF(DAY, c.LastPurchaseDate, GETDATE()) > 30 THEN 'Active'
        ELSE 'Very Active'
    END AS CustomerStatus
FROM Customers c
WHERE c.IsActive = 1;
GO

-- =============================================
-- EXECUTE DEMONSTRATIONS
-- =============================================

PRINT '=============================================================';
PRINT '=== DEMONSTRATION: SALES ANALYTICS DASHBOARD ===';
PRINT '=============================================================';
PRINT '';

-- Demo 1: Daily Sales Line Chart
PRINT '=== DEMO 1: DAILY SALES LINE CHART (Last 30 Days) ===';
EXEC sp_GetDailySalesLineChart @StartDate = '2025-10-20', @EndDate = '2025-11-20';
PRINT '';
GO

-- Demo 2: Monthly Revenue Bar Chart
PRINT '=== DEMO 2: MONTHLY REVENUE BAR CHART (2025) ===';
EXEC sp_GetMonthlyRevenueBarChart @Year = 2025;
PRINT '';
GO

-- Demo 3: Best Selling Products Pie Chart
PRINT '=== DEMO 3: BEST SELLING PRODUCTS PIE CHART (Top 10) ===';
EXEC sp_GetBestSellingProductsPieChart @TopN = 10;
PRINT '';
GO

-- Demo 4: Customer Growth Trend
PRINT '=== DEMO 4: CUSTOMER GROWTH TREND ===';
EXEC sp_GetCustomerGrowthTrend @StartDate = '2024-01-01', @EndDate = '2025-11-20';
PRINT '';
GO

-- Demo 5: Top 10 Customers Bar Chart
PRINT '=== DEMO 5: TOP 10 CUSTOMERS BAR CHART ===';
EXEC sp_GetTop10CustomersBarChart @TopN = 10;
PRINT '';
GO

-- Demo 6: Order Status Donut Chart
PRINT '=== DEMO 6: ORDER STATUS DONUT CHART ===';
EXEC sp_GetOrderStatusDonutChart @StartDate = '2025-10-01', @EndDate = '2025-11-20';
PRINT '';
GO

-- Demo 7: View Sales Overview
PRINT '=== DEMO 7: SALES OVERVIEW (View) ===';
SELECT * FROM vw_SalesOverview;
PRINT '';
GO

-- Demo 8: Product Performance
PRINT '=== DEMO 8: TOP 10 PRODUCT PERFORMANCE ===';
SELECT TOP 10 * FROM vw_ProductPerformance ORDER BY TotalRevenue DESC;
PRINT '';
GO

-- Demo 9: Customer Insights
PRINT '=== DEMO 9: CUSTOMER INSIGHTS (Top Spenders) ===';
SELECT TOP 10 * FROM vw_CustomerInsights ORDER BY TotalSpent DESC;
PRINT '';
GO

-- Demo 10: Complete Dashboard
PRINT '=== DEMO 10: COMPLETE DASHBOARD (All Graphs) ===';
-- EXEC sp_GetCompleteDashboard;
-- Commented out to avoid too much output, uncomment to run
PRINT '';
GO

PRINT '=============================================================';
PRINT '=== SETUP COMPLETE ===';
PRINT '=============================================================';
PRINT '';
PRINT 'Database: ECommerceDashboardDB';
PRINT 'Tables: 6 (Customers, Categories, Products, Orders, OrderItems, Payments)';
PRINT 'Sample Data: 20 Customers, 20 Products, 100+ Orders';
PRINT 'Date Range: Oct 1, 2025 - Nov 20, 2025';
PRINT '';
PRINT 'GRAPH STORED PROCEDURES:';
PRINT '  1. sp_GetDailySalesLineChart - LINE CHART';
PRINT '  2. sp_GetMonthlyRevenueBarChart - BAR CHART';
PRINT '  3. sp_GetBestSellingProductsPieChart - PIE CHART';
PRINT '  4. sp_GetCustomerGrowthTrend - LINE/AREA CHART';
PRINT '  5. sp_GetTop10CustomersBarChart - HORIZONTAL BAR CHART';
PRINT '  6. sp_GetOrderStatusDonutChart - DONUT CHART';
PRINT '  7. sp_GetCompleteDashboard - ALL GRAPHS';
PRINT '';
PRINT 'VIEWS:';
PRINT '  1. vw_SalesOverview';
PRINT '  2. vw_ProductPerformance';
PRINT '  3. vw_CustomerInsights';
PRINT '';
PRINT 'Ready for visualization in Power BI, Tableau, or Chart.js!';
PRINT '=============================================================';
GO