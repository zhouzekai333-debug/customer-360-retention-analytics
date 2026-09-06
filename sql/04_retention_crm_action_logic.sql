-- Customer 360 & Retention Analytics
-- Day 7: Retention analysis and CRM decision logic
-- SQL dialect: SQLite
--
-- Purpose
-- -------
-- Combine current-year RFM behaviour with cross-year lifecycle status and
-- translate the resulting customer states into actionable CRM treatment groups.
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
        END AS ActionGroup,
        CASE
            WHEN CustomerSegment = 'At Risk'
                THEN 'Personalised re-engagement offer'
            WHEN CustomerSegment = 'Needs Attention'
                 AND LifecycleStatus = 'Returning'
                THEN 'Retention reminder or targeted incentive'
            WHEN CustomerSegment = 'Needs Attention'
                 AND LifecycleStatus = 'New'
                THEN 'Encourage repeat purchase'
            WHEN CustomerSegment = 'Recent / Developing'
                THEN 'Second-purchase nurture journey'
            WHEN CustomerSegment = 'Champions'
                THEN 'VIP recognition and loyalty reward'
            WHEN CustomerSegment = 'Loyal Customers'
                THEN 'Cross-sell and loyalty programme'
            WHEN CustomerSegment = 'Low Priority'
                THEN 'Low-cost automated communication'
            ELSE 'Monitor behaviour'
        END AS RecommendedAction
    FROM customer_360
)

-- ============================================================
-- 1. CRM action-group summary with customer and revenue shares
-- ============================================================
SELECT
    ActionGroup,
    COUNT(*) AS Customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        1
    ) AS CustomerSharePct,
    ROUND(SUM(Revenue), 2) AS TotalRevenue,
    ROUND(
        SUM(Revenue) * 100.0 / SUM(SUM(Revenue)) OVER (),
        1
    ) AS RevenueSharePct,
    ROUND(AVG(Revenue), 2) AS AvgCustomerRevenue,
    ROUND(AVG(Orders), 2) AS AvgOrders,
    ROUND(AVG(RecencyDays), 1) AS AvgRecencyDays
FROM retention_decision
GROUP BY ActionGroup
ORDER BY TotalRevenue DESC;

-- Expected QA results:
-- Protect & Grow       = 1,451 customers | £6,736,600.09 | 75.6% revenue share
-- Retention / Win-back =   798 customers | £1,071,386.25 | 12.0% revenue share
-- Nurture Next Purchase=   700 customers |   £496,824.24 |  5.6% revenue share
-- Low-cost Monitor     = 1,308 customers |   £378,473.75 |  4.2% revenue share
-- Re-engage Now        =    81 customers |   £228,141.57 |  2.6% revenue share
-- Total                = 4,338 customers | £8,911,425.90


-- ============================================================
-- 2. Lifecycle x RFM segment QA matrix
-- Re-run the CTE chain above, then use this SELECT instead of the summary.
-- ============================================================
/*
SELECT
    LifecycleStatus,
    CustomerSegment,
    COUNT(*) AS Customers,
    ROUND(SUM(Revenue), 2) AS TotalRevenue,
    ROUND(AVG(Revenue), 2) AS AvgCustomerRevenue,
    ROUND(AVG(Orders), 2) AS AvgOrders,
    ROUND(AVG(RecencyDays), 1) AS AvgRecencyDays
FROM retention_decision
GROUP BY
    LifecycleStatus,
    CustomerSegment
ORDER BY
    LifecycleStatus,
    TotalRevenue DESC;
*/

-- Observed lifecycle x segment counts:
-- New:       At Risk 19 | Champions 209 | Loyal 184 | Low Priority 562 |
--            Needs Attention 448 | Recent / Developing 144 | Total 1,566
-- Returning: At Risk 62 | Champions 571 | Loyal 487 | Low Priority 746 |
--            Needs Attention 798 | Recent / Developing 108 | Total 2,772
-- Total:     At Risk 81 | Champions 780 | Loyal 671 | Low Priority 1,308 |
--            Needs Attention 1,246 | Recent / Developing 252 | Total 4,338


-- ============================================================
-- 3. Customer-grain export for Power BI
-- Re-run the CTE chain above, then use this SELECT and export to CSV.
-- ============================================================
/*
SELECT
    [Customer ID],
    LifecycleStatus,
    CustomerSegment,
    RecencyDays,
    Orders,
    Revenue,
    ActionGroup,
    RecommendedAction
FROM retention_decision;
*/

-- Power BI export QA: 4,338 customer-grain rows.
-- The lightweight CSV was loaded as dim_customer_action and related 1:* to
-- fact_transactions_clean on Customer ID to avoid re-running the slow
-- Power Query customer-dimension dependency chain.

-- Interpretation limitation:
-- LifecycleStatus is a cross-year behavioural proxy based on purchase presence.
-- It should not be presented as confirmed churn because the source data does not
-- contain an explicit churn label, campaign exposure, acquisition date, or a
-- cohort-normalised observation window.
