
-- Table schema (portable across SQL engines)
CREATE TABLE kickstarter_projects (
    ID BIGINT PRIMARY KEY,
    name TEXT,
    category VARCHAR(255),
    main_category VARCHAR(255),
    currency VARCHAR(10),
    deadline TEXT,       -- use TEXT if DATETIME not supported
    goal NUMERIC,        -- changed from DECIMAL(15,2) to NUMERIC
    launched TEXT,
    pledged NUMERIC,
    state VARCHAR(50),
    backers INT,
    country VARCHAR(10),
    usd_pledged NUMERIC
);

-- Insert sample rows
INSERT INTO kickstarter_projects
(ID, name, category, main_category, currency, deadline, goal,
 launched, pledged, state, backers, country, usd_pledged)
VALUES
(1000002330, 'The Songs of Adelaide & Abullah', 'Poetry', 'Publishing', 'GBP',
 '2015-10-09 11:36:00', 1000, '2015-08-11 12:12:28', 0, 'failed', 0, 'GB', 0),

(1000004038, 'Where is Hank?', 'Narrative Film', 'Film & Video', 'USD',
 '2013-02-26 00:20:50', 45000, '2013-01-12 00:20:50', 220, 'failed', 3, 'US', 220),

(1000007540, 'ToshiCapital Rekordz Needs Help to Complete Album', 'Music', 'Music', 'USD',
 '2012-04-16 04:24:11', 5000, '2012-03-17 03:24:11', 1, 'failed', 1, 'US', 1),

(1000011046, 'Community Film Project: The Art of Neighbourhoods', 'Film & Video', 'Film & Video', 'USD',
 '2015-08-29 01:00:00', 19500, '2015-07-04 08:35:03', 1283, 'canceled', 14, 'US', 1283),

(1000014025, 'Monarch Espresso Bar', 'Restaurants', 'Food', 'USD',
 '2016-04-01 13:38:27', 50000, '2016-02-26 13:38:27', 52375, 'successful', 224, 'US', 52375);

