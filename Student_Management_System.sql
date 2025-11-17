-- Create table
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    department VARCHAR(50),
    marks INT
);

-- Insert sample data
INSERT INTO students (name, department, marks) VALUES
('Rajesh', 'ECE', 85),
('Priya', 'CSE', 92),
('Amit', 'Mechanical', 76),
('Suchi', 'ECE', 90);

-- Fetch all students
SELECT * FROM students;

-- Top 2 students
SELECT name, marks FROM students ORDER BY marks DESC LIMIT 2;

-- Department-wise average marks
SELECT department, AVG(marks) FROM students GROUP BY department;
