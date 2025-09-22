-- Create tables
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE grades (
    grade_id INT PRIMARY KEY,
    student_id INT,
    subject VARCHAR(50),
    score INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Insert sample data
INSERT INTO students VALUES (101, 'Alice'), (102, 'Bob');
INSERT INTO grades VALUES (1, 101, 'Math', 85), (2, 101, 'Science', 90), (3, 102, 'Math', 78);

-- Query: Get average score for each student
SELECT s.name, AVG(g.score) AS avg_score
FROM students s
JOIN grades g ON s.student_id = g.student_id
GROUP BY s.name;