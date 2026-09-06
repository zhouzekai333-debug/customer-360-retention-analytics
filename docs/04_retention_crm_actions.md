# Day 7 — Retention & CRM Actions

## Business question

Which customers should CRM prioritise for protection, re-engagement, win-back, nurture, or low-cost monitoring based on current RFM behaviour and cross-year lifecycle status?

## Analytical design

The Day 7 decision layer combines two separate concepts:

- **RFM Segment** — current customer behaviour/value state in 2010–2011
- **LifecycleStatus** — whether a valid-purchase customer is New or Returning relative to 2009–2010

These are deliberately kept separate before being translated into a CRM treatment group.

## CRM action logic

Five action groups were defined:

- **Protect & Grow** — Champions and Loyal Customers
- **Re-engage Now** — At Risk customers, regardless of lifecycle status
- **Retention / Win-back** — Returning customers in Needs Attention
- **Nurture Next Purchase** — New customers in Needs Attention plus Recent / Developing customers
- **Low-cost Monitor** — Low Priority customers

Recommended actions include VIP/loyalty treatment, personalised re-engagement, targeted retention incentives, second-purchase nurture, and lower-cost automated communication.

## Sanity check and rule revision

The first priority-rule version placed only Returning + At Risk customers into the highest re-engagement bucket. A lifecycle-by-segment sanity check showed 19 New + At Risk customers with meaningful historical value and long inactivity. Because `New` only means absent from the prior-year dataset—not necessarily a newly acquired customer—the rule was revised so **all At Risk customers are classified as Re-engage Now**.

This check prevented lifecycle labels from overriding stronger current-behaviour evidence.

## Final action-group results

| Action Group | Customers | Customer Share | Revenue | Revenue Share | Avg Customer Revenue | Avg Orders | Avg Recency Days |
|---|---:|---:|---:|---:|---:|---:|---:|
| Protect & Grow | 1,451 | 33.4% | £6,736,600.09 | 75.6% | £4,642.73 | 8.84 | 17.9 |
| Retention / Win-back | 798 | 18.4% | £1,071,386.25 | 12.0% | £1,342.59 | 2.98 | 88.9 |
| Nurture Next Purchase | 700 | 16.1% | £496,824.24 | 5.6% | £709.75 | 1.90 | 53.4 |
| Low-cost Monitor | 1,308 | 30.2% | £378,473.75 | 4.2% | £289.35 | 1.23 | 193.4 |
| Re-engage Now | 81 | 1.9% | £228,141.57 | 2.6% | £2,816.56 | 4.77 | 202.3 |

Total customer population: **4,338**.

## Lifecycle × RFM QA

| LifecycleStatus | At Risk | Champions | Loyal Customers | Low Priority | Needs Attention | Recent / Developing | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| New | 19 | 209 | 184 | 562 | 448 | 144 | 1,566 |
| Returning | 62 | 571 | 487 | 746 | 798 | 108 | 2,772 |
| Total | 81 | 780 | 671 | 1,308 | 1,246 | 252 | 4,338 |

## Key CRM insights

1. **Protect & Grow** represents 33.4% of customers but contributes **75.6% of customer revenue**, showing a highly concentrated core value base that should be protected and expanded.
2. **Re-engage Now** contains only **81 customers**, but represents approximately **£228K in historical revenue** and an average inactivity period of **202 days**, making it a focused high-value win-back opportunity.
3. **Low-cost Monitor** accounts for **30.2% of customers but only 4.2% of revenue**, supporting lower-cost automated CRM treatment rather than intensive retention investment.

## Power BI implementation

The previous `dim_customer_rfm` Power Query dependency chain repeatedly re-evaluated the 1.73 GB source and became a refresh-performance blocker. Instead of spending Day 7 on another long refresh attempt, the final customer-grain SQL output was exported as a lightweight **4,338-row CSV** and loaded into Power BI as `dim_customer_action`.

The intended model relationship is:

`dim_customer_action[Customer ID] (1) -> fact_transactions_clean[Customer ID] (*)`

with single-direction filtering.

Day 7 Power BI QA matched SQL:

- CRM Customers = **4,338**
- CRM Revenue = **£8.91M**
- Re-engage Customers = **81**
- Re-engage Revenue = **£228.14K**
- Protect & Grow Revenue Share = **75.6%**

The Retention & CRM Actions report page now includes KPI cards, customer count by action group, revenue by action group, a lifecycle × RFM matrix, and written CRM insights.

## Limitation

`LifecycleStatus` is a cross-year purchase-presence proxy, not a confirmed churn label. The dataset does not include explicit churn outcomes, campaign exposure, acquisition dates, demographics, or cohort-normalised observation windows. Therefore the analysis should be presented as **retention / re-engagement prioritisation**, not causal churn modelling.

## SQL evidence

See [`../sql/04_retention_crm_action_logic.sql`](../sql/04_retention_crm_action_logic.sql).
