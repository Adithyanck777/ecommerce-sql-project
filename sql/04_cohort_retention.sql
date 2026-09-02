-- ============================================================
-- Q4. Customer repeat-purchase rate / retention by cohort
-- Skills: self-joins, CTEs, window functions, date-diff math
-- Cohort = the calendar month of a customer's FIRST order.
-- month_offset = number of months between the cohort month and each
-- subsequent order month for that customer (0 = the cohort month itself).
-- ============================================================

WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE order_status NOT IN ('canceled', 'returned')
    GROUP BY customer_id
),
cohort_orders AS (
    SELECT
        o.customer_id,
        strftime('%Y-%m', f.first_order_date) AS cohort_month,
        strftime('%Y-%m', o.order_date)        AS order_month,
        (
            (CAST(strftime('%Y', o.order_date) AS INTEGER) - CAST(strftime('%Y', f.first_order_date) AS INTEGER)) * 12
            + (CAST(strftime('%m', o.order_date) AS INTEGER) - CAST(strftime('%m', f.first_order_date) AS INTEGER))
        ) AS month_offset
    FROM orders o
    JOIN first_order f ON f.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'returned')
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
    FROM cohort_orders
    WHERE month_offset = 0
    GROUP BY cohort_month
)
SELECT
    co.cohort_month,
    cs.cohort_customers,
    co.month_offset,
    COUNT(DISTINCT co.customer_id)                                        AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT co.customer_id) / cs.cohort_customers, 1) AS retention_pct
FROM cohort_orders co
JOIN cohort_size cs ON cs.cohort_month = co.cohort_month
GROUP BY co.cohort_month, cs.cohort_customers, co.month_offset
ORDER BY co.cohort_month, co.month_offset;

-- Overall repeat-purchase rate: what % of all customers placed 2+ orders?
SELECT
    COUNT(DISTINCT customer_id)                                              AS total_customers,
    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END)           AS repeat_customers,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END)
        / COUNT(DISTINCT customer_id), 1
    )                                                                          AS repeat_purchase_rate_pct
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    WHERE order_status NOT IN ('canceled', 'returned')
    GROUP BY customer_id
);
