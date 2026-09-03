# Data Audit — Online Retail II

## Scope

The project uses two staging tables representing the two worksheets in the UCI Online Retail II dataset:

- `stg_retail_2009_2010`
- `stg_retail_2010_2011`

## Source-to-SQL reconciliation

| Period | Rows |
|---|---:|
| 2009–2010 | 525,461 |
| 2010–2011 | 541,910 |
| **Total** | **1,067,371** |

The combined SQL staging row count matches the official dataset total.

## Audit findings

### Missing Customer ID

| Period | Rows |
|---|---:|
| 2009–2010 | 107,927 |
| 2010–2011 | 135,080 |

Decision:

- Retain where useful for overall transaction / sales analysis.
- Exclude from Customer 360 and RFM analyses because the transaction cannot be attributed to an identifiable customer.

### Negative Quantity

| Period | Rows |
|---|---:|
| 2009–2010 | 12,326 |
| 2010–2011 | 10,624 |

Negative-quantity records were separated into cancellations and operational adjustments.

### Cancellation / return transactions

Classification rule:

```sql
Quantity < 0
AND Invoice LIKE 'C%'
```

| Period | Rows | Net amount |
|---|---:|---:|
| 2009–2010 | 10,205 | -630,228.94 |
| 2010–2011 | 9,288 | -896,812.49 |

Decision:

- Retain for Net Sales calculations.
- Do not treat as positive purchases in RFM.
- Analyse separately as cancellation / return behaviour.

### Non-cancellation negative quantities

```sql
Quantity < 0
AND Invoice NOT LIKE 'C%'
```

| Period | Rows |
|---|---:|
| 2009–2010 | 2,121 |
| 2010–2011 | 1,336 |

Further validation showed these records have `Price = 0`. Descriptions commonly include terms such as `lost`, `damages`, and `short`, indicating inventory / operational adjustments rather than customer returns.

Decision: exclude from normal customer sales analysis and Customer 360 / RFM.

### Price audit

`Price = 0`:

| Period | Rows |
|---|---:|
| 2009–2010 | 3,687 |
| 2010–2011 | 2,515 |

`Price < 0`:

| Period | Rows |
|---|---:|
| 2009–2010 | 3 |
| 2010–2011 | 2 |

All negative-price records have:

```text
StockCode = B
Description = Adjust bad debt
```

These are accounting adjustments rather than normal customer purchases and are excluded from normal sales KPIs and Customer 360 / RFM.

### Exact duplicates

Exact duplicates were evaluated across all eight source fields:

- Invoice
- StockCode
- Description
- Quantity
- InvoiceDate
- Price
- Customer ID
- Country

| Period | Excess duplicate rows |
|---|---:|
| 2009–2010 | 6,865 |
| 2010–2011 | 5,268 |
| **Total** | **12,133** |

Cleaning decision: retain one row from each exact duplicate group in the cleaned analytical layer while leaving raw / staging tables unchanged.

For 2010–2011, Power Query reconciliation confirms:

```text
541,910 source rows
- 5,268 excess exact duplicates
= 536,642 cleaned rows
```

## Transaction classification

```sql
CASE
    WHEN Quantity < 0 AND Invoice LIKE 'C%' THEN 'Cancellation'
    WHEN Quantity < 0 AND Invoice NOT LIKE 'C%' THEN 'Adjustment'
    WHEN Quantity > 0 THEN 'Sale'
    ELSE 'Other'
END AS transaction_type
```

Validation for 2010–2011:

| Transaction type | Rows |
|---|---:|
| Adjustment | 1,336 |
| Cancellation | 9,288 |
| Sale | 531,286 |
| **Total** | **541,910** |

The classification reconciles exactly to the staging-table row count.

## Cleaning decision summary

| Issue | Sales analysis | Customer 360 / RFM | Rationale |
|---|---|---|---|
| Missing Customer ID | Retain where appropriate | Exclude | Cannot attribute transaction to a customer |
| Cancellation / Return | Retain for Net Sales | Exclude as positive purchase | Required to measure net revenue and return behaviour |
| Bad debt adjustment | Exclude from normal KPI | Exclude | Accounting adjustment |
| Lost / damaged / short inventory | Exclude | Exclude | Operational adjustment rather than customer activity |
| Exact duplicate | Keep one copy | Keep one copy | Prevent double counting |

## Analytical note

Data cleaning and analysis filtering are treated separately. For example, the dataset ends on 9 December 2011; those December transactions are valid records and should not be deleted, but December 2011 should not be directly compared with complete months in monthly trend analysis.
