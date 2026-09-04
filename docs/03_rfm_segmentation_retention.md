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

The 2010–2011 customer population contains **4,338 customers**, matching the Power BI customer population.

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

## Power BI implementation status

A referenced `dim_customer_rfm` query has been created from `fact_transactions_clean` with:

- Revenue
- Distinct Orders
- LastPurchaseDate
- RecencyDays
- R_Score
- F_Score
- M_Score
- CustomerSegment
- LifecycleStatus merge logic using `dim_previous_year_customers`

Historical-customer Power Query QA reconciled to SQL at **4,312 unique valid customers**.

### Open reconciliation item

Power BI currently shows:

- Champions: **778**
- Loyal Customers: **673**

while the current SQL staging-based segmentation shows:

- Champions: **780**
- Loyal Customers: **671**

All other segment counts match and the total population remains **4,338**. This two-customer discrepancy is intentionally left open for root-cause analysis rather than forcing the outputs to match. A likely area to test is the difference between staging-based SQL aggregation and Power BI aggregation after exact-duplicate removal.

Power BI lifecycle count QA is also pending final refresh after removal of an accidental post-segmentation filter.

## Next QA steps

1. Reconcile the two-customer Champions / Loyal difference.
2. Confirm Power BI lifecycle counts equal Returning 2,772 and New 1,566.
3. Document the root cause and correction.
4. Build the recruiter-facing segmentation / retention dashboard page only after reconciliation passes.
