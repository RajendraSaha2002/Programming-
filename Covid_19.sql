
-- 1. SETUP: Create Tables
-- In the video, these tables are imported from Excel/CSV. 
-- We define the schema here to match the columns used in the queries.

DROP TABLE IF EXISTS covid_vaccinations;
DROP TABLE IF EXISTS covid_deaths;

CREATE TABLE covid_deaths (
    iso_code VARCHAR(10),
    continent VARCHAR(50),
    location VARCHAR(50),
    date DATE,
    population BIGINT,
    total_cases BIGINT,
    new_cases INT,
    total_deaths INT,
    new_deaths INT
);

CREATE TABLE covid_vaccinations (
    iso_code VARCHAR(10),
    continent VARCHAR(50),
    location VARCHAR(50),
    date DATE,
    new_vaccinations INT,
    total_vaccinations BIGINT
);

-- 2. DUMMY DATA (For Testing)
-- Inserting sample data to make the queries below runnable.
INSERT INTO covid_deaths (iso_code, continent, location, date, population, total_cases, new_cases, total_deaths, new_deaths) VALUES
('AFG', 'Asia', 'Afghanistan', '2020-02-24', 38928341, 1, 1, NULL, NULL),
('AFG', 'Asia', 'Afghanistan', '2020-12-30', 38928341, 51526, 100, 2191, 10),
('USA', 'North America', 'United States', '2021-01-01', 331002647, 20000000, 200000, 350000, 2000),
('IND', 'Asia', 'India', '2021-01-01', 1380004385, 10300000, 15000, 150000, 200);

INSERT INTO covid_vaccinations (iso_code, continent, location, date, new_vaccinations) VALUES
('AFG', 'Asia', 'Afghanistan', '2021-01-01', 100),
('USA', 'North America', 'United States', '2021-01-01', 50000),
('IND', 'Asia', 'India', '2021-01-01', 40000);


-- =======================================================================================
-- 3. ANALYTICAL QUERIES (Step-by-Step from Video)
-- =======================================================================================

-- A. Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1, 2;


-- B. Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths::DECIMAL / total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location ILIKE '%states%' -- Filter for United States
AND total_cases > 0
ORDER BY 1, 2;


-- C. Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    (total_cases::DECIMAL / population)*100 AS percent_population_infected
FROM covid_deaths
-- WHERE location ILIKE '%states%'
ORDER BY 1, 2;


-- D. Countries with Highest Infection Rate compared to Population
SELECT 
    location, 
    population, 
    MAX(total_cases) AS highest_infection_count, 
    MAX((total_cases::DECIMAL / population))*100 AS percent_population_infected
FROM covid_deaths
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- E. Countries with Highest Death Count per Population
-- Note: 'total_deaths' in the video was originally varchar, so he cast it. 
-- In Postgres, we ensure numeric math or simple casting.
SELECT 
    location, 
    MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL -- Removing World/Continent aggregates
GROUP BY location
ORDER BY total_death_count DESC;


-- F. BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT 
    continent, 
    MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- G. GLOBAL NUMBERS
-- Aggregating data across the world per day (or total if removed date)
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths)::DECIMAL / NULLIF(SUM(new_cases),0))*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2;


-- =======================================================================================
-- 4. JOINING TABLES & ADVANCED SQL (CTE, Temp Table, Views)
-- =======================================================================================

-- H. Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
    -- , (rolling_people_vaccinated / population) * 100 -- You can't use a column you just created in the same SELECT
FROM covid_deaths dea
JOIN covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


-- I. Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
    FROM covid_deaths dea
    JOIN covid_vaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated::DECIMAL / population) * 100 AS percent_vaccinated
FROM PopvsVac;


-- J. Using Temp Table to perform Calculation on Partition By in previous query
-- Note: In Postgres, use 'CREATE TEMP TABLE'. In SQL Server (Video), it was 'CREATE TABLE #Name'
DROP TABLE IF EXISTS percent_population_vaccinated;

CREATE TEMP TABLE percent_population_vaccinated (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_people_vaccinated NUMERIC
);

INSERT INTO percent_population_vaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM covid_deaths dea
JOIN covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (rolling_people_vaccinated / population) * 100 AS percent_vaccinated
FROM percent_population_vaccinated;


-- K. Creating View to store data for later visualizations
CREATE OR REPLACE VIEW view_percent_population_vaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Query the View
SELECT * FROM view_percent_population_vaccinated;