# Customer 360 & Retention Analytics

A portfolio project focused on customer insights, CRM analytics, retention, reporting, and BI using the UCI Online Retail II dataset.

## Project objective

Build an end-to-end customer analytics workflow covering:

- SQL data audit and reconciliation
- Data cleaning and analytical population design
- Power Query transformation
- Power BI data modelling and DAX
- Customer 360 KPIs
- Sales and customer behaviour analysis
- Retention / RFM segmentation
- Business insight generation

## Dataset

**UCI Online Retail II**

Two staging tables are used:

- `stg_retail_2009_2010`
- `stg_retail_2010_2011`

Row-count reconciliation:

- 2009–2010: 525,461 rows
- 2010–2011: 541,910 rows
- Total: 1,067,371 rows

The SQL staging totals reconcile to the source dataset.

## Current progress

### SQL Data Audit

Completed checks for missing Customer ID, negative quantities, cancellations / returns, operational adjustments, zero and negative prices, bad-debt adjustments and exact duplicates.

The audit also uses `CASE WHEN` to classify transactions as Sale, Cancellation, Adjustment or Other and reconciles the classification back to the source row count.

See [`sql/01_data_audit.sql`](sql/01_data_audit.sql) and [`docs/01_data_audit.md`](docs/01_data_audit.md).

### Power Query

Implemented:

- Data type standardisation
- `TransactionType`
- `Revenue`
- `CustomerAnalysisFlag`
- `SalesAnalysisFlag`
- Exact duplicate removal
- SQL-to-Power Query reconciliation
- Date-only `TransactionDate`

The 2010–2011 cleaned transaction table contains **536,642 rows**, reconciling to:

`541,910 source rows - 5,268 duplicate rows = 536,642 cleaned rows`

### Power BI / DAX

The current model contains a dedicated `dim_date` date table and an active one-to-many relationship to the cleaned transaction fact table.

Measures currently include:

- Gross Sales
- Return Amount
- Net Sales
- Orders
- Customers
- AOV
- Previous Month Net Sales
- MoM Net Sales Growth %
- Orders per Customer

Current KPI results are approximately **£10.63M Gross Sales**, **-£893.98K Return Amount** and **£9.74M Net Sales**.

The working Power BI file is available in this repository as [`Customer_360_Retention_Analytics.pbix`](Customer_360_Retention_Analytics.pbix).

Detailed modelling, DAX and analysis notes are documented in [`docs/02_power_bi_analysis.md`](docs/02_power_bi_analysis.md).

## Insight #1 — Late-year sales acceleration

From August to November 2011, net sales increased from approximately **£692K to £1.46M**. Orders rose from **1,280 to 2,657**, active customers from **935 to 1,664**, and orders per customer from **1.37 to 1.60**, while AOV declined slightly from about **£583 to £566**.

**The Aug–Nov sales acceleration was primarily volume- and engagement-driven rather than basket-value-driven.**

The analysis intentionally avoids attributing this pattern to a specific cause such as Christmas demand without additional evidence.

## Repository structure

```text
customer-360-retention-analytics/
├── README.md
├── Customer_360_Retention_Analytics.pbix
├── sql/
│   └── 01_data_audit.sql
└── docs/
    ├── 01_data_audit.md
    └── 02_power_bi_analysis.md
```

## Next steps

- Align KPI analytical populations and finalise AOV definition
- Build Customer 360 dashboard pages
- Add customer segmentation / RFM
- Add retention analysis
- Add dashboard screenshots for recruiter-friendly preview
- Develop additional business insights and recommendations
