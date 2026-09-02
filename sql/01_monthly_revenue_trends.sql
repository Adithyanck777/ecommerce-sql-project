-- ============================================================
-- Q1. What are the monthly / quarterly revenue trends?
-- Skills: date grouping, aggregation, window functions (running total)
-- Note: excludes canceled/returned orders — those never fulfilled revenue.
-- ============================================================

-- Monthly revenue + order count + running (cumulative) total
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date)              AS year_month,
        COUNT(DISTINCT o.order_id)                     AS orders,
        ROUND(SUM(o.order_total), 2)                   AS revenue
    FROM orders o
    WHERE o.order_status NOT IN ('canceled', 'returned')
    GROUP BY 1
)
SELECT
    year_month,
    orders,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY year_month), 2) AS running_total_revenue,
    ROUND(revenue / NULLIF(orders, 0), 2)              AS avg_order_value
FROM monthly
ORDER BY year_month;

-- Quarterly revenue trend
WITH quarterly AS (
    SELECT
        strftime('%Y', o.order_date) || '-Q' ||
            CAST(((CAST(strftime('%m', o.order_date) AS INTEGER) - 1) / 3) + 1 AS TEXT) AS year_quarter,
        COUNT(DISTINCT o.order_id) AS orders,
        ROUND(SUM(o.order_total), 2) AS revenue
    FROM orders o
    WHERE o.order_status NOT IN ('canceled', 'returned')
    GROUP BY 1
)
SELECT * FROM quarterly ORDER BY year_quarter;
