-- ============================================================
-- Q6. Which customers haven't ordered in 90+ days (churn risk)?
-- Skills: date filtering, CASE logic, subqueries
-- "Today" is parameterized as the max order date in the dataset so
-- this query stays meaningful against a static historical dataset;
-- in production, replace with CURRENT_DATE.
-- ============================================================

WITH ref_date AS (
    SELECT MAX(order_date) AS today FROM orders
),
customer_last_order AS (
    SELECT
        c.customer_id,
        c.customer_city,
        c.customer_state,
        c.region,
        MAX(o.order_date)                              AS last_order_date,
        COUNT(o.order_id)                               AS total_orders,
        SUM(o.order_total)                              AS lifetime_value
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'returned')
    GROUP BY c.customer_id, c.customer_city, c.customer_state, c.region
)
SELECT
    clo.*,
    CAST(julianday((SELECT today FROM ref_date)) - julianday(clo.last_order_date) AS INTEGER) AS days_since_last_order,
    CASE
        WHEN julianday((SELECT today FROM ref_date)) - julianday(clo.last_order_date) >= 180 THEN 'High risk (180+ days)'
        WHEN julianday((SELECT today FROM ref_date)) - julianday(clo.last_order_date) >= 90  THEN 'At risk (90-179 days)'
        ELSE 'Active'
    END AS churn_status
FROM customer_last_order clo
WHERE julianday((SELECT today FROM ref_date)) - julianday(clo.last_order_date) >= 90
ORDER BY days_since_last_order DESC;

-- Summary: churn risk distribution + revenue at stake
WITH ref_date AS (
    SELECT MAX(order_date) AS today FROM orders
),
customer_last_order AS (
    SELECT
        c.customer_id,
        MAX(o.order_date) AS last_order_date,
        SUM(o.order_total) AS lifetime_value
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'returned')
    GROUP BY c.customer_id
)
SELECT
    CASE
        WHEN julianday((SELECT today FROM ref_date)) - julianday(last_order_date) >= 180 THEN 'High risk (180+ days)'
        WHEN julianday((SELECT today FROM ref_date)) - julianday(last_order_date) >= 90  THEN 'At risk (90-179 days)'
        ELSE 'Active (<90 days)'
    END AS churn_status,
    COUNT(*)                       AS customers,
    ROUND(SUM(lifetime_value), 2)  AS ltv_at_stake
FROM customer_last_order
GROUP BY churn_status
ORDER BY ltv_at_stake DESC;
