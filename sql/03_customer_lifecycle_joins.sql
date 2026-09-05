-- Customer 360 & Retention Analytics
-- Day 6: JOIN practice applied to cross-year customer lifecycle analysis
-- SQL dialect: SQLite
--
-- Purpose
-- -------
-- Use customer-grain JOINs rather than joining raw transaction rows directly.
-- Each annual customer CTE is reduced to one row per Customer ID before JOINs,
-- avoiding many-to-many row multiplication across transaction-level tables.
--
-- Valid-purchase customer definition:
-- - Customer ID is not null
-- - Quantity > 0
-- - Price > 0

-- ============================================================
-- 1. Returning customers
-- Business definition: valid-purchase customer appears in both years.
-- INNER JOIN keeps only the intersection of the two customer sets.
-- ============================================================

WITH customers_2010_2011 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2010_2011
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
),
customers_2009_2010 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2009_2010
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
)
SELECT
    current_year.[Customer ID]
FROM customers_2010_2011 AS current_year
INNER JOIN customers_2009_2010 AS prior_year
    ON current_year.[Customer ID] = prior_year.[Customer ID];


-- ============================================================
-- 2. New customers
-- Business definition: customer appears in 2010-2011 but not 2009-2010.
-- LEFT JOIN preserves all current-year customers; unmatched prior-year
-- records are identified with IS NULL.
-- ============================================================

WITH customers_2010_2011 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2010_2011
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
),
customers_2009_2010 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2009_2010
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
)
SELECT
    current_year.[Customer ID]
FROM customers_2010_2011 AS current_year
LEFT JOIN customers_2009_2010 AS prior_year
    ON current_year.[Customer ID] = prior_year.[Customer ID]
WHERE prior_year.[Customer ID] IS NULL;


-- ============================================================
-- 3. Lapsed customers
-- Business definition: customer appears in 2009-2010 but not 2010-2011.
-- The LEFT JOIN direction is reversed because the prior-year population
-- is now the population that must be preserved.
-- ============================================================

WITH customers_2009_2010 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2009_2010
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
),
customers_2010_2011 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2010_2011
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
)
SELECT
    prior_year.[Customer ID]
FROM customers_2009_2010 AS prior_year
LEFT JOIN customers_2010_2011 AS current_year
    ON prior_year.[Customer ID] = current_year.[Customer ID]
WHERE current_year.[Customer ID] IS NULL;


-- ============================================================
-- 4. Current-year lifecycle classification and count
-- Every 2010-2011 customer is classified as New or Returning.
-- This combines LEFT JOIN + IS NULL + CASE WHEN + GROUP BY.
-- ============================================================

WITH customers_2010_2011 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2010_2011
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
),
customers_2009_2010 AS (
    SELECT DISTINCT [Customer ID]
    FROM stg_retail_2009_2010
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
),
lifecycle AS (
    SELECT
        current_year.[Customer ID],
        CASE
            WHEN prior_year.[Customer ID] IS NULL THEN 'New'
            ELSE 'Returning'
        END AS LifecycleStatus
    FROM customers_2010_2011 AS current_year
    LEFT JOIN customers_2009_2010 AS prior_year
        ON current_year.[Customer ID] = prior_year.[Customer ID]
)
SELECT
    LifecycleStatus,
    COUNT(*) AS customer_count
FROM lifecycle
GROUP BY LifecycleStatus
ORDER BY customer_count DESC;

-- Expected QA counts from the project dataset:
-- Returning = 2,772
-- New       = 1,566


-- ============================================================
-- 5. Reusable pattern: lifecycle x RFM segment
-- Use after the customer-level RFM/segment output has been materialised
-- as a table or view named customer_segments.
-- The LEFT JOIN preserves the lifecycle population and exposes any
-- unexpected missing RFM match as NULL for QA.
-- ============================================================

/*
SELECT
    l.LifecycleStatus,
    r.CustomerSegment,
    COUNT(*) AS customer_count
FROM lifecycle AS l
LEFT JOIN customer_segments AS r
    ON l.[Customer ID] = r.[Customer ID]
GROUP BY
    l.LifecycleStatus,
    r.CustomerSegment
ORDER BY
    l.LifecycleStatus,
    customer_count DESC;
*/

-- Day 6 learning checkpoint:
-- INNER JOIN  = keep matched customers in both tables.
-- LEFT JOIN   = keep every row from the left customer set.
-- LEFT JOIN + right key IS NULL = find customers present only on the left.
-- FULL OUTER JOIN is conceptually useful for reconciliation; SQLite does not
-- support it directly in older versions, so UNION-based reconciliation is used
-- elsewhere in this project.
