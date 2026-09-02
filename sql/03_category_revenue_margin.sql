-- ============================================================
-- Q3. Which product categories drive the most revenue and profit margin?
-- Skills: joins, aggregation, GROUP BY/HAVING, derived metrics
-- ============================================================

SELECT
    p.product_category,
    COUNT(DISTINCT oi.order_id)                                   AS orders_containing_category,
    SUM(oi.quantity)                                               AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)                     AS gross_revenue,
    ROUND(SUM(oi.quantity * p.unit_cost), 2)                       AS total_cost,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.unit_cost)), 2)     AS gross_profit,
    ROUND(
        100.0 * SUM(oi.quantity * (oi.unit_price - p.unit_cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0), 1
    )                                                               AS margin_pct
FROM order_items oi
JOIN products p  ON p.product_id = oi.product_id
JOIN orders o    ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'returned')
GROUP BY p.product_category
HAVING SUM(oi.quantity * oi.unit_price) > 0
ORDER BY gross_revenue DESC;
