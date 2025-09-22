-- Find employees with missing department assignments
SELECT * FROM employees
WHERE department_id IS NULL;