

-- 1. SETUP: Create a raw table to simulate the state before flattening
-- In Postgres, we use 'JSONB' for efficient JSON handling (equivalent to Snowflake VARIANT)
DROP TABLE IF EXISTS raw_advertisements;
CREATE TABLE raw_advertisements (
    json_data JSONB
);

-- 2. DUMMY DATA: Inserting a sample record to mimic the scraper output
INSERT INTO raw_advertisements (json_data)
VALUES (
    '{
        "title": "Cozy Apartment in Warsaw Center",
        "price": "3500",
        "currency": "PLN",
        "surface": "45.5",
        "location": "52.2297, 21.0122",
        "number_of_rooms": "2",
        "advertisement_type": "rent",
        "is_for_sale": "false",
        "url": "https://www.otodom.pl/pl/oferta/sample-id",
        "description": "<p>Beautiful apartment <b>near the metro</b>. <br>Available immediately.</p>"
    }'
);

-- =======================================================================================
-- 3. TRANSFORMATION (THE FLATTENING SCRIPT)
-- This query performs the specific actions mentioned in the video:
--   A. Extracts fields using JSON operators (->>)
--   B. Cleans the Description field by removing HTML tags (REGEXP_REPLACE)
--   C. Generates a unique ID (ROW_NUMBER)
-- =======================================================================================

DROP TABLE IF EXISTS flat_advertisements;

CREATE TABLE flat_advertisements AS
SELECT
    -- Generating a unique identifier for each row
    ROW_NUMBER() OVER () AS id,

    -- Extracting basic text fields (The ->> operator extracts value as text)
    json_data ->> 'title' AS title,
    
    -- Extracting and cleaning Price (Handling potential NULLs or formatting)
    -- We assume price is numeric, but keep as text first if formats vary, 
    -- or cast immediately if data is clean: (json_data ->> 'price')::NUMERIC
    json_data ->> 'price' AS price,
    
    json_data ->> 'location' AS coordinates,
    
    json_data ->> 'surface' AS surface_area,
    
    json_data ->> 'number_of_rooms' AS room_count,
    
    json_data ->> 'advertisement_type' AS ad_type,
    
    json_data ->> 'url' AS original_url,

    -- COMPLEX TRANSFORMATION: Cleaning the Description
    -- The video uses Regex to replace '<...>' tags with an empty string.
    -- In Postgres, we use REGEXP_REPLACE with the 'g' (global) flag to remove ALL tags.
    REGEXP_REPLACE(
        json_data ->> 'description', -- Source text
        '<[^>]+>',                   -- Pattern: Matches < anything >
        '',                          -- Replacement: Empty string
        'g'                          -- Flag: Global (replace all occurrences)
    ) AS clean_description

FROM
    raw_advertisements;

-- 4. VERIFICATION: Select data to confirm the structure
SELECT * FROM flat_advertisements;

-- =======================================================================================
-- EXPLANATION OF CHANGES (Snowflake -> Postgres):
-- 1. Syntax: Snowflake uses `json_col:field::string`. Postgres uses `json_col ->> 'field'`.
-- 2. Regex: Snowflake uses `REGEXP_REPLACE(col, pat, repl, 1, 0, 'i')`. 
--    Postgres uses `REGEXP_REPLACE(col, pat, repl, 'g')`.
-- 3. Types: Used JSONB which is the binary, indexed version of JSON in Postgres.
-- =======================================================================================