/*******************************************************************************
** CIA World Factbook Data Analysis Script
**
** This script defines the schema for basic geopolitical data, inserts
** sample data for diverse countries, and provides key analytical queries.
*******************************************************************************/

-- =============================================================================
-- 1. SCHEMA DEFINITION (DDL)
-- =============================================================================

-- Table 1: countries - Basic country metadata
CREATE TABLE countries (
    country_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    continent VARCHAR(50),
    code CHAR(3) UNIQUE -- ISO 3-letter code
);

-- Table 2: geography - Physical attributes
CREATE TABLE geography (
    country_id INT PRIMARY KEY REFERENCES countries(country_id),
    total_area_sqkm BIGINT NOT NULL, -- Total area in square kilometers
    coastline_km INT,
    climate VARCHAR(50)
);

-- Table 3: population_data - Demographic metrics
CREATE TABLE population_data (
    country_id INT PRIMARY KEY REFERENCES countries(country_id),
    population BIGINT NOT NULL,
    life_expectancy_years DECIMAL(4, 1),
    birth_rate_per_1000 DECIMAL(4, 1) -- Births per 1,000 people
);

-- Table 4: economy_data - Financial metrics
CREATE TABLE economy_data (
    country_id INT PRIMARY KEY REFERENCES countries(country_id),
    gdp_usd_billion DECIMAL(10, 2),  -- Gross Domestic Product in billions USD
    unemployment_rate DECIMAL(4, 2), -- Percentage
    inflation_rate DECIMAL(4, 2)     -- Percentage
);


-- =============================================================================
-- 2. SAMPLE DATA INSERTION (DML)
-- =============================================================================

-- COUNTRIES
INSERT INTO countries (country_id, name, continent, code) VALUES
(1, 'United States', 'North America', 'USA'),
(2, 'China', 'Asia', 'CHN'),
(3, 'India', 'Asia', 'IND'),
(4, 'United Kingdom', 'Europe', 'GBR'),
(5, 'Brazil', 'South America', 'BRA'),
(6, 'Nigeria', 'Africa', 'NGA');

-- GEOGRAPHY
INSERT INTO geography (country_id, total_area_sqkm, coastline_km, climate) VALUES
(1, 9833517, 19924, 'Temperate'),
(2, 9596960, 14500, 'Diverse'),
(3, 3287263, 7000, 'Tropical Monsoon'),
(4, 243610, 12429, 'Temperate Maritime'),
(5, 8515770, 7491, 'Mostly Tropical'),
(6, 923768, 853, 'Tropical');

-- POPULATION_DATA
INSERT INTO population_data (country_id, population, life_expectancy_years, birth_rate_per_1000) VALUES
(1, 335000000, 78.5, 12.0),
(2, 1425000000, 77.1, 7.5),
(3, 1440000000, 70.4, 17.5),
(4, 67000000, 81.3, 10.5),
(5, 218000000, 76.2, 13.8),
(6, 230000000, 55.2, 37.0);

-- ECONOMY_DATA
INSERT INTO economy_data (country_id, gdp_usd_billion, unemployment_rate, inflation_rate) VALUES
(1, 27974.00, 3.80, 3.20),
(2, 17700.00, 5.20, 0.50),
(3, 3937.00, 7.80, 5.50),
(4, 3330.00, 4.20, 4.70),
(5, 2127.00, 8.50, 4.00),
(6, 510.00, 4.50, 24.50);


-- =============================================================================
-- 3. 5 KEY FACTBOOK ANALYSIS QUERIES (DQL)
-- =============================================================================

-- QUERY 1: Countries with the highest GDP per capita
-- Purpose: Measure economic output relative to population size (using calculated field).
-------------------------------------------------------------------------------
SELECT
    c.name,
    e.gdp_usd_billion,
    p.population,
    -- Calculate GDP per Capita (USD)
    (e.gdp_usd_billion * 1000000000) / p.population AS gdp_per_capita_usd
FROM
    countries c
JOIN
    economy_data e ON c.country_id = e.country_id
JOIN
    population_data p ON c.country_id = p.country_id
ORDER BY
    gdp_per_capita_usd DESC
LIMIT 5;

-- QUERY 2: Highly Populated Countries with the lowest Life Expectancy
-- Purpose: Identify large nations facing major public health challenges.
-------------------------------------------------------------------------------
SELECT
    c.name,
    c.continent,
    p.population,
    p.life_expectancy_years
FROM
    countries c
JOIN
    population_data p ON c.country_id = p.country_id
WHERE
    p.population >= 100000000 -- Filter for countries with over 100 million people
ORDER BY
    p.life_expectancy_years ASC
LIMIT 5;


-- QUERY 3: Global Population Density Rankings (Top 5)
-- Purpose: Understand which countries have the most crowded land area (using calculated field).
-------------------------------------------------------------------------------
SELECT
    c.name,
    g.total_area_sqkm,
    p.population,
    -- Calculate Density (Population per sq km)
    p.population / g.total_area_sqkm AS population_density_sqkm
FROM
    countries c
JOIN
    geography g ON c.country_id = g.country_id
JOIN
    population_data p ON c.country_id = p.country_id
ORDER BY
    population_density_sqkm DESC
LIMIT 5;


-- QUERY 4: Average Economic Stability Metrics by Continent
-- Purpose: Aggregate continent-level trends in inflation and unemployment.
-------------------------------------------------------------------------------
SELECT
    c.continent,
    COUNT(c.country_id) AS total_countries,
    AVG(e.unemployment_rate) AS avg_unemployment,
    AVG(e.inflation_rate) AS avg_inflation
FROM
    countries c
JOIN
    economy_data e ON c.country_id = e.country_id
GROUP BY
    c.continent
ORDER BY
    avg_inflation DESC;


-- QUERY 5: Countries with High Inflation AND High Unemployment (Stagflation Risk)
-- Purpose: Pinpoint economies facing simultaneous economic struggles.
-------------------------------------------------------------------------------
SELECT
    c.name,
    e.unemployment_rate,
    e.inflation_rate,
    p.birth_rate_per_1000
FROM
    countries c
JOIN
    economy_data e ON c.country_id = e.country_id
JOIN
    population_data p ON c.country_id = p.country_id
WHERE
    e.unemployment_rate > 5.00 -- Unemployment greater than 5%
    AND e.inflation_rate > 4.00 -- Inflation greater than 4%
ORDER BY
    e.inflation_rate DESC;
