# Stage II — Progress Log

This file records effective study-day progress for the Stage II interview-ownership plan. Study days are progress-based rather than calendar-based.

## Day 10 — SQL Ownership II: CTE, Dates & Debugging

**Completed:** 2026-09-12  
**Status:** PASS  
**Overall assessment:** ~85%

### SQL ownership completed

- Learned and explained the purpose and structure of a CTE as a temporary named result set used to break a query into smaller steps.
- Built single-layer customer KPI CTEs from a transaction-level schema.
- Built a two-layer CTE flow:
  - `customer_kpi` for customer-level revenue and distinct order counts.
  - `customer_aov` for AOV calculation and downstream filtering.
- Reconstructed customer KPIs from a blank page using:
  - `SUM(Quantity * Price)` for revenue.
  - `COUNT(DISTINCT InvoiceNo)` for order count.
  - `total_revenue / NULLIF(total_orders, 0)` for AOV.
- Practised `COUNT(*)`, `COUNT(column)`, `COUNT(DISTINCT ...)`, NULL behaviour, and divide-by-zero protection with `NULLIF`.
- Practised date filtering with safe month boundaries:
  - `>= first_day_of_month`
  - `< first_day_of_next_month`
- Practised monthly grouping logic with `DATE_TRUNC('month', InvoiceDate)`.

### Debugging gate

Passed **3/3** major debugging cases:

1. Identified over-counted orders when `COUNT(InvoiceNo)` was used at item-level grain instead of `COUNT(DISTINCT InvoiceNo)`.
2. Identified revenue inflation when an order-level table was joined one-to-many to order items and order revenue was summed after row duplication.
3. Identified the timestamp boundary problem in `InvoiceDate <= '2026-03-31'` and corrected it conceptually to `InvoiceDate < '2026-04-01'`.

### Blank-page reconstruction

Passed the customer-KPI reconstruction gate:

- CTE structure independently recalled.
- Customer grain established with `GROUP BY CustomerID`.
- Revenue, distinct orders and AOV logic independently recalled.
- Final sorting logic correct.

One recurring error remained: the requested final filter was sometimes read incorrectly (for example, filtering AOV instead of revenue). This is now treated as a question-reading issue rather than a SQL-concept issue.

### Interview transfer

Completed three short technical-English transfer exercises:

1. **CTE explanation — Pass**
   - Core frame: temporary named result set → break complex SQL into smaller steps → customer KPI → outer-query calculation.
2. **SQL vs Power BI mismatch — Pass**
   - Diagnostic frame: definition → population → grain → filter → transformation → reconcile.
3. **Why grain matters in joins — Pass**
   - Core frame: different grain → duplicated rows → inflated metrics.

### Current strengths

- Aggregation logic.
- `COUNT(DISTINCT ...)` for entity counts.
- Customer-level grain.
- CTE concept and basic multi-step use.
- NULL / `NULLIF` logic.
- Basic date boundaries.
- Common analyst SQL debugging.

### Reinforcement needed

- Read the schema before typing field names; avoid spelling mistakes such as `transactions` / `InvoiceNo`.
- Before every SQL prompt, explicitly confirm:
  1. grain,
  2. filters,
  3. KPI definition,
  4. final metric and numeric threshold.
- Continue improving spoken precision for technical terms such as CTE, KPI, grain, metric definition and reconciliation.

### Exit gate result

- Overall correctness target >=80%: **PASS**
- Independently build customer KPI CTE: **PASS**
- Diagnose 3/3 major query errors: **PASS**

**Day 10 complete. Next effective study day should start from the current Notion Stage II plan after a progress preflight.**
