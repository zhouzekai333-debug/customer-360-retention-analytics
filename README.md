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

### Data Audit

Completed checks for:

- Missing Customer ID
- Negative Quantity
- Cancellation / return transactions
- Inventory / operational adjustments
- Zero and negative Price
- Bad-debt adjustments
- Exact duplicates
- Transaction classification using `CASE WHEN`

### Power Query

Implemented:

- Data type standardisation
- `TransactionType`
- `Revenue`
- `CustomerAnalysisFlag`
- `SalesAnalysisFlag`
- Exact duplicate removal
- SQL-to-Power Query reconciliation

The 2010–2011 cleaned transaction table contains **536,642 rows**, reconciling to:

`541,910 source rows - 5,268 duplicate rows = 536,642 cleaned rows`

### Power BI / DAX

Initial measures include:

- Gross Sales
- Return Amount
- Net Sales
- Orders
- Customers
- AOV
- Previous Month Net Sales
- MoM Net Sales Growth %
- Orders per Customer

A date dimension (`dim_date`) has also been created and related to the cleaned transaction fact table.

## Initial insight

From August to November 2011, net sales increased from approximately **£692K to £1.46M**. The increase was primarily volume- and engagement-driven: orders rose from **1,280 to 2,657**, active customers from **935 to 1,664**, and orders per customer from **1.37 to 1.60**, while AOV declined slightly from about **£583 to £566**.

This suggests that late-year growth was driven by a larger and more active customer base rather than higher basket values.

## Repository structure

```text
customer-360-retention-analytics/
├── README.md
├── sql/
│   └── 01_data_audit.sql
├── docs/
│   └── 01_data_audit.md
└── powerbi/
    └── (Power BI files and screenshots will be added later)
```

## Next steps

- Finish cleaned analytical table logic in SQL
- Standardise InvoiceDate handling
- Define formal KPI business rules
- Build Customer 360 dashboard pages
- Add segmentation / RFM
- Add retention analysis
- Document final business recommendations
