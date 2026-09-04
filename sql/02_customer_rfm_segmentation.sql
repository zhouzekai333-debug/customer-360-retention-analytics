-- Customer 360 & Retention Analytics
-- Day 5: Customer-level RFM, segmentation and cross-year lifecycle analysis
-- SQL dialect: SQLite

/*
Business scope
--------------
Current-year behavioural analysis: stg_retail_2010_2011
Historical lookback: stg_retail_2009_2010
Analysis date for Recency: 2011-12-10 (day after the final transaction date)

Customer purchase population:
- Customer ID is not null
- Quantity > 0
- Price > 0

Important QA note:
The current SQL RFM query below uses the staging table. Power BI builds the
customer table from fact_transactions_clean after exact-duplicate removal.
A small segment-count discrepancy remains to be reconciled before final sign-off.
*/

-- ============================================================
-- 1. Standardise SQLite text dates and aggregate to customer grain
-- ============================================================

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
        SUM(Quantity * Price) AS Revenue,
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

-- ============================================================
-- 2. Fixed RFM scoring
-- Exploratory NTILE(4) was rejected for R/F because tied values
-- were split across adjacent quartiles.
-- ============================================================

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

-- ============================================================
-- 3. Business segmentation
-- RFM segment = current behaviour/value state.
-- It is intentionally separate from cross-year lifecycle status.
-- ============================================================

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
)

SELECT
    CustomerSegment,
    COUNT(*) AS Customers,
    ROUND(SUM(Revenue), 2) AS TotalRevenue,
    ROUND(
        SUM(Revenue) * 100.0 /
        SUM(SUM(Revenue)) OVER (),
        1
    ) AS RevenueSharePct,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        1
    ) AS CustomerSharePct,
    ROUND(AVG(Revenue), 2) AS AvgCustomerRevenue,
    ROUND(AVG(Orders), 2) AS AvgOrders,
    ROUND(AVG(RecencyDays), 1) AS AvgRecencyDays
FROM customer_segments
GROUP BY CustomerSegment
ORDER BY TotalRevenue DESC;


-- ============================================================
-- 4. Cross-year customer lifecycle QA
-- Returning: valid purchase customer in both years
-- New: valid purchase customer in 2010-2011 only
-- Lapsed: valid purchase customer in 2009-2010 only
-- These are cross-year lifecycle proxies, not a formal churn model.
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
),

all_customers AS (
    SELECT [Customer ID]
    FROM customers_2009_2010
    UNION
    SELECT [Customer ID]
    FROM customers_2010_2011
),

customer_lifecycle AS (
    SELECT
        a.[Customer ID],
        CASE
            WHEN y1.[Customer ID] IS NOT NULL
             AND y2.[Customer ID] IS NOT NULL
                THEN 'Returning'
            WHEN y1.[Customer ID] IS NULL
             AND y2.[Customer ID] IS NOT NULL
                THEN 'New'
            WHEN y1.[Customer ID] IS NOT NULL
             AND y2.[Customer ID] IS NULL
                THEN 'Lapsed'
        END AS LifecycleStatus
    FROM all_customers a
    LEFT JOIN customers_2009_2010 y1
        ON a.[Customer ID] = y1.[Customer ID]
    LEFT JOIN customers_2010_2011 y2
        ON a.[Customer ID] = y2.[Customer ID]
)

SELECT
    LifecycleStatus,
    COUNT(*) AS Customers
FROM customer_lifecycle
GROUP BY LifecycleStatus
ORDER BY Customers DESC;

-- Valid-purchase lifecycle QA results observed during analysis:
-- Returning = 2,772
-- New       = 1,566
-- Lapsed    = 1,540
-- Year-1 valid customers = 4,312
-- Year-2 valid customers = 4,338
-- Year-1 customers returning in Year 2 = 64.3%
-- Year-2 customers from prior year = 63.9%
