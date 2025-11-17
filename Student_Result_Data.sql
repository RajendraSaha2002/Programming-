-- ========================================
-- STUDENT RESULT MANAGEMENT SYSTEM
-- Microsoft SQL Server (T-SQL) Compatible Version
-- ========================================

-- Drop existing objects if they exist
IF OBJECT_ID('dbo.Marks', 'U') IS NOT NULL DROP TABLE dbo.Marks;
IF OBJECT_ID('dbo.Subjects', 'U') IS NOT NULL DROP TABLE dbo.Subjects;
IF OBJECT_ID('dbo.Students', 'U') IS NOT NULL DROP TABLE dbo.Students;
IF OBJECT_ID('dbo.student_cgpa', 'V') IS NOT NULL DROP VIEW dbo.student_cgpa;
GO

-- ========================================
-- TABLE CREATION
-- ========================================

-- Students Table
CREATE TABLE Students (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    dept NVARCHAR(50) NOT NULL,
    admission_year INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
);

-- Subjects Table
CREATE TABLE Subjects (
    id INT IDENTITY(1,1) PRIMARY KEY,
    subject_name NVARCHAR(100) NOT NULL,
    credit INT NOT NULL CHECK(credit > 0),
    created_at DATETIME DEFAULT GETDATE()
);

-- Marks Table
CREATE TABLE Marks (
    id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    subject_id INT NOT NULL,
    marks DECIMAL(5,2) NOT NULL CHECK(marks >= 0 AND marks <= 100),
    semester INT NOT NULL,
    exam_date DATE,
    CONSTRAINT FK_Marks_Students FOREIGN KEY (student_id) REFERENCES Students(id) ON DELETE CASCADE,
    CONSTRAINT FK_Marks_Subjects FOREIGN KEY (subject_id) REFERENCES Subjects(id) ON DELETE CASCADE,
    CONSTRAINT UQ_Student_Subject_Semester UNIQUE(student_id, subject_id, semester)
);

-- Create indexes for better performance
CREATE INDEX idx_marks_student ON Marks(student_id);
CREATE INDEX idx_marks_subject ON Marks(subject_id);
CREATE INDEX idx_students_dept ON Students(dept);
GO

-- ========================================
-- SAMPLE DATA INSERTION
-- ========================================

-- Insert Students
SET IDENTITY_INSERT Students ON;
INSERT INTO Students (id, name, dept, admission_year) VALUES
(1, 'Alice Johnson', 'Computer Science', 2022),
(2, 'Bob Smith', 'Computer Science', 2022),
(3, 'Charlie Brown', 'Electronics', 2021),
(4, 'Diana Prince', 'Computer Science', 2023),
(5, 'Eve Wilson', 'Mechanical', 2022),
(6, 'Frank Miller', 'Electronics', 2022),
(7, 'Grace Lee', 'Computer Science', 2021),
(8, 'Henry Davis', 'Mechanical', 2023),
(9, 'Ivy Chen', 'Electronics', 2022),
(10, 'Jack Ryan', 'Computer Science', 2022),
(11, 'Kate Morgan', 'Mechanical', 2021),
(12, 'Leo Martinez', 'Electronics', 2023),
(13, 'Maya Patel', 'Computer Science', 2022),
(14, 'Nathan Gray', 'Mechanical', 2022),
(15, 'Olivia Turner', 'Computer Science', 2023);
SET IDENTITY_INSERT Students OFF;

-- Insert Subjects
SET IDENTITY_INSERT Subjects ON;
INSERT INTO Subjects (id, subject_name, credit) VALUES
(1, 'Data Structures', 4),
(2, 'Database Management', 3),
(3, 'Operating Systems', 4),
(4, 'Computer Networks', 3),
(5, 'Software Engineering', 3),
(6, 'Web Development', 2),
(7, 'Machine Learning', 4),
(8, 'Artificial Intelligence', 3),
(9, 'Digital Electronics', 3),
(10, 'Microprocessors', 4);
SET IDENTITY_INSERT Subjects OFF;

-- Insert Marks (Semester 1)
SET IDENTITY_INSERT Marks ON;
INSERT INTO Marks (id, student_id, subject_id, marks, semester, exam_date) VALUES
-- Alice Johnson (Excellent student)
(1, 1, 1, 92, 1, '2023-05-15'),
(2, 1, 2, 88, 1, '2023-05-17'),
(3, 1, 3, 95, 1, '2023-05-20'),
(4, 1, 4, 90, 1, '2023-05-22'),
(5, 1, 5, 87, 1, '2023-05-25'),

-- Bob Smith (Good student)
(6, 2, 1, 78, 1, '2023-05-15'),
(7, 2, 2, 82, 1, '2023-05-17'),
(8, 2, 3, 75, 1, '2023-05-20'),
(9, 2, 4, 80, 1, '2023-05-22'),
(10, 2, 5, 76, 1, '2023-05-25'),

-- Charlie Brown (Average with one fail)
(11, 3, 1, 65, 1, '2023-05-15'),
(12, 3, 2, 38, 1, '2023-05-17'),
(13, 3, 3, 70, 1, '2023-05-20'),
(14, 3, 4, 68, 1, '2023-05-22'),
(15, 3, 9, 72, 1, '2023-05-25'),

-- Diana Prince (Top performer)
(16, 4, 1, 96, 1, '2023-05-15'),
(17, 4, 2, 94, 1, '2023-05-17'),
(18, 4, 3, 98, 1, '2023-05-20'),
(19, 4, 4, 93, 1, '2023-05-22'),
(20, 4, 5, 91, 1, '2023-05-25'),

-- Eve Wilson (Below average)
(21, 5, 1, 55, 1, '2023-05-15'),
(22, 5, 2, 60, 1, '2023-05-17'),
(23, 5, 3, 58, 1, '2023-05-20'),
(24, 5, 6, 62, 1, '2023-05-22'),
(25, 5, 7, 56, 1, '2023-05-25'),

-- Frank Miller (Mixed performance)
(26, 6, 1, 72, 1, '2023-05-15'),
(27, 6, 9, 68, 1, '2023-05-17'),
(28, 6, 10, 75, 1, '2023-05-20'),
(29, 6, 4, 70, 1, '2023-05-22'),

-- Grace Lee (Excellent student)
(30, 7, 1, 89, 1, '2023-05-15'),
(31, 7, 2, 92, 1, '2023-05-17'),
(32, 7, 3, 88, 1, '2023-05-20'),
(33, 7, 7, 90, 1, '2023-05-22'),
(34, 7, 8, 86, 1, '2023-05-25'),

-- Henry Davis (Weak student with fails)
(35, 8, 1, 45, 1, '2023-05-15'),
(36, 8, 2, 35, 1, '2023-05-17'),
(37, 8, 3, 42, 1, '2023-05-20'),
(38, 8, 6, 50, 1, '2023-05-22'),

-- Ivy Chen (Good student)
(39, 9, 9, 80, 1, '2023-05-15'),
(40, 9, 10, 85, 1, '2023-05-17'),
(41, 9, 4, 78, 1, '2023-05-20'),
(42, 9, 1, 82, 1, '2023-05-22'),

-- Jack Ryan (Average student)
(43, 10, 1, 70, 1, '2023-05-15'),
(44, 10, 2, 68, 1, '2023-05-17'),
(45, 10, 3, 72, 1, '2023-05-20'),
(46, 10, 5, 69, 1, '2023-05-22'),
(47, 10, 6, 71, 1, '2023-05-25');
SET IDENTITY_INSERT Marks OFF;
GO

-- ========================================
-- QUERY 1: CALCULATE CGPA / GPA FOR EACH STUDENT
-- ========================================

-- Create View for CGPA calculation
CREATE VIEW student_cgpa AS
SELECT 
    s.id,
    s.name,
    s.dept,
    s.admission_year,
    COUNT(DISTINCT m.subject_id) as total_subjects,
    ROUND(AVG(m.marks), 2) as avg_marks,
    ROUND(
        SUM(
            CASE 
                WHEN m.marks >= 90 THEN 10 * sub.credit
                WHEN m.marks >= 80 THEN 9 * sub.credit
                WHEN m.marks >= 70 THEN 8 * sub.credit
                WHEN m.marks >= 60 THEN 7 * sub.credit
                WHEN m.marks >= 50 THEN 6 * sub.credit
                WHEN m.marks >= 40 THEN 5 * sub.credit
                ELSE 0
            END
        ) * 1.0 / NULLIF(SUM(sub.credit), 0), 
        2
    ) as cgpa
FROM Students s
LEFT JOIN Marks m ON s.id = m.student_id
LEFT JOIN Subjects sub ON m.subject_id = sub.id
GROUP BY s.id, s.name, s.dept, s.admission_year;
GO

-- View CGPA Results
SELECT 
    name,
    dept,
    admission_year,
    total_subjects,
    avg_marks,
    cgpa,
    CASE 
        WHEN cgpa >= 9.0 THEN 'Outstanding'
        WHEN cgpa >= 8.0 THEN 'Excellent'
        WHEN cgpa >= 7.0 THEN 'Very Good'
        WHEN cgpa >= 6.0 THEN 'Good'
        WHEN cgpa >= 5.0 THEN 'Average'
        ELSE 'Poor'
    END as grade_category
FROM student_cgpa
WHERE cgpa IS NOT NULL
ORDER BY cgpa DESC;
GO

-- ========================================
-- QUERY 2: TOP 3 PERFORMERS (OVERALL)
-- ========================================

SELECT TOP 3
    RANK() OVER (ORDER BY cgpa DESC) as [rank],
    name,
    dept,
    admission_year,
    total_subjects,
    avg_marks,
    cgpa
FROM student_cgpa
WHERE total_subjects > 0
ORDER BY cgpa DESC;
GO

-- ========================================
-- QUERY 3: TOP 3 PERFORMERS (DEPARTMENT-WISE)
-- ========================================

WITH dept_rankings AS (
    SELECT 
        name,
        dept,
        admission_year,
        total_subjects,
        avg_marks,
        cgpa,
        RANK() OVER (PARTITION BY dept ORDER BY cgpa DESC) as dept_rank,
        DENSE_RANK() OVER (PARTITION BY dept ORDER BY cgpa DESC) as dept_dense_rank
    FROM student_cgpa
    WHERE total_subjects > 0
)
SELECT 
    dept_rank,
    name,
    dept,
    cgpa,
    avg_marks
FROM dept_rankings
WHERE dept_rank <= 3
ORDER BY dept, dept_rank;
GO

-- ========================================
-- QUERY 4: STUDENTS WITH FAILED SUBJECTS (<40 marks)
-- ========================================

SELECT 
    s.id,
    s.name,
    s.dept,
    sub.subject_name,
    m.marks,
    m.semester,
    'FAIL' as status
FROM Students s
JOIN Marks m ON s.id = m.student_id
JOIN Subjects sub ON m.subject_id = sub.id
WHERE m.marks < 40
ORDER BY s.name, sub.subject_name;
GO

-- ========================================
-- QUERY 5: COUNT OF FAILED SUBJECTS PER STUDENT
-- ========================================

SELECT 
    s.id,
    s.name,
    s.dept,
    COUNT(m.id) as failed_subjects,
    STRING_AGG(sub.subject_name, ', ') WITHIN GROUP (ORDER BY sub.subject_name) as failed_in
FROM Students s
JOIN Marks m ON s.id = m.student_id
JOIN Subjects sub ON m.subject_id = sub.id
WHERE m.marks < 40
GROUP BY s.id, s.name, s.dept
ORDER BY failed_subjects DESC;
GO

-- ========================================
-- QUERY 6: DEPARTMENT-WISE RESULT SUMMARY
-- ========================================

SELECT 
    s.dept,
    COUNT(DISTINCT s.id) as total_students,
    COUNT(DISTINCT m.subject_id) as subjects_offered,
    ROUND(AVG(m.marks), 2) as avg_dept_marks,
    ROUND(AVG(sc.cgpa), 2) as avg_dept_cgpa,
    COUNT(DISTINCT CASE WHEN m.marks >= 40 THEN m.student_id END) as passed_students,
    COUNT(DISTINCT CASE WHEN m.marks < 40 THEN m.student_id END) as students_with_failures,
    ROUND(
        COUNT(DISTINCT CASE WHEN m.marks >= 40 THEN m.student_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT s.id), 0), 
        2
    ) as pass_percentage
FROM Students s
LEFT JOIN Marks m ON s.id = m.student_id
LEFT JOIN student_cgpa sc ON s.id = sc.id
GROUP BY s.dept
ORDER BY avg_dept_cgpa DESC;
GO

-- ========================================
-- QUERY 7: SUBJECT-WISE PERFORMANCE ANALYSIS
-- ========================================

SELECT 
    sub.subject_name,
    sub.credit,
    COUNT(m.id) as total_attempts,
    ROUND(AVG(m.marks), 2) as avg_marks,
    MIN(m.marks) as min_marks,
    MAX(m.marks) as max_marks,
    COUNT(CASE WHEN m.marks >= 90 THEN 1 END) as outstanding_count,
    COUNT(CASE WHEN m.marks >= 70 THEN 1 END) as good_count,
    COUNT(CASE WHEN m.marks < 40 THEN 1 END) as fail_count,
    ROUND(
        COUNT(CASE WHEN m.marks >= 40 THEN 1 END) * 100.0 / NULLIF(COUNT(m.id), 0), 
        2
    ) as pass_percentage
FROM Subjects sub
LEFT JOIN Marks m ON sub.id = m.subject_id
GROUP BY sub.id, sub.subject_name, sub.credit
ORDER BY avg_marks DESC;
GO

-- ========================================
-- QUERY 8: STUDENTS WITH ALL SUBJECTS ATTEMPTED
-- ========================================

SELECT 
    s.id,
    s.name,
    s.dept,
    COUNT(DISTINCT m.subject_id) as subjects_taken,
    (SELECT COUNT(*) FROM Subjects) as total_subjects_available
FROM Students s
JOIN Marks m ON s.id = m.student_id
GROUP BY s.id, s.name, s.dept
HAVING COUNT(DISTINCT m.subject_id) = (SELECT COUNT(*) FROM Subjects);
GO

-- ========================================
-- QUERY 9: SEMESTER-WISE PERFORMANCE
-- ========================================

SELECT 
    m.semester,
    COUNT(DISTINCT m.student_id) as students_appeared,
    COUNT(m.id) as total_exams,
    ROUND(AVG(m.marks), 2) as avg_marks,
    COUNT(CASE WHEN m.marks >= 90 THEN 1 END) as grade_A_plus,
    COUNT(CASE WHEN m.marks >= 80 THEN 1 END) as grade_A,
    COUNT(CASE WHEN m.marks >= 70 THEN 1 END) as grade_B,
    COUNT(CASE WHEN m.marks >= 60 THEN 1 END) as grade_C,
    COUNT(CASE WHEN m.marks >= 40 THEN 1 END) as passed,
    COUNT(CASE WHEN m.marks < 40 THEN 1 END) as failed
FROM Marks m
GROUP BY m.semester
ORDER BY m.semester;
GO

-- ========================================
-- QUERY 10: STUDENTS AT RISK (CGPA < 6.0)
-- ========================================

SELECT 
    sc.name,
    sc.dept,
    sc.admission_year,
    sc.cgpa,
    sc.avg_marks,
    sc.total_subjects,
    COUNT(CASE WHEN m.marks < 40 THEN 1 END) as failed_subjects
FROM student_cgpa sc
LEFT JOIN Marks m ON sc.id = m.student_id
WHERE sc.cgpa < 6.0
GROUP BY sc.id, sc.name, sc.dept, sc.admission_year, sc.cgpa, sc.avg_marks, sc.total_subjects
ORDER BY sc.cgpa ASC;
GO

-- ========================================
-- QUERY 11: TOP PERFORMER IN EACH SUBJECT
-- ========================================

WITH subject_toppers AS (
    SELECT 
        m.subject_id,
        m.student_id,
        m.marks,
        RANK() OVER (PARTITION BY m.subject_id ORDER BY m.marks DESC) as [rank]
    FROM Marks m
)
SELECT 
    sub.subject_name,
    s.name as student_name,
    s.dept,
    st.marks as highest_marks
FROM subject_toppers st
JOIN Students s ON st.student_id = s.id
JOIN Subjects sub ON st.subject_id = sub.id
WHERE st.[rank] = 1
ORDER BY sub.subject_name;
GO

-- ========================================
-- QUERY 12: COMPARISON: AVERAGE MARKS vs DEPARTMENT AVERAGE
-- ========================================

WITH dept_avg AS (
    SELECT 
        s.dept,
        AVG(m.marks) as dept_avg_marks
    FROM Students s
    JOIN Marks m ON s.id = m.student_id
    GROUP BY s.dept
)
SELECT 
    s.name,
    s.dept,
    ROUND(AVG(m.marks), 2) as student_avg,
    ROUND(da.dept_avg_marks, 2) as dept_avg,
    ROUND(AVG(m.marks) - da.dept_avg_marks, 2) as difference,
    CASE 
        WHEN AVG(m.marks) > da.dept_avg_marks THEN 'Above Average'
        WHEN AVG(m.marks) = da.dept_avg_marks THEN 'At Average'
        ELSE 'Below Average'
    END as performance_status
FROM Students s
JOIN Marks m ON s.id = m.student_id
JOIN dept_avg da ON s.dept = da.dept
GROUP BY s.id, s.name, s.dept, da.dept_avg_marks
ORDER BY s.dept, difference DESC;
GO

-- ========================================
-- QUERY 13: PERCENTILE RANKING
-- ========================================

WITH student_percentiles AS (
    SELECT 
        id,
        name,
        dept,
        cgpa,
        PERCENT_RANK() OVER (ORDER BY cgpa) * 100 as percentile
    FROM student_cgpa
    WHERE total_subjects > 0
)
SELECT 
    name,
    dept,
    cgpa,
    ROUND(percentile, 2) as percentile_rank,
    CASE 
        WHEN percentile >= 90 THEN 'Top 10%'
        WHEN percentile >= 75 THEN 'Top 25%'
        WHEN percentile >= 50 THEN 'Top 50%'
        ELSE 'Bottom 50%'
    END as rank_category
FROM student_percentiles
ORDER BY percentile DESC;
GO

-- ========================================
-- QUERY 14: STUDENT DETAILED REPORT CARD
-- ========================================

SELECT 
    s.name,
    s.dept,
    s.admission_year,
    sub.subject_name,
    sub.credit,
    m.marks,
    m.semester,
    CASE 
        WHEN m.marks >= 90 THEN 'A+ (Outstanding)'
        WHEN m.marks >= 80 THEN 'A (Excellent)'
        WHEN m.marks >= 70 THEN 'B (Very Good)'
        WHEN m.marks >= 60 THEN 'C (Good)'
        WHEN m.marks >= 50 THEN 'D (Average)'
        WHEN m.marks >= 40 THEN 'E (Pass)'
        ELSE 'F (Fail)'
    END as grade,
    CASE 
        WHEN m.marks >= 90 THEN 10
        WHEN m.marks >= 80 THEN 9
        WHEN m.marks >= 70 THEN 8
        WHEN m.marks >= 60 THEN 7
        WHEN m.marks >= 50 THEN 6
        WHEN m.marks >= 40 THEN 5
        ELSE 0
    END as grade_point
FROM Students s
JOIN Marks m ON s.id = m.student_id
JOIN Subjects sub ON m.subject_id = sub.id
ORDER BY s.name, m.semester, sub.subject_name;
GO

-- ========================================
-- QUERY 15: YEAR-WISE ADMISSION STATISTICS
-- ========================================

SELECT 
    s.admission_year,
    COUNT(DISTINCT s.id) as total_students,
    ROUND(AVG(sc.cgpa), 2) as avg_cgpa,
    MAX(sc.cgpa) as highest_cgpa,
    MIN(sc.cgpa) as lowest_cgpa,
    COUNT(DISTINCT CASE WHEN sc.cgpa >= 8.0 THEN s.id END) as excellent_performers,
    COUNT(DISTINCT CASE WHEN sc.cgpa < 6.0 THEN s.id END) as at_risk_students
FROM Students s
LEFT JOIN student_cgpa sc ON s.id = sc.id
GROUP BY s.admission_year
ORDER BY s.admission_year DESC;
GO

-- ========================================
-- STORED PROCEDURE: Get Student Complete Report
-- ========================================

CREATE PROCEDURE GetStudentReport
    @student_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Student Info
    SELECT 
        s.id,
        s.name,
        s.dept,
        s.admission_year,
        sc.cgpa,
        sc.avg_marks,
        sc.total_subjects
    FROM Students s
    LEFT JOIN student_cgpa sc ON s.id = sc.id
    WHERE s.id = @student_id;
    
    -- Subject-wise marks
    SELECT 
        sub.subject_name,
        sub.credit,
        m.marks,
        m.semester,
        CASE 
            WHEN m.marks >= 90 THEN 'A+'
            WHEN m.marks >= 80 THEN 'A'
            WHEN m.marks >= 70 THEN 'B'
            WHEN m.marks >= 60 THEN 'C'
            WHEN m.marks >= 50 THEN 'D'
            WHEN m.marks >= 40 THEN 'E'
            ELSE 'F'
        END as grade
    FROM Marks m
    JOIN Subjects sub ON m.subject_id = sub.id
    WHERE m.student_id = @student_id
    ORDER BY m.semester, sub.subject_name;
    
    -- Failed subjects
    SELECT 
        sub.subject_name,
        m.marks,
        m.semester
    FROM Marks m
    JOIN Subjects sub ON m.subject_id = sub.id
    WHERE m.student_id = @student_id AND m.marks < 40
    ORDER BY m.semester;
END;
GO

-- ========================================
-- FUNCTION: Calculate Grade Point
-- ========================================

CREATE FUNCTION dbo.GetGradePoint(@marks DECIMAL(5,2))
RETURNS INT
AS
BEGIN
    DECLARE @grade_point INT;
    
    IF @marks >= 90 SET @grade_point = 10;
    ELSE IF @marks >= 80 SET @grade_point = 9;
    ELSE IF @marks >= 70 SET @grade_point = 8;
    ELSE IF @marks >= 60 SET @grade_point = 7;
    ELSE IF @marks >= 50 SET @grade_point = 6;
    ELSE IF @marks >= 40 SET @grade_point = 5;
    ELSE SET @grade_point = 0;
    
    RETURN @grade_point;
END;
GO

-- ========================================
-- USAGE EXAMPLES
-- ========================================

-- Call stored procedure for student report
-- EXEC GetStudentReport @student_id = 1;

-- Use function in query
-- SELECT s.name, m.marks, dbo.GetGradePoint(m.marks) as grade_point 
-- FROM Marks m JOIN Students s ON m.student_id = s.id;