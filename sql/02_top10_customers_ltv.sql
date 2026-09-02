-- ============================================================
-- Q2. Who are the top 10 customers by lifetime value (LTV)?
-- Skills: aggregation, ranking window function (RANK)
-- ============================================================

WITH customer_ltv AS (
    SELECT
        c.customer_id,
        c.customer_city,
        c.customer_state,
        c.region,
        COUNT(DISTINCT o.order_id)     AS total_orders,
        ROUND(SUM(o.order_total), 2)   AS lifetime_value,
        MIN(o.order_date)              AS first_order_date,
        MAX(o.order_date)              AS last_order_date
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'returned')
    GROUP BY c.customer_id, c.customer_city, c.customer_state, c.region
)
SELECT
    RANK() OVER (ORDER BY lifetime_value DESC) AS ltv_rank,
    customer_id,
    customer_city,
    customer_state,
    region,
    total_orders,
    lifetime_value,
    ROUND(lifetime_value / NULLIF(total_orders, 0), 2) AS avg_order_value,
    first_order_date,
    last_order_date
FROM customer_ltv
ORDER BY lifetime_value DESC
LIMIT 10;
