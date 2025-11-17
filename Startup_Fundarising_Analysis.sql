/*******************************************************************************
** Crunchbase Startup Fundraising Analysis Script
**
** This script defines the schema, inserts sample data, and provides
** five essential SQL queries for analyzing startup funding deals.
*******************************************************************************/

-- =============================================================================
-- SCHEMA DEFINITION (Uncommented for a runnable script)
-- =============================================================================

-- 1. COMPANIES: Basic company information
CREATE TABLE companies (
    company_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100),
    founded_year INT
);

-- 2. FUNDING_ROUNDS: Details of each funding round
CREATE TABLE funding_rounds (
    round_id INT PRIMARY KEY,
    company_id INT REFERENCES companies(company_id),
    round_type VARCHAR(50) NOT NULL, -- e.g., 'Seed', 'Series A', 'Venture', 'IPO'
    raised_amount_usd BIGINT,        -- Amount in USD (use BIGINT for large numbers)
    announced_date DATE
);

-- 3. INVESTORS: Details about the investors
CREATE TABLE investors (
    investor_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50),                -- e.g., 'VC Firm', 'Angel', 'Corporate'
    headquarters_city VARCHAR(100)
);

-- 4. INVESTMENTS: Linking investors to funding rounds (many-to-many relationship)
CREATE TABLE investments (
    investment_id INT PRIMARY KEY,
    round_id INT REFERENCES funding_rounds(round_id),
    investor_id INT REFERENCES investors(investor_id)
);


-- =============================================================================
-- SAMPLE DATA INSERTION
-- =============================================================================

-- COMPANIES
INSERT INTO companies (company_id, name, industry, city, country, founded_year) VALUES
(101, 'FutureGrid Energy', 'Energy Tech', 'San Francisco', 'USA', 2018),
(102, 'MediCare AI', 'Healthcare', 'London', 'UK', 2020),
(103, 'PixelWorks Studio', 'Gaming', 'Tokyo', 'Japan', 2019),
(104, 'AgriFlow Robotics', 'AgriTech', 'Berlin', 'Germany', 2021),
(105, 'GlobalFin Platform', 'FinTech', 'Singapore', 'Singapore', 2017);

-- INVESTORS
INSERT INTO investors (investor_id, name, type, headquarters_city) VALUES
(201, 'Silicon Valley Capital', 'VC Firm', 'Menlo Park'),
(202, 'EuroTech Ventures', 'VC Firm', 'London'),
(203, 'Rising Sun Angel Group', 'Angel', 'Tokyo'),
(204, 'Corporate Growth Fund', 'Corporate', 'New York'),
(205, 'Deep Impact LP', 'VC Firm', 'San Francisco');

-- FUNDING_ROUNDS
INSERT INTO funding_rounds (round_id, company_id, round_type, raised_amount_usd, announced_date) VALUES
-- FutureGrid Energy (101)
(301, 101, 'Seed', 2500000, '2019-03-15'),
(302, 101, 'Series A', 15000000, '2020-09-20'),
(303, 101, 'Series B', 65000000, '2022-05-10'),

-- MediCare AI (102)
(304, 102, 'Seed', 1000000, '2021-01-05'),
(305, 102, 'Series A', 12000000, '2022-03-01'),

-- PixelWorks Studio (103)
(306, 103, 'Venture', 450000000, '2023-11-25'), -- Large Venture round (QUERY 1)

-- AgriFlow Robotics (104)
(307, 104, 'Seed', 3000000, '2021-12-10'),
(308, 104, 'Series A', 18000000, '2023-04-01'),

-- GlobalFin Platform (105)
(309, 105, 'Venture', 150000000, '2021-08-01'),
(310, 105, 'Venture', 2000000000, '2024-01-15'); -- Massive round (QUERY 1)

-- INVESTMENTS (Linking rounds to investors)
INSERT INTO investments (investment_id, round_id, investor_id) VALUES
(401, 301, 203), -- FutureGrid Seed: Rising Sun
(402, 302, 201), -- FutureGrid Series A: Silicon Valley Capital
(403, 303, 205), -- FutureGrid Series B: Deep Impact
(404, 304, 202), -- MediCare Seed: EuroTech Ventures
(405, 305, 202), -- MediCare Series A: EuroTech Ventures
(406, 306, 204), -- PixelWorks Venture: Corporate Growth Fund
(407, 307, 201), -- AgriFlow Seed: Silicon Valley Capital
(408, 308, 201), -- AgriFlow Series A: Silicon Valley Capital (Most active: 3 deals)
(409, 309, 205), -- GlobalFin Venture: Deep Impact
(410, 310, 204), -- GlobalFin Massive: Corporate Growth Fund
(411, 310, 205); -- GlobalFin Massive: Deep Impact

-- =============================================================================
-- 5 KEY FUNDRAISING ANALYSIS QUERIES
-- =============================================================================

-- QUERY 1: Top 10 Largest Funding Rounds Ever
-- Purpose: Identify the biggest single capital injections globally.
-------------------------------------------------------------------------------
SELECT
    c.name AS company_name,
    c.country,
    f.round_type,
    f.raised_amount_usd / 1000000 AS raised_amount_millions_usd,
    f.announced_date
FROM
    funding_rounds f
JOIN
    companies c ON f.company_id = c.company_id
ORDER BY
    f.raised_amount_usd DESC
LIMIT 10;


-- QUERY 2: Total Funds Raised by Industry (Top 10)
-- Purpose: Understand which industries attract the most capital overall.
-------------------------------------------------------------------------------
SELECT
    c.industry,
    COUNT(f.round_id) AS total_rounds,
    SUM(f.raised_amount_usd) / 1000000000.0 AS total_raised_billions_usd
FROM
    companies c
JOIN
    funding_rounds f ON c.company_id = f.company_id
GROUP BY
    c.industry
HAVING
    SUM(f.raised_amount_usd) > 5000000000 -- Only include industries that raised over $5 Billion
ORDER BY
    total_raised_billions_usd DESC
LIMIT 10;


-- QUERY 3: Average Series A Round Size by Country
-- Purpose: Analyze regional differences in early-stage funding valuations.
-------------------------------------------------------------------------------
SELECT
    c.country,
    COUNT(f.round_id) AS series_a_count,
    AVG(f.raised_amount_usd) / 1000000 AS average_series_a_millions_usd
FROM
    funding_rounds f
JOIN
    companies c ON f.company_id = c.company_id
WHERE
    f.round_type = 'Series A'
GROUP BY
    c.country
HAVING
    COUNT(f.round_id) >= 1 -- Changed to >= 1 for the small sample data set
ORDER BY
    average_series_a_millions_usd DESC;


-- QUERY 4: Most Active Investors (by deal count)
-- Purpose: Identify the VC firms and individuals with the highest volume of deals.
-------------------------------------------------------------------------------
SELECT
    i.name AS investor_name,
    i.type AS investor_type,
    i.headquarters_city,
    COUNT(t.investment_id) AS total_investments
FROM
    investors i
JOIN
    investments t ON i.investor_id = t.investor_id
GROUP BY
    i.investor_id, i.name, i.type, i.headquarters_city
ORDER BY
    total_investments DESC
LIMIT 15;


-- QUERY 5: Companies that successfully raised both Seed and Series A rounds
-- Purpose: Track early-stage company progression and funding efficiency.
-------------------------------------------------------------------------------
SELECT
    c.name,
    c.industry,
    MIN(CASE WHEN f.round_type = 'Seed' THEN f.announced_date ELSE NULL END) AS first_seed_date,
    MAX(CASE WHEN f.round_type = 'Series A' THEN f.announced_date ELSE NULL END) AS latest_series_a_date
FROM
    companies c
JOIN
    funding_rounds f ON c.company_id = c.company_id
WHERE
    f.round_type IN ('Seed', 'Series A')
GROUP BY
    c.company_id, c.name, c.industry
HAVING
    -- Check that the company has at least one Seed round AND at least one Series A round
    SUM(CASE WHEN f.round_type = 'Seed' THEN 1 ELSE 0 END) > 0 AND
    SUM(CASE WHEN f.round_type = 'Series A' THEN 1 ELSE 0 END) > 0
ORDER BY
    c.name;
