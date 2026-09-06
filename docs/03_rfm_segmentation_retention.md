# RFM Segmentation & Retention Analysis

## Scope

The customer-level analysis uses the **2010–2011** worksheet as the current behavioural period and the **2009–2010** worksheet as a historical lookback for cross-year lifecycle status.

The design intentionally separates two concepts:

- **RFM Segment** = current behaviour and value state
- **Lifecycle Status** = whether the customer is New, Returning or Lapsed across the two annual periods

This prevents labels such as "New" from being inferred only from current-period purchase frequency.

## Customer population

Customer-level RFM uses valid positive purchase transactions:

- `Customer ID IS NOT NULL`
- `Quantity > 0`
- `Price > 0`

The 2010–2011 customer population contains **4,338 customers**, matching the current Power BI customer population.

## SQLite date standardisation

`InvoiceDate` is stored as text in forms such as `2011/9/9 13:20`. Direct use of SQLite `julianday()` returned null, and text `MAX(InvoiceDate)` could sort dates lexicographically rather than chronologically.

The date string was therefore standardised to `YYYY-MM-DD HH:MM` using `printf`, `substr`, `instr` and `CAST` before calculating the last purchase date and recency.

Analysis date:

- Dataset final transaction date: **2011-12-09**
- Recency analysis date: **2011-12-10**

Recency is measured in natural days, so a purchase on 2011-12-09 has `RecencyDays = 1`.

## RFM scoring methodology

### Exploratory quartiles

`NTILE(4)` was initially evaluated. QA identified tie-splitting at Recency and Frequency boundaries. For example, customers with the same order count could receive different frequency scores.

The scoring method was therefore revised to fixed boundaries that preserve identical behaviour.

### Final scoring rules

| Score | Recency | Frequency | Monetary |
|---|---|---|---|
| 1 | 143+ days | 1 order | ≤ £307.40 |
| 2 | 52–142 days | 2 orders | £307.41–£674.52 |
| 3 | 19–51 days | 3–5 orders | £674.53–£1,661.84 |
| 4 | 1–18 days | 6+ orders | > £1,661.84 |

Frequency distribution after fixed scoring:

- F1: 1,493 customers (34.4%)
- F2: 835 (19.2%)
- F3: 1,138 (26.2%)
- F4: 872 (20.1%)

Recency distribution:

- R1: 1,085 customers (25.0%)
- R2: 1,077 (24.8%)
- R3: 1,073 (24.7%)
- R4: 1,103 (25.4%)

Monetary distribution is approximately quartile-balanced.

## Six-segment framework

The segmentation translates RFM into CRM decision logic rather than creating labels for all 64 R/F/M combinations.

| Segment | Business interpretation | CRM implication |
|---|---|---|
| Champions | Recent, frequent and high-value | Retain and reward |
| Loyal Customers | Demonstrated repeat purchasing and still relatively active | Maintain engagement / cross-sell |
| Recent / Developing | Very recent but not yet mature loyalty | Encourage repeat purchase |
| At Risk | Historically valuable but long inactive | Targeted reactivation priority |
| Needs Attention | Some value or engagement remains but activity is weaker | Re-engage |
| Low Priority | Inactive with low historical value | Lower-cost automated contact |

`Recent / Developing` replaced the earlier label `New / Potential` after cross-year QA showed that 108 of its 252 customers were actually Returning customers from the prior annual period.

## Segment QA — SQL

Observed SQL segment distribution:

| Segment | Customers | Customer Share | Revenue Share |
|---|---:|---:|---:|
| Champions | 780 | 18.0% | 54.8% |
| Loyal Customers | 671 | 15.5% | 20.8% |
| Needs Attention | 1,246 | 28.7% | 16.3% |
| Low Priority | 1,308 | 30.2% | 4.2% |
| At Risk | 81 | 1.9% | 2.6% |
| Recent / Developing | 252 | 5.8% | 1.3% |

Behavioural profiles support the business labels:

| Segment | Avg Revenue | Avg Orders | Avg Recency Days |
|---|---:|---:|---:|
| Champions | £6,257.71 | 11.48 | 8.3 |
| Loyal Customers | £2,765.41 | 5.79 | 29.1 |
| Needs Attention | £1,163.66 | 2.65 | 84.9 |
| Low Priority | £289.35 | 1.23 | 193.4 |
| At Risk | £2,816.56 | 4.77 | 202.3 |
| Recent / Developing | £469.41 | 1.61 | 10.1 |

## Insight #2 — Customer value and retention priority

**Customer value is highly concentrated.** Champions and Loyal Customers represent **33.5% of customers but 75.6% of historical revenue**. Low Priority customers represent **30.2% of customers but only 4.2% of revenue**.

The At Risk group is small at **1.9% of customers**, but has meaningful historical value: approximately **£2.8K average revenue**, **4.8 orders per customer**, and **202 days average recency**. This makes the group a focused reactivation opportunity rather than evidence of confirmed churn.

Recommended CRM direction:

- Prioritise retention investment toward Champions and Loyal Customers.
- Use targeted win-back activity for At Risk customers.
- Encourage repeat purchase among Recent / Developing customers.
- Use lower-cost automated engagement for Low Priority customers.

These are recommendations based on observed behaviour, not measured post-campaign outcomes.

## Cross-year lifecycle analysis

Valid purchase customer counts:

- 2009–2010: **4,312**
- 2010–2011: **4,338**
- Returning across both periods: **2,772**
- New in 2010–2011: **1,566**
- Lapsed after 2009–2010: **1,540**

Derived cross-year indicators:

- **64.3%** of Year-1 valid customers appear again in Year 2.
- **63.9%** of Year-2 valid customers also appeared in Year 1.

These are treated as **cross-year continuation / lapse proxies**, not a formal churn rate, because cohort entry timing and observation windows have not yet been modelled.

## Power BI implementation and reconciliation status

### Historical Power Query path

An earlier referenced `dim_customer_rfm` Power Query implementation produced:

- Champions: **778**
- Loyal Customers: **673**

while the staging-based SQL segmentation produced:

- Champions: **780**
- Loyal Customers: **671**

All other segment counts and the total population matched at **4,338**. The exact root cause of this legacy two-customer split was not proven before the 1.73 GB upstream Power Query dependency chain became a refresh-performance blocker.

This discrepancy is retained here as historical technical debt. It is **not** silently relabelled as solved.

### Current recruiter-facing retention path

For the current Day 7 Retention & CRM Actions page, the legacy `dim_customer_rfm` path is not used. The validated SQL customer-grain output is exported as a lightweight **4,338-row CSV** and loaded into Power BI as `dim_customer_action`.

The current customer-level fields include:

- Customer ID
- LifecycleStatus
- CustomerSegment
- RecencyDays
- Orders
- Revenue
- ActionGroup
- RecommendedAction

Current Power BI reconciliation matches SQL for the recruiter-facing retention analysis:

- Total customers: **4,338**
- New: **1,566**
- Returning: **2,772**
- Champions: **780**
- Loyal Customers: **671**
- Needs Attention: **1,246**
- Low Priority: **1,308**
- At Risk: **81**
- Recent / Developing: **252**

The lifecycle × segment matrix also reconciles to the same 4,338-customer total.

The current report-page KPIs reconcile to SQL:

- CRM Customers: **4,338**
- CRM Revenue: **£8.91M**
- Re-engage Customers: **81**
- Re-engage Revenue: **£228.14K**
- Protect & Grow Revenue Share: **75.6%**

This distinction matters for evidence integrity: the project documents the old unresolved path while using the reconciled SQL-derived path for the current dashboard.

## Retention decision layer

The next analytical layer combines RFM Segment with LifecycleStatus to create actionable CRM treatment groups and validates them with a lifecycle × segment sanity check.

See:

- [`../sql/04_retention_crm_action_logic.sql`](../sql/04_retention_crm_action_logic.sql)
- [`04_retention_crm_actions.md`](04_retention_crm_actions.md)

## Limitation

Lifecycle status is based on observed purchase presence across two annual periods. It should therefore be interpreted as a behavioural continuation / lapse proxy rather than confirmed churn. The dataset does not contain explicit churn labels, acquisition dates, campaign exposure, demographics, or cohort-normalised observation windows.

## Current QA status

1. SQL RFM segment totals: **PASS**.
2. Current SQL-derived Power BI retention dimension: **PASS**.
3. Lifecycle counts New 1,566 / Returning 2,772: **PASS**.
4. Current retention-page KPI reconciliation: **PASS**.
5. Legacy Power Query RFM 778/673 vs SQL 780/671 split: **documented historical technical debt; not used in the current recruiter-facing path**.
