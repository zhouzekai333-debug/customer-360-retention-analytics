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
- RFM segmentation
- Cross-year customer lifecycle analysis
- Business insight generation and CRM decision support

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

The project currently uses **2010–2011 as the main behavioural analysis period** and **2009–2010 as a historical lookback** for cross-year lifecycle status.

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
- Customer-level `dim_customer_rfm`
- Historical-customer lookup `dim_previous_year_customers`
- Lifecycle merge logic

The 2010–2011 cleaned transaction table contains **536,642 rows**, reconciling to:

`541,910 source rows - 5,268 duplicate rows = 536,642 cleaned rows`

### Power BI / DAX

The current model contains a dedicated `dim_date` date table and an active one-to-many relationship to the cleaned transaction fact table.

Measures include:

- Gross Sales
- Return Amount
- Net Sales
- Customer Orders
- Customers
- Sales Orders
- Sales AOV
- Previous Month Net Sales
- MoM Net Sales Growth %
- Orders per Customer

Current KPI results are approximately **£10.63M Gross Sales**, **-£893.98K Return Amount**, **£9.74M Net Sales** and **£532.65 Sales AOV**.

The working Power BI file is available as [`Customer_360_Retention_Analytics.pbix`](Customer_360_Retention_Analytics.pbix).

Detailed modelling, DAX and analysis notes are documented in [`docs/02_power_bi_analysis.md`](docs/02_power_bi_analysis.md).

## Insight #1 — Late-year sales acceleration

From August to November 2011, net sales increased from approximately **£692K to £1.46M**. Orders rose from **1,280 to 2,657**, active customers from **935 to 1,664**, and orders per customer from **1.37 to 1.60**, while AOV declined slightly from about **£583 to £566**.

**The Aug–Nov sales acceleration was primarily volume- and engagement-driven rather than basket-value-driven.**

The analysis intentionally avoids attributing this pattern to a specific cause such as Christmas demand without additional evidence.

## RFM customer segmentation

The 2010–2011 customer-analysis population contains **4,338 customers**.

RFM scoring was initially tested with quartiles. QA showed that `NTILE(4)` split customers with identical Recency and Frequency values across adjacent score bands, so the final method uses fixed, tie-preserving thresholds.

The six business segments are:

- Champions
- Loyal Customers
- Recent / Developing
- At Risk
- Needs Attention
- Low Priority

The segment design translates current customer behaviour and value into CRM priority rather than creating labels for all 64 R/F/M combinations.

See [`sql/02_customer_rfm_segmentation.sql`](sql/02_customer_rfm_segmentation.sql) and [`docs/03_rfm_segmentation_retention.md`](docs/03_rfm_segmentation_retention.md).

## Insight #2 — Customer value and retention priority

**Champions and Loyal Customers represent 33.5% of customers but account for 75.6% of historical revenue.** By contrast, Low Priority customers represent 30.2% of customers but only 4.2% of revenue.

The smaller At Risk group represents 1.9% of customers and shows meaningful historical value, with approximately **£2.8K average revenue**, **4.8 orders per customer** and **202 days average recency**. This makes the group a focused reactivation opportunity, not evidence of confirmed churn.

## Cross-year lifecycle analysis

Using the same valid-purchase customer definition in both annual periods:

- 2009–2010 valid customers: **4,312**
- 2010–2011 valid customers: **4,338**
- Returning across both periods: **2,772**
- New in 2010–2011: **1,566**
- Lapsed after 2009–2010: **1,540**

This gives a **64.3% cross-year continuation proxy** for Year-1 customers. It is intentionally not labelled as a formal churn/retention rate because customer cohort entry timing and observation windows have not yet been modelled.

Lifecycle status is kept separate from RFM segment:

- **RFM Segment** = current behaviour/value state
- **Lifecycle Status** = New / Returning / Lapsed across annual periods

This distinction led to renaming the earlier `New / Potential` RFM label to **Recent / Developing** after QA showed that 108 of those 252 customers were actually Returning from the prior year.

## Validation status

Passed:

- Source row reconciliation
- Transaction classification SQL ↔ Power Query
- Exact-duplicate row reconciliation
- Customer population SQL ↔ Power BI: **4,338**
- Previous-year valid customer count SQL ↔ Power BI: **4,312**

Open QA item:

- SQL currently shows Champions 780 / Loyal 671, while Power BI shows Champions 778 / Loyal 673. All other segments and the total customer population match. The two-customer discrepancy is being retained for root-cause analysis rather than forcing the outputs to match.
- Final Power BI LifecycleStatus count reconciliation is pending after correcting an accidental post-segmentation filter.

## Repository structure

```text
customer-360-retention-analytics/
├── README.md
├── Customer_360_Retention_Analytics.pbix
├── sql/
│   ├── 01_data_audit.sql
│   └── 02_customer_rfm_segmentation.sql
└── docs/
    ├── 01_data_audit.md
    ├── 02_power_bi_analysis.md
    └── 03_rfm_segmentation_retention.md
```

## Next steps

- Reconcile the two-customer Champions / Loyal difference
- Confirm Power BI lifecycle counts: Returning 2,772 / New 1,566
- Document root cause and final reconciliation result
- Build recruiter-facing Customer Segmentation / Retention dashboard page
- Add dashboard screenshots for a recruiter-friendly preview
- Continue retention and decision-logic analysis
