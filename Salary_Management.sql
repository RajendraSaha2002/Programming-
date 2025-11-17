/*******************************************************************************
** Salary Management Database for PostgreSQL
**
** This script sets up the schema, including Employees, Departments, Salary,
** and Leave tracking. It also defines custom PL/pgSQL functions and triggers
** to enforce business rules and automate logging.
*******************************************************************************/

-- =============================================================================
-- 0. CLEANUP (DROP FUNCTIONS AND TABLES)
--    Ensures the script can be run multiple times without error.
-- =============================================================================

-- Drop triggers first
DROP TRIGGER IF EXISTS trg_new_employee_salary ON employees;
DROP TRIGGER IF EXISTS trg_salary_change_check ON salary_components;
DROP TRIGGER IF EXISTS trg_calculate_leave_duration ON employee_leaves;
DROP TRIGGER IF EXISTS trg_log_payment_audit ON salary_payments;

-- Drop functions
DROP FUNCTION IF EXISTS set_initial_salary();
DROP FUNCTION IF EXISTS log_salary_update();
DROP FUNCTION IF EXISTS calculate_leave_days();
DROP FUNCTION IF EXISTS log_payment_audit();

-- Drop tables (in dependency order)
DROP TABLE IF EXISTS salary_payments;
DROP TABLE IF EXISTS employee_leaves;
DROP TABLE IF EXISTS salary_components;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS audit_log;


-- =============================================================================
-- 1. SCHEMA DEFINITION (DDL)
-- =============================================================================

-- Table 1: departments
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) UNIQUE NOT NULL
);

-- Table 2: employees
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    dept_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    hire_date DATE DEFAULT CURRENT_DATE,
    total_leaves_taken INT DEFAULT 0,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Table 3: salary_components (Tracks base salary and benefits history)
CREATE TABLE salary_components (
    component_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    base_salary NUMERIC(10, 2) NOT NULL,
    monthly_benefits NUMERIC(10, 2) DEFAULT 0.00,
    tax_rate NUMERIC(4, 3) DEFAULT 0.25, -- Stored as a decimal (e.g., 0.250)
    effective_date DATE NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Table 4: employee_leaves
CREATE TABLE employee_leaves (
    leave_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    leave_type VARCHAR(50) NOT NULL, -- e.g., 'Sick', 'Vacation', 'Personal'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    duration_days INT, -- Calculated by trigger
    status VARCHAR(50) DEFAULT 'Approved',
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Table 5: salary_payments (Monthly Transactions)
CREATE TABLE salary_payments (
    payment_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    pay_date DATE DEFAULT CURRENT_DATE,
    gross_pay NUMERIC(10, 2) NOT NULL,
    net_pay NUMERIC(10, 2) NOT NULL,
    tax_deducted NUMERIC(10, 2) NOT NULL,
    payment_method VARCHAR(50),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Table 6: audit_log (For tracking system events)
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    event_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    event_type VARCHAR(50),
    details TEXT
);


-- =============================================================================
-- 2. TRIGGER FUNCTIONS (PL/pgSQL)
-- =============================================================================

-- TRIGGER FUNCTION 1: New Employee Added
-- Purpose: Automatically set the initial salary component when a new employee is hired.
CREATE OR REPLACE FUNCTION set_initial_salary()
RETURNS trigger AS $$
BEGIN
    INSERT INTO salary_components (employee_id, base_salary, monthly_benefits, effective_date)
    VALUES (NEW.employee_id, 4500.00, 500.00, NEW.hire_date);

    INSERT INTO audit_log (event_type, details)
    VALUES ('New Employee', 'Employee ' || NEW.employee_id || ' (' || NEW.first_name || ' ' || NEW.last_name || ') hired. Initial salary component set.');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER FUNCTION 2: Change in Employee Salary (Logs the change)
-- Purpose: Log when a new salary component is added or updated (e.g., a raise or promotion).
CREATE OR REPLACE FUNCTION log_salary_update()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (event_type, details)
        VALUES ('Salary Change', 'New salary component created for Employee ' || NEW.employee_id ||
                '. Base: ' || NEW.base_salary || ', Benefits: ' || NEW.monthly_benefits ||
                ', Effective: ' || NEW.effective_date);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (event_type, details)
        VALUES ('Salary Update', 'Salary component ' || NEW.component_id || ' updated for Employee ' || NEW.employee_id ||
                '. Base changed from ' || OLD.base_salary || ' to ' || NEW.base_salary);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER FUNCTION 3: Leaves (Calculates duration and updates employee's total leaves)
-- Purpose: Calculate the duration in days and update the employee's total leaves taken.
CREATE OR REPLACE FUNCTION calculate_leave_days()
RETURNS trigger AS $$
DECLARE
    v_duration INT;
BEGIN
    -- Calculate duration (PostgreSQL handles DATE subtraction returning an integer for days)
    v_duration := NEW.end_date - NEW.start_date + 1;
    NEW.duration_days := v_duration;

    -- Update the employee's total leaves taken
    UPDATE employees
    SET total_leaves_taken = total_leaves_taken + v_duration
    WHERE employee_id = NEW.employee_id;

    INSERT INTO audit_log (event_type, details)
    VALUES ('Leave Recorded', 'Employee ' || NEW.employee_id || ' took ' || v_duration || ' days of leave.');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- TRIGGER FUNCTION 4: Any Transaction (Salary Payment)
-- Purpose: Log every successful salary payment transaction for audit purposes.
CREATE OR REPLACE FUNCTION log_payment_audit()
RETURNS trigger AS $$
BEGIN
    INSERT INTO audit_log (event_type, details)
    VALUES ('Payment Transaction', 'Payment ID ' || NEW.payment_id || ' recorded for Employee ' || NEW.employee_id ||
            '. Net Pay: ' || NEW.net_pay || ' paid on ' || NEW.pay_date);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- 3. TRIGGER ATTACHMENTS
-- =============================================================================

-- Trigger for New Employee Added
CREATE TRIGGER trg_new_employee_salary
AFTER INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION set_initial_salary();

-- Trigger for Change in Employee Salary (on salary_components insert/update)
CREATE TRIGGER trg_salary_change_check
AFTER INSERT OR UPDATE ON salary_components
FOR EACH ROW
EXECUTE FUNCTION log_salary_update();

-- Trigger for Leaves (on employee_leaves insert)
CREATE TRIGGER trg_calculate_leave_duration
BEFORE INSERT ON employee_leaves
FOR EACH ROW
EXECUTE FUNCTION calculate_leave_days();

-- Trigger for Any Transaction (on salary_payments insert)
CREATE TRIGGER trg_log_payment_audit
AFTER INSERT ON salary_payments
FOR EACH ROW
EXECUTE FUNCTION log_payment_audit();


-- =============================================================================
-- 4. SAMPLE DATA INSERTION (DML)
-- =============================================================================

-- DEPARTMENTS (1, 2, 3)
INSERT INTO departments (dept_name) VALUES
('Engineering'),
('Marketing'),
('Finance');

-- EMPLOYEES (1, 2, 3) - Triggers run automatically to set initial salary
INSERT INTO employees (dept_id, first_name, last_name, job_title, hire_date) VALUES
(1, 'Alice', 'Johnson', 'Software Engineer', '2022-08-15'),
(2, 'Bob', 'Smith', 'Marketing Manager', '2023-01-20'),
(3, 'Carla', 'Davis', 'Financial Analyst', '2024-05-10');

-- NOTE: Initial salary_components are inserted by the 'trg_new_employee_salary' trigger.

-- SIMULATE SALARY CHANGE (For Employee 1 - Insert new component)
-- This action fires the 'trg_salary_change_check' trigger (log_salary_update).
INSERT INTO salary_components (employee_id, base_salary, monthly_benefits, effective_date) VALUES
(1, 6000.00, 750.00, '2024-01-01');

-- EMPLOYEE LEAVES (Insert leave records)
-- This action fires the 'trg_calculate_leave_duration' trigger (calculate_leave_days).
INSERT INTO employee_leaves (employee_id, leave_type, start_date, end_date) VALUES
(1, 'Vacation', '2024-09-02', '2024-09-06'), -- 5 days
(2, 'Sick', '2024-09-20', '2024-09-20');    -- 1 day

-- SALARY PAYMENTS (Monthly Transactions)
-- This action fires the 'trg_log_payment_audit' trigger (log_payment_audit).
INSERT INTO salary_payments (employee_id, pay_date, gross_pay, net_pay, tax_deducted, payment_method) VALUES
(1, '2024-09-30', 6750.00, 5062.50, 1687.50, 'Direct Deposit'),
(3, '2024-09-30', 5000.00, 3750.00, 1250.00, 'Direct Deposit');


-- =============================================================================
-- 5. ANALYTICAL QUERIES
-- =============================================================================

-- QUERY 1: Current Employee Salaries and Total Leave Taken (Joining all core tables)
-- Purpose: Get a complete view of an employee's status and current pay.
-------------------------------------------------------------------------------
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.dept_name,
    e.job_title,
    sc.base_salary,
    sc.monthly_benefits,
    e.total_leaves_taken AS total_days_off
FROM
    employees e
JOIN
    departments d ON e.dept_id = d.dept_id
JOIN
    salary_components sc ON e.employee_id = sc.employee_id
WHERE
    -- Selects the most recent salary component (highest effective_date)
    sc.effective_date = (
        SELECT MAX(effective_date)
        FROM salary_components
        WHERE employee_id = e.employee_id
    )
ORDER BY
    e.employee_id;

-- QUERY 2: Total Gross Pay by Department for the last payment cycle
-- Purpose: Assess departmental payroll burden.
-------------------------------------------------------------------------------
SELECT
    d.dept_name,
    SUM(sp.gross_pay) AS total_gross_payroll
FROM
    salary_payments sp
JOIN
    employees e ON sp.employee_id = e.employee_id
JOIN
    departments d ON e.dept_id = d.dept_id
WHERE
    sp.pay_date = (SELECT MAX(pay_date) FROM salary_payments) -- Last payment cycle
GROUP BY
    d.dept_name
ORDER BY
    total_gross_payroll DESC;

-- QUERY 3: List all Audit Log Events
-- Purpose: Review system changes and transactions chronologically.
-------------------------------------------------------------------------------
SELECT
    event_timestamp,
    event_type,
    details
FROM
    audit_log
ORDER BY
    event_timestamp DESC;
