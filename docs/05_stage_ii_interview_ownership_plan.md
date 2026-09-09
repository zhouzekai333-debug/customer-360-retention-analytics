# Stage II — Interview Ownership & Commercial Analytics Plan

**Re-scoped:** 2026-09-10

## Why the portfolio is now in maintenance mode

Portfolio V1 already demonstrates an end-to-end customer analytics workflow: source reconciliation, SQL audit/cleaning logic, Power Query, Power BI/DAX, customer-level RFM, cross-year lifecycle analysis, CRM prioritisation, customer value concentration, validation and documented limitations.

The next constraint is no longer missing project breadth. The key development gaps are:

1. Independent SQL recall under interview conditions.
2. Ability to defend project choices without relying on AI-generated explanations.
3. Commercial problem structuring across revenue, pricing, CRM/retention and customer-migration cases.
4. Interview execution: understanding multi-part questions, clarifying ambiguity, answering concisely, and handling follow-up challenges.

Therefore this repository is **frozen for major new analytical modules** unless a live target job description creates a clear evidence gap.

Allowed portfolio maintenance:

- Recruiter-facing dashboard screenshots and README readability.
- Final Power BI visual polish and sync.
- Reproducibility/interview-ownership notes.
- Corrections required by QA or evidence checks.

Not currently prioritised:

- Predictive churn modelling without a valid churn label.
- Extra machine-learning modules for portfolio decoration.
- More dashboard pages without a defined recruiter/business need.

## Stage II learning allocation

Approximate learning allocation for effective study days:

- **25% — SQL technical interview practice**
- **25% — Interview + commercial business cases**
- **20% — Targeted applications and funnel review**
- **15% — Interview/workplace English**
- **10% — Portfolio maintenance**
- **5% — Explicit AI workflow practice**

AI remains a daily productivity tool, but explicit AI-learning time is intentionally limited because the current bottleneck is independent execution rather than tool adoption.

## SQL interview target

The goal is analyst-level independence, not database-engineering depth.

### Must be independently usable

- SELECT / WHERE
- AND / OR
- SUM / COUNT / AVG
- COUNT(DISTINCT ...)
- GROUP BY / HAVING
- CASE WHEN
- ORDER BY
- INNER JOIN / LEFT JOIN
- CTEs
- NULL handling
- Date aggregation

### Interview-level working knowledge

- ROW_NUMBER
- RANK / DENSE_RANK
- LAG
- SUM(...) OVER (...)

### Deferred unless a target JD requires it

- Recursive CTEs
- Stored procedures / triggers
- Database-engine internals
- Advanced query optimisation

## Interview ownership gates

Portfolio V1 is not considered personally owned merely because the code runs. Stage II uses four interview gates.

### Gate A — SQL

Without AI or repository access:

- Solve at least 80% of basic analyst SQL prompts.
- Build customer-level KPI queries from a schema.
- Explain JOIN direction and data grain.
- Identify common duplicate-join and denominator errors.

### Gate B — Project defence

Random 10-question project test. Pass target: **8/10** answers delivered clearly in 60–90 seconds.

Core defence topics:

- Why 2010–2011 is the main behavioural period.
- Why 2009–2010 is a historical lookback.
- Why lifecycle status is not called confirmed churn.
- Why annual customer sets are deduplicated before JOINs.
- Why NTILE(4) was rejected for tied R/F values.
- Why the RFM label changed from New / Potential to Recent / Developing.
- Why all At Risk customers were moved into Re-engage Now after the lifecycle × segment QA.
- What the legacy Power Query two-customer RFM discrepancy means.
- What business recommendation is supported by value concentration.
- What additional data would be needed in a real company environment.

### Gate C — Commercial case

Independently structure at least one case covering:

- Revenue decline
- Pricing
- Customer migration
- CRM / retention

A passing answer must connect:

**problem → analysis → evidence → recommendation → risk/assumption → next action**

### Gate D — Interview English

For multi-part or ambiguous questions:

1. Identify the competency being tested.
2. Clarify when needed.
3. Give a short structure before details.
4. Answer the actual question rather than forcing a prepared script.

## Effective Day 9–30 structure

### Days 9–12 — Technical foundation consolidation

Independent SQL writing, CTE/date logic, window functions, debugging and timed technical simulation.

### Days 13–16 — Project ownership

Customer 360 defence, telecom project business story, cross-project question selection and AI-off reconstruction.

### Days 17–20 — Commercial analytics cases

Revenue decline, pricing, customer migration and CRM/retention cases.

### Days 21–24 — Interview conversion

Recruiter/behavioural, technical/project, hiring-manager and full end-to-end mocks.

### Days 25–30 — Job-market feedback loop

Evaluate roles using:

1. **Match Score** — likelihood of getting an interview now.
2. **Career Capital Score** — commercial/revenue exposure, stakeholder partnering, project ownership, decision responsibility and domain depth.
3. **AI Resilience** — whether the role is mainly execution/reporting or sits closer to business decisions and ownership.

Use actual application funnel data to identify the biggest bottleneck and direct the next learning block there.

## Target career direction

Primary long-term direction:

- Commercial Analyst
- Pricing Analyst
- Revenue / Sales Operations Analyst
- Customer Insights / Customer Strategy Analyst
- CRM / Retention Analyst

Secondary options:

- Product Analyst
- Business Performance Analyst
- Commercial Planning Analyst
- Marketing Analytics roles with meaningful decision/stakeholder responsibility

Execution-heavy reporting / dashboard / data-maintenance roles remain valid entry points, but should not become the intended 2–3 year destination.

## Final principle

The portfolio was built with AI assistance, so Stage II does not attempt to hide or reverse that. The goal is to make the work defensible and personally reproducible:

> Use AI aggressively at work; prove enough independent technical and commercial judgement to remain in control of the analysis.
