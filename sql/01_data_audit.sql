-- Customer 360 & Retention Analytics
-- Data Audit Script
-- Dataset: UCI Online Retail II
-- Purpose: Validate source row counts, audit missing IDs, cancellations,
-- operational adjustments, price anomalies, duplicates, and transaction types.

-- ============================================================
-- 1. Source row-count reconciliation
-- ============================================================

SELECT COUNT(*) AS total_rows
FROM stg_retail_2009_2010;

SELECT COUNT(*) AS total_rows
FROM stg_retail_2010_2011;

-- ============================================================
-- 2. Missing Customer ID audit
-- ============================================================

SELECT COUNT(*) AS missing_customer_id
FROM stg_retail_2010_2011
WHERE [Customer ID] IS NULL;

SELECT
    Quantity,
    Price,
    Quantity * Price AS revenue
FROM stg_retail_2009_2010
LIMIT 10;

SELECT
    SUM(Quantity * Price) AS missing_customer_revenue
FROM stg_retail_2009_2010
WHERE [Customer ID] IS NULL;

SELECT
    SUM(Quantity * Price) AS known_customer_revenue
FROM stg_retail_2009_2010
WHERE [Customer ID] IS NOT NULL;

-- ============================================================
-- 3. Negative Quantity / cancellation / adjustment audit
-- ============================================================

SELECT COUNT(*) AS negative_quantity_rows
FROM stg_retail_2009_2010
WHERE Quantity < 0;

SELECT
    Invoice,
    Quantity
FROM stg_retail_2009_2010
WHERE Quantity < 0
LIMIT 10;

SELECT COUNT(*) AS negative_qty_without_c
FROM stg_retail_2009_2010
WHERE Quantity < 0
  AND Invoice NOT LIKE 'C%';

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    Price
FROM stg_retail_2009_2010
WHERE Quantity < 0
  AND Invoice NOT LIKE 'C%'
LIMIT 20;

SELECT COUNT(*) AS zero_price_negative_rows
FROM stg_retail_2009_2010
WHERE Quantity < 0
  AND Invoice NOT LIKE 'C%'
  AND Price = 0;

SELECT
    SUM(Quantity * Price) AS cancelled_value
FROM stg_retail_2009_2010
WHERE Quantity < 0
  AND Invoice LIKE 'C%';

-- ============================================================
-- 4. Price audit
-- ============================================================

SELECT COUNT(*) AS zero_price_rows
FROM stg_retail_2009_2010
WHERE Price = 0;

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    Price
FROM stg_retail_2009_2010
WHERE Price = 0
  AND Quantity >= 0
LIMIT 20;

SELECT COUNT(*) AS zero_price_missing_desc
FROM stg_retail_2009_2010
WHERE Price = 0
  AND Quantity >= 0
  AND Description IS NULL;

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    Price
FROM stg_retail_2009_2010
WHERE Price = 0
  AND Quantity >= 0
  AND Description IS NOT NULL
LIMIT 20;

SELECT COUNT(*) AS negative_price_rows
FROM stg_retail_2009_2010
WHERE Price < 0;

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    Price,
    [Customer ID]
FROM stg_retail_2009_2010
WHERE Price < 0;

-- ============================================================
-- 5. Exact duplicate audit: 2009-2010
-- Exact duplicate definition uses all 8 source fields.
-- ============================================================

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    [Customer ID],
    Country,
    COUNT(*) AS duplicate_count
FROM stg_retail_2009_2010
GROUP BY
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    [Customer ID],
    Country
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT
        Invoice,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        Price,
        [Customer ID],
        Country
    FROM stg_retail_2009_2010
    GROUP BY
        Invoice,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        Price,
        [Customer ID],
        Country
    HAVING COUNT(*) > 1
);

SELECT
    SUM(duplicate_count - 1) AS extra_duplicate_rows
FROM (
    SELECT
        COUNT(*) AS duplicate_count
    FROM stg_retail_2009_2010
    GROUP BY
        Invoice,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        Price,
        [Customer ID],
        Country
    HAVING COUNT(*) > 1
);

-- ============================================================
-- 6. 2010-2011 audit checks
-- ============================================================

SELECT COUNT(*) AS negative_quantity_rows
FROM stg_retail_2010_2011
WHERE Quantity < 0;

SELECT COUNT(*) AS negative_qty_without_c
FROM stg_retail_2010_2011
WHERE Invoice NOT LIKE 'C%'
  AND Quantity < 0;

SELECT COUNT(*) AS zero_price_negative_rows
FROM stg_retail_2010_2011
WHERE Quantity < 0
  AND Invoice NOT LIKE 'C%'
  AND Price = 0;

SELECT COUNT(*) AS zero_price_rows
FROM stg_retail_2010_2011
WHERE Price = 0;

SELECT COUNT(*) AS zero_price_missing_desc
FROM stg_retail_2010_2011
WHERE Price = 0
  AND Quantity >= 0
  AND Description IS NULL;

SELECT COUNT(*) AS negative_price_rows
FROM stg_retail_2010_2011
WHERE Price < 0;

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    Price,
    [Customer ID]
FROM stg_retail_2010_2011
WHERE Price < 0;

-- ============================================================
-- 7. Exact duplicate audit: 2010-2011
-- ============================================================

SELECT
    SUM(duplicate_count - 1) AS extra_duplicate_rows
FROM (
    SELECT
        COUNT(*) AS duplicate_count
    FROM stg_retail_2010_2011
    GROUP BY
        Invoice,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        Price,
        [Customer ID],
        Country
    HAVING COUNT(*) > 1
);

-- ============================================================
-- 8. Cancellation value: 2010-2011
-- ============================================================

SELECT
    SUM(Quantity * Price) AS revenue_cancel_record
FROM stg_retail_2010_2011
WHERE Quantity < 0
  AND Invoice LIKE 'C%';

-- ============================================================
-- 9. Transaction-type classification and reconciliation
-- ============================================================

SELECT
    transaction_type,
    COUNT(*) AS row_count
FROM (
    SELECT
        CASE
            WHEN Quantity < 0 AND Invoice LIKE 'C%' THEN 'Cancellation'
            WHEN Quantity < 0 AND Invoice NOT LIKE 'C%' THEN 'Adjustment'
            WHEN Quantity > 0 THEN 'Sale'
            ELSE 'Other'
        END AS transaction_type
    FROM stg_retail_2010_2011
)
GROUP BY transaction_type;
