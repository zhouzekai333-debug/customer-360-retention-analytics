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
- CRM prioritisation and decision support

The recruiter-facing decision question is:

> Which customers should CRM prioritise for protection, re-engagement, win-back, nurture, or low-cost monitoring based on observed behaviour, value, and lifecycle status?

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

The project uses **2010–2011 as the main behavioural analysis period** and **2009–2010 as a historical lookback** for cross-year lifecycle status.

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

A previous Power Query customer-dimension dependency chain was retained as a documented performance lesson because it repeatedly re-evaluated the 1.73 GB upstream source. The recruiter-facing Day 7 retention page therefore uses a lightweight SQL-derived customer dimension instead of rerunning that slow chain.

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

Current sales KPI results are approximately **£10.63M Gross Sales**, **-£893.98K Return Amount**, **£9.74M Net Sales** and **£532.65 Sales AOV**.

The Day 7 retention layer loads a SQL-derived **4,338-row** customer-grain table as `dim_customer_action`, containing LifecycleStatus, RFM segment, Recency, Orders, Revenue, ActionGroup and RecommendedAction.

Current retention-page QA:

- CRM Customers: **4,338**
- CRM Revenue: **£8.91M**
- Re-engage Customers: **81**
- Re-engage Revenue: **£228.14K**
- Protect & Grow Revenue Share: **75.6%**

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

## Cross-year lifecycle analysis

Using the same valid-purchase customer definition in both annual periods:

- 2009–2010 valid customers: **4,312**
- 2010–2011 valid customers: **4,338**
- Returning across both periods: **2,772**
- New in 2010–2011: **1,566**
- Lapsed after 2009–2010: **1,540**

This gives a **64.3% cross-year continuation proxy** for Year-1 customers. It is intentionally not labelled as a formal churn/retention rate because customer cohort entry timing and observation windows have not been modelled.

Lifecycle status is kept separate from RFM segment:

- **RFM Segment** = current behaviour/value state
- **Lifecycle Status** = New / Returning / Lapsed across annual periods

This distinction led to renaming the earlier `New / Potential` RFM label to **Recent / Developing** after QA showed that 108 of those 252 customers were actually Returning from the prior year.

### SQL JOIN applied to lifecycle analysis

JOIN practice was applied directly to the project at customer grain rather than on raw transaction rows:

- `INNER JOIN` identifies customers present in both annual periods → Returning
- `LEFT JOIN` from 2010–2011 to 2009–2010 plus `IS NULL` identifies New customers
- Reversing the `LEFT JOIN` direction identifies Lapsed customers
- `CASE WHEN` converts match status into `LifecycleStatus`

The annual customer sets are deduplicated with `SELECT DISTINCT [Customer ID]` before joining to avoid transaction-level many-to-many row multiplication.

See [`sql/03_customer_lifecycle_joins.sql`](sql/03_customer_lifecycle_joins.sql).

## Retention & CRM decision logic

RFM segment and LifecycleStatus are combined into five actionable CRM treatment groups:

- **Protect & Grow** — Champions and Loyal Customers
- **Re-engage Now** — At Risk customers
- **Retention / Win-back** — Returning customers in Needs Attention
- **Nurture Next Purchase** — New customers in Needs Attention plus Recent / Developing customers
- **Low-cost Monitor** — Low Priority customers

A lifecycle × segment sanity check exposed **19 New + At Risk** customers. Because `New` only means absent from the prior-year dataset rather than newly acquired, the initial rule was revised so **all At Risk customers are classified as Re-engage Now**.

Final action-group results:

| Action Group | Customers | Customer Share | Revenue | Revenue Share | Avg Recency Days |
|---|---:|---:|---:|---:|---:|
| Protect & Grow | 1,451 | 33.4% | £6,736,600.09 | 75.6% | 17.9 |
| Retention / Win-back | 798 | 18.4% | £1,071,386.25 | 12.0% | 88.9 |
| Nurture Next Purchase | 700 | 16.1% | £496,824.24 | 5.6% | 53.4 |
| Low-cost Monitor | 1,308 | 30.2% | £378,473.75 | 4.2% | 193.4 |
| Re-engage Now | 81 | 1.9% | £228,141.57 | 2.6% | 202.3 |

See [`sql/04_retention_crm_action_logic.sql`](sql/04_retention_crm_action_logic.sql) and [`docs/04_retention_crm_actions.md`](docs/04_retention_crm_actions.md).

## Key CRM insights

1. **Protect & Grow** represents 33.4% of customers but contributes **75.6% of customer revenue**, highlighting a concentrated core value base to protect and expand.
2. **Re-engage Now** contains only **81 customers**, but represents approximately **£228K in historical revenue** and an average inactivity period of **202 days**, making it a focused high-value win-back opportunity.
3. **Low-cost Monitor** represents **30.2% of customers but only 4.2% of revenue**, supporting lower-cost automated CRM treatment rather than intensive retention investment.

## Validation & reconciliation status

Current recruiter-facing analysis path:

- Source row reconciliation: **PASS**
- Transaction classification SQL ↔ Power Query: **PASS**
- Exact-duplicate row reconciliation: **PASS**
- Customer population SQL ↔ Power BI: **4,338 = PASS**
- Previous-year valid customer count: **4,312 = PASS**
- Lifecycle counts: **New 1,566 / Returning 2,772 = PASS**
- Current RFM segment counts: **Champions 780 / Loyal 671 / Needs Attention 1,246 / Low Priority 1,308 / At Risk 81 / Recent-Developing 252 = PASS**
- Day 7 CRM action-group customer totals: **4,338 = PASS**
- Day 7 customer-share total: **100% = PASS**
- Day 7 revenue-share total: **100% = PASS**
- Day 7 Power BI KPI QA: **4,338 customers / £8.91M revenue / 81 re-engage / £228.14K re-engage revenue / 75.6% Protect & Grow revenue share = PASS**

### Historical Power Query discrepancy

An earlier Power Query implementation of `dim_customer_rfm` showed Champions **778** / Loyal **673**, while SQL showed Champions **780** / Loyal **671**. The total population still matched at 4,338. The exact root cause of that legacy two-customer split was not proven before the upstream refresh chain became a performance blocker.

For the current recruiter-facing retention page, this legacy path is **not used**. The page uses the validated SQL customer-grain output loaded as `dim_customer_action`, and its segment, lifecycle, CRM-group and KPI counts reconcile to the SQL source. The old mismatch is retained in the documentation as historical technical debt rather than being silently overwritten or presented as resolved without evidence.

## Limitation

`LifecycleStatus` is a cross-year purchase-presence proxy, not a confirmed churn label. The dataset does not include explicit churn outcomes, campaign exposure, acquisition dates, demographics, or cohort-normalised observation windows. Recommendations therefore represent **retention / re-engagement prioritisation**, not measured campaign outcomes or causal churn modelling.

## Repository structure

```text
customer-360-retention-analytics/
├── README.md
├── Customer_360_Retention_Analytics.pbix
├── sql/
│   ├── 01_data_audit.sql
│   ├── 02_customer_rfm_segmentation.sql
│   ├── 03_customer_lifecycle_joins.sql
│   └── 04_retention_crm_action_logic.sql
└── docs/
    ├── 01_data_audit.md
    ├── 02_power_bi_analysis.md
    ├── 03_rfm_segmentation_retention.md
    └── 04_retention_crm_actions.md
```

## Next steps

- Add recruiter-facing dashboard screenshots to the README
- Sync the latest Power BI file after final visual polish
- Run the portfolio reproduction / interview-ownership test
- Conduct cohort analysis if a more appropriate observation design is added
- Build predictive churn modelling only if explicit churn labels become available
