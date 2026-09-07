-- Customer 360 & Retention Analytics
-- Day 8: Customer Value Concentration
-- SQL dialect: SQLite
--
-- Business question:
-- How concentrated is customer revenue among the highest-value customers?
--
-- Current-year behavioural analysis: stg_retail_2010_2011
-- Historical lookback: stg_retail_2009_2010
-- Analysis date for Recency: 2011-12-10
--
-- Valid-purchase customer definition:
-- - Customer ID is not null
-- - Quantity > 0
-- - Price > 0

WITH cleaned_dates AS (
    SELECT
        [Customer ID],
        Invoice,
        Quantity,
        Price,
        printf(
            '%04d-%02d-%02d %s',
            CAST(substr(InvoiceDate, 1, 4) AS INTEGER),
            CAST(
                substr(
                    substr(InvoiceDate, instr(InvoiceDate, '/') + 1),
                    1,
                    instr(
                        substr(InvoiceDate, instr(InvoiceDate, '/') + 1),
                        '/'
                    ) - 1
                ) AS INTEGER
            ),
            CAST(
                substr(
                    substr(
                        substr(InvoiceDate, instr(InvoiceDate, '/') + 1),
                        instr(
                            substr(InvoiceDate, instr(InvoiceDate, '/') + 1),
                            '/'
                        ) + 1
                    ),
                    1,
                    instr(
                        substr(
                            substr(InvoiceDate, instr(InvoiceDate, '/') + 1),
                            instr(
                                substr(InvoiceDate, instr(InvoiceDate, '/') + 1),
                                '/'
                            ) + 1
                        ),
                        ' '
                    ) - 1
                ) AS INTEGER
            ),
            substr(InvoiceDate, instr(InvoiceDate, ' ') + 1)
        ) AS FixedDate
    FROM stg_retail_2010_2011
),

customer_rfm AS (
    SELECT
        [Customer ID],
        COUNT(DISTINCT Invoice) AS Orders,
        ROUND(SUM(Quantity * Price), 2) AS Revenue,
        MAX(FixedDate) AS LastPurchaseDate,
        CAST(
            julianday('2011-12-10')
            - julianday(date(MAX(FixedDate)))
            AS INTEGER
        ) AS RecencyDays
    FROM cleaned_dates
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
    GROUP BY [Customer ID]
),

rfm_scored AS (
    SELECT
        *,
        CASE
            WHEN RecencyDays BETWEEN 1 AND 18 THEN 4
            WHEN RecencyDays BETWEEN 19 AND 51 THEN 3
            WHEN RecencyDays BETWEEN 52 AND 142 THEN 2
            WHEN RecencyDays >= 143 THEN 1
        END AS R_Score,
        CASE
            WHEN Orders = 1 THEN 1
            WHEN Orders = 2 THEN 2
            WHEN Orders BETWEEN 3 AND 5 THEN 3
            WHEN Orders >= 6 THEN 4
        END AS F_Score,
        CASE
            WHEN Revenue <= 307.40 THEN 1
            WHEN Revenue <= 674.52 THEN 2
            WHEN Revenue <= 1661.84 THEN 3
            ELSE 4
        END AS M_Score
    FROM customer_rfm
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN R_Score = 1
                 AND F_Score >= 3
                 AND M_Score >= 3
                THEN 'At Risk'
            WHEN R_Score = 4
                 AND F_Score >= 3
                 AND M_Score >= 3
                THEN 'Champions'
            WHEN (
                    R_Score >= 3
                    AND F_Score >= 3
                 )
                 OR (
                    R_Score = 4
                    AND F_Score = 2
                    AND M_Score = 4
                 )
                THEN 'Loyal Customers'
            WHEN R_Score = 4
                THEN 'Recent / Developing'
            WHEN R_Score <= 2
                 AND F_Score <= 2
                 AND M_Score <= 2
                THEN 'Low Priority'
            ELSE 'Needs Attention'
        END AS CustomerSegment
    FROM rfm_scored
),

prior_year_customers AS (
    SELECT DISTINCT
        [Customer ID]
    FROM stg_retail_2009_2010
    WHERE
        [Customer ID] IS NOT NULL
        AND Quantity > 0
        AND Price > 0
),

customer_360 AS (
    SELECT
        s.*,
        CASE
            WHEN p.[Customer ID] IS NULL THEN 'New'
            ELSE 'Returning'
        END AS LifecycleStatus
    FROM customer_segments AS s
    LEFT JOIN prior_year_customers AS p
        ON s.[Customer ID] = p.[Customer ID]
),

retention_decision AS (
    SELECT
        *,
        CASE
            WHEN CustomerSegment = 'At Risk'
                THEN 'Re-engage Now'
            WHEN CustomerSegment = 'Needs Attention'
                 AND LifecycleStatus = 'Returning'
                THEN 'Retention / Win-back'
            WHEN CustomerSegment = 'Needs Attention'
                 AND LifecycleStatus = 'New'
                THEN 'Nurture Next Purchase'
            WHEN CustomerSegment = 'Recent / Developing'
                THEN 'Nurture Next Purchase'
            WHEN CustomerSegment IN ('Champions', 'Loyal Customers')
                THEN 'Protect & Grow'
            WHEN CustomerSegment = 'Low Priority'
                THEN 'Low-cost Monitor'
            ELSE 'Monitor'
        END AS ActionGroup
    FROM customer_360
),

value_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY Revenue DESC
        ) AS RevenueRank,
        COUNT(*) OVER () AS TotalCustomers,
        SUM(Revenue) OVER () AS TotalRevenue
    FROM retention_decision
)

-- Cumulative customer-value concentration table.
SELECT
    'Top 1%' AS CustomerGroup,
    COUNT(*) AS Customers,
    ROUND(SUM(Revenue), 2) AS Revenue,
    ROUND(SUM(Revenue) * 100.0 / MAX(TotalRevenue), 1) AS RevenueSharePct
FROM value_ranked
WHERE RevenueRank <= ROUND(TotalCustomers * 0.01)

UNION ALL

SELECT
    'Top 5%',
    COUNT(*),
    ROUND(SUM(Revenue), 2),
    ROUND(SUM(Revenue) * 100.0 / MAX(TotalRevenue), 1)
FROM value_ranked
WHERE RevenueRank <= ROUND(TotalCustomers * 0.05)

UNION ALL

SELECT
    'Top 10%',
    COUNT(*),
    ROUND(SUM(Revenue), 2),
    ROUND(SUM(Revenue) * 100.0 / MAX(TotalRevenue), 1)
FROM value_ranked
WHERE RevenueRank <= ROUND(TotalCustomers * 0.10)

UNION ALL

SELECT
    'Top 20%',
    COUNT(*),
    ROUND(SUM(Revenue), 2),
    ROUND(SUM(Revenue) * 100.0 / MAX(TotalRevenue), 1)
FROM value_ranked
WHERE RevenueRank <= ROUND(TotalCustomers * 0.20)

UNION ALL

SELECT
    'All Customers',
    COUNT(*),
    ROUND(SUM(Revenue), 2),
    100.0
FROM value_ranked;

-- Expected QA results:
-- Top 1%  =   43 customers | £2,831,634.13 | 31.8% revenue share
-- Top 5%  =  217 customers | £4,489,400.21 | 50.4% revenue share
-- Top 10% =  434 customers | £5,469,382.46 | 61.4% revenue share
-- Top 20% =  868 customers | £6,649,437.46 | 74.6% revenue share
-- All     = 4,338 customers | £8,911,425.90 | 100.0% revenue share
--
-- Interpretation:
-- Customer value is highly concentrated. The top 5% of customers contribute
-- more than half of customer revenue, while the top 20% contribute 74.6%.
-- This supports differentiated CRM investment toward high-value customers.
