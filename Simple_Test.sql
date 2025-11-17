CREATE DATABASE TestDB;
GO

USE TestDB;
GO

CREATE TABLE Students (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50),
    Age INT
);
GO

INSERT INTO Students (Name, Age) VALUES
('Rajendra', 23),
('Suchismita', 22),
('Rahul', 21);
GO

SELECT * FROM Students;
GO
