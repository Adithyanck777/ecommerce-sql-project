-- ============================================================
-- Q7. What's the month-over-month (MoM) revenue growth rate?
-- Skills: window functions (LAG), CTEs
-- ============================================================

WITH monthly AS (
    SELECT
        strftime('%Y-%m', order_date) AS year_month,
        ROUND(SUM(order_total), 2)     AS revenue
    FROM orders
    WHERE order_status NOT IN ('canceled', 'returned')
    GROUP BY 1
)
SELECT
    year_month,
    revenue,
    LAG(revenue) OVER (ORDER BY year_month)              AS prior_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY year_month), 2) AS revenue_change,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY year_month), 0), 1
    )                                                       AS mom_growth_pct
FROM monthly
ORDER BY year_month;
