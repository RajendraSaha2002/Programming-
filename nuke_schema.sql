

-- 1. Reactor Telemetry (The "Black Box" Logs)
CREATE TABLE IF NOT EXISTS reactor_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    core_temp DECIMAL(10, 2),
    coolant_pressure DECIMAL(10, 2),
    control_rod_pos INT,
    valve_status VARCHAR(10), -- 'OPEN' or 'CLOSED'
    coolant_flow_rate INT     -- 0 to 100
);

-- 2. Command Queue (For SCRAM / Emergency Actions)
CREATE TABLE IF NOT EXISTS command_queue (
    id SERIAL PRIMARY KEY,
    command VARCHAR(50) NOT NULL, -- e.g., 'SCRAM', 'RESET'
    priority INT DEFAULT 1,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_executed BOOLEAN DEFAULT FALSE
);

-- 3. Seed initial state
INSERT INTO reactor_logs (core_temp, coolant_pressure, control_rod_pos, valve_status, coolant_flow_rate)
VALUES (300.00, 100.00, 50, 'OPEN', 100);