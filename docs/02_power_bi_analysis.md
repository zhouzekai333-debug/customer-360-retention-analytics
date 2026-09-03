# Power BI Analysis — Customer 360 & Retention Analytics

## Scope

The current Power BI model focuses on the **2010–2011** worksheet of the UCI Online Retail II dataset. SQL audit results are used as QA benchmarks so that Power Query transformations can be reconciled against the staging data.

## Power Query transformation

### Data types

- Invoice — Text
- StockCode — Text
- Description — Text
- Quantity — Whole Number
- InvoiceDate — Date/Time
- Price — Decimal Number
- Customer ID — Text
- Country — Text

### Transaction classification

```powerquery
if [Quantity] < 0 and Text.StartsWith([Invoice], "C") then "Cancellation"
else if [Quantity] < 0 and not Text.StartsWith([Invoice], "C") then "Adjustment"
else if [Quantity] > 0 then "Sale"
else "Other"
```

QA reconciliation:

| Transaction Type | Rows |
|---|---:|
| Sale | 531,286 |
| Cancellation | 9,288 |
| Adjustment | 1,336 |
| **Total** | **541,910** |

These counts match the SQL audit exactly.

### Revenue

Row-level revenue is calculated as:

```text
Revenue = Quantity × Price
```

This preserves negative revenue on cancellation transactions so that returns can reduce Net Sales.

### Analytical populations

Two flags are maintained because sales reporting and customer-level analysis require different populations.

**CustomerAnalysisFlag** is used for Customer 360, customer KPIs, RFM and segmentation. Transactions without an identifiable customer, cancellations, operational adjustments, bad debt and invalid prices are excluded from the customer purchase population.

**SalesAnalysisFlag** is used for revenue reporting. Valid cancellations remain included so their negative revenue reduces Net Sales, while operational adjustments, bad debt and invalid-price records are excluded.

### Exact duplicate removal

A referenced query named `fact_transactions_clean` was created. Exact duplicates were removed using the original eight source fields only:

- Invoice
- StockCode
- Description
- Quantity
- InvoiceDate
- Price
- Customer ID
- Country

Reconciliation:

```text
541,910 source rows
- 5,268 excess exact duplicate rows
= 536,642 cleaned rows
```

The cleaned Power Query result therefore reconciles to the SQL duplicate audit.

### Date field

`TransactionDate` was derived from `InvoiceDate` as a date-only field. The original Date/Time field is retained.

## Data model

A dedicated date dimension was created:

```DAX
dim_date =
CALENDAR(
    MIN(fact_transactions_clean[TransactionDate]),
    MAX(fact_transactions_clean[TransactionDate])
)
```

Additional fields:

```DAX
Year = YEAR(dim_date[Date])
Month = FORMAT(dim_date[Date], "MMM")
MonthNumber = MONTH(dim_date[Date])
YearMonth = FORMAT(dim_date[Date], "YYYY-MM")
```

Relationship:

```text
dim_date[Date]  1  →  *  fact_transactions_clean[TransactionDate]
```

The relationship is active, one-to-many and single-direction.

Dataset date range:

- First transaction: 1 December 2010
- Last transaction: 9 December 2011

Because December 2011 contains only nine days of data, it is treated as a partial month and is not interpreted as a comparable full month in monthly trend analysis.

## DAX measures

### Gross Sales

```DAX
Gross Sales =
CALCULATE(
    SUM(fact_transactions_clean[Revenue]),
    fact_transactions_clean[TransactionType] = "Sale",
    fact_transactions_clean[SalesAnalysisFlag] = "Include"
)
```

### Return Amount

```DAX
Return Amount =
CALCULATE(
    SUM(fact_transactions_clean[Revenue]),
    fact_transactions_clean[TransactionType] = "Cancellation",
    fact_transactions_clean[SalesAnalysisFlag] = "Include"
)
```

### Net Sales

```DAX
Net Sales =
[Gross Sales] + [Return Amount]
```

### Orders

```DAX
Orders =
CALCULATE(
    DISTINCTCOUNT(fact_transactions_clean[Invoice]),
    fact_transactions_clean[CustomerAnalysisFlag] = "Include"
)
```

### Customers

```DAX
Customers =
CALCULATE(
    DISTINCTCOUNT(fact_transactions_clean[Customer ID]),
    fact_transactions_clean[CustomerAnalysisFlag] = "Include"
)
```

### Average Order Value

```DAX
AOV =
DIVIDE(
    [Gross Sales],
    [Orders]
)
```

> **Model refinement note:** the current Gross Sales measure uses the sales-analysis population while Orders uses the customer-analysis population. Before the final dashboard is published, the denominator and numerator populations will be aligned so that AOV has a fully consistent business definition.

### Previous Month Net Sales

```DAX
Previous Month Net Sales =
CALCULATE(
    [Net Sales],
    DATEADD(dim_date[Date], -1, MONTH)
)
```

### Month-over-Month growth

```DAX
MoM Net Sales Growth % =
DIVIDE(
    [Net Sales] - [Previous Month Net Sales],
    [Previous Month Net Sales]
)
```

### Orders per Customer

```DAX
Orders per Customer =
DIVIDE(
    [Orders],
    [Customers]
)
```

## Initial KPI results

Current model results are approximately:

- Gross Sales: £10.63M
- Return Amount: -£893.98K
- Net Sales: £9.74M
- Orders: ~19K
- Customers: ~4K
- AOV: £573.66

The Power BI Return Amount differs slightly from the SQL staging cancellation amount (-£896,812.49) because the Power BI measure is calculated **after exact duplicate removal**. This is an expected pre-clean vs post-clean reconciliation difference.

## Monthly sales trend

For comparable full months, the main trend analysis focuses on **January–November 2011**.

The pattern is not a steady upward trend. Sales fluctuate through the first eight months of 2011, with June–August remaining around £0.68–£0.69M. A stronger acceleration appears from September onward, and November is the highest complete month at approximately £1.46M.

December 2011 is excluded from this interpretation because the dataset ends on 9 December.

## Driver analysis: August–November 2011

| Month | Net Sales | Orders | Customers | AOV | Orders / Customer |
|---|---:|---:|---:|---:|---:|
| 2011-08 | £692,448.52 | 1,280 | 935 | £583.42 | 1.37 |
| 2011-09 | £1,017,596.68 | 1,755 | 1,266 | £601.96 | 1.39 |
| 2011-10 | £1,069,368.23 | 1,929 | 1,364 | £596.82 | 1.41 |
| 2011-11 | £1,456,145.80 | 2,657 | 1,664 | £566.00 | 1.60 |

From August to November:

- Net Sales increased by approximately **110%**.
- Orders increased by approximately **108%**.
- Active customers increased by approximately **78%**.
- Orders per customer increased from **1.37 to 1.60**.
- AOV declined slightly by approximately **3%**.

## Insight #1 — Late-year sales acceleration

> Net sales more than doubled from £692K in August to £1.46M in November 2011. The increase was primarily driven by customer and order growth: active customers increased by approximately 78%, while orders rose by 108%. Purchase frequency also increased from 1.37 to 1.60 orders per customer, whereas AOV declined slightly by around 3%. This suggests that the late-year sales acceleration was driven by a larger and more active customer base rather than higher basket values.

### Executive summary

**The Aug–Nov sales acceleration was primarily volume- and engagement-driven rather than basket-value-driven.**

This analysis describes the observed growth drivers. It does not infer an unsupported causal explanation such as seasonality or Christmas demand without additional evidence.
