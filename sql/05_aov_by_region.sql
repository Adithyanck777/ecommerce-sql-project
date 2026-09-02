-- ============================================================
-- Q5. What's the average order value (AOV) and how does it vary
-- by region / customer segment?
-- Skills: joins, aggregation, CASE segmentation
-- ============================================================

-- AOV by region
SELECT
    c.region,
    COUNT(DISTINCT o.order_id)                       AS orders,
    ROUND(SUM(o.order_total), 2)                     AS total_revenue,
    ROUND(AVG(o.order_total), 2)                      AS avg_order_value
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status NOT IN ('canceled', 'returned')
GROUP BY c.region
ORDER BY avg_order_value DESC;

-- AOV by customer segment (segmented by lifetime order count)
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*)          AS order_count,
        AVG(order_total)  AS avg_order_value
    FROM orders
    WHERE order_status NOT IN ('canceled', 'returned')
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional (2-3 orders)'
        WHEN order_count BETWEEN 4 AND 7 THEN 'Frequent (4-7 orders)'
        ELSE 'Loyal (8+ orders)'
    END                                            AS segment,
    COUNT(*)                                       AS customers,
    ROUND(AVG(avg_order_value), 2)                 AS avg_order_value
FROM customer_orders
GROUP BY segment
ORDER BY avg_order_value DESC;
