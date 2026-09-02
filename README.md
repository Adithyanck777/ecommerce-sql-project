# E-Commerce Sales & Customer Analytics
SQL-based analysis of an e-commerce platform's orders, customers, products, and payments. The project analyzes sales performance, customer behavior, and churn risk using SQL.
## Business context

You're a data analyst at a mid-size e-commerce company. Leadership wants
visibility into sales trends, top-performing products/categories, customer
purchasing behavior, and churn risk, so they can prioritize retention
spend and category investment for next quarter.

## Dataset

The project uses a synthetic e-commerce dataset based on the Olist dataset structure. The data includes customers, products, orders, order items, and payments, with 9,000 customers, 1,200 products, 26,000 orders, and 51,000+ order line items covering January 2023 to December 2024.

The dataset is generated using data/generate_data.py and stored as CSV files in data/ and a SQLite database in db/ecommerce.db.


## Schema

```
customers (customer_id PK, customer_unique_key, customer_city, customer_state, region, signup_date)
products  (product_id PK, product_category, product_name, unit_cost, list_price, weight_g)
orders    (order_id PK, customer_id FK, order_date, order_status, order_total)
order_items (order_item_id PK, order_id FK, product_id FK, quantity, unit_price, freight_value)
payments  (payment_id PK, order_id FK, payment_type, installments, payment_value)
```
Full DDL: `sql/00_schema.sql`.

## SQL scripts (`/sql`)

Each file is self-contained and answers one business question. Each query is designed to run against db/ecommerce.db.

| File | Question | Key techniques |
|------|----------|----------------|
| `01_monthly_revenue_trends.sql` | Monthly & quarterly revenue trend | date grouping, running-total window function |
| `02_top10_customers_ltv.sql` | Top 10 customers by lifetime value | aggregation, `RANK()` |
| `03_category_revenue_margin.sql` | Revenue & margin by product category | joins, `GROUP BY`/`HAVING` |
| `04_cohort_retention.sql` | Repeat-purchase rate & cohort retention | self-join-style cohort logic, CTEs |
| `05_aov_by_region.sql` | Average order value by region/segment | joins, `CASE` segmentation |
| `06_churn_risk_90days.sql` | Customers inactive 90+ days | date filtering, `CASE`, subqueries |
| `07_mom_growth_rate.sql` | Month-over-month growth rate | `LAG()` window function |
| `08_rfm_segmentation.sql` | RFM segmentation (Recency/Frequency/Monetary) | `NTILE()`, CTEs, `CASE` bucketing |

Run any file directly:
```bash
python3 -c "
import sqlite3
conn = sqlite3.connect('db/ecommerce.db')
print(conn.execute(open('sql/02_top10_customers_ltv.sql').read()).fetchall())
"
```
or open `db/ecommerce.db` in DB Browser for SQLite / DataGrip / TablePlus
and paste any script in directly.

**Porting to Postgres/MySQL:** the only SQLite-specific pieces are
`strftime()` (→ `DATE_TRUNC`/`TO_CHAR` in Postgres, `DATE_FORMAT` in MySQL)
and `julianday()` (→ plain date subtraction in Postgres, `DATEDIFF` in
MySQL). Everything else — CTEs, window functions, `NTILE`, `RANK`,
`LAG` — is standard ANSI SQL and portable as-is.

## Dashboard

`dashboard.html` is a self-contained, static dashboard (Chart.js) built
directly from the output of the SQL scripts above — no numbers are
hand-typed. Open it in any browser. It covers: monthly revenue & order
volume, revenue by category, AOV by region, churn-risk distribution, and
RFM segment revenue contribution.

## Write-up

`docs/insights_report.md` — 1-page summary of key findings and
recommendations for leadership.

## Repo structure

```
ecommerce-analytics/
├── data/
│   ├── generate_data.py       # synthetic dataset generator
│   ├── run_all.py              # runs & validates every SQL script
│   ├── dashboard_data.json     # exported query results powering dashboard.html
│   └── *.csv                   # generated raw data
├── db/
│   └── ecommerce.db            # SQLite database (customers, products, orders, order_items, payments)
├── sql/
│   ├── 00_schema.sql
│   └── 01–08_*.sql             # one file per business question
├── docs/
│   └── insights_report.md
├── dashboard.html
└── README.md
```

## Resume bullet

Analyzed 26,000+ e-commerce orders using SQL to identify revenue trends, customer segments, category performance, and churn risk; applied CTEs, window functions (RANK, LAG, NTILE), and cohort analysis, with findings presented through an interactive dashboard.
