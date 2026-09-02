-- ============================================================
-- Q8. RFM segmentation (Recency, Frequency, Monetary)
-- Skills: CTEs, window functions (NTILE), CASE bucketing
-- Each customer is scored 1 (worst) - 4 (best) on each dimension
-- using quartiles, then bucketed into a named segment.
-- ============================================================

WITH ref_date AS (
    SELECT MAX(order_date) AS today FROM orders
),
customer_rfm_raw AS (
    SELECT
        c.customer_id,
        CAST(julianday((SELECT today FROM ref_date)) - julianday(MAX(o.order_date)) AS INTEGER) AS recency_days,
        COUNT(o.order_id)                AS frequency,
        ROUND(SUM(o.order_total), 2)     AS monetary
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'returned')
    GROUP BY c.customer_id
),
scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        -- Lower recency_days is better -> reverse the quartile (5 - ntile)
        (5 - NTILE(4) OVER (ORDER BY recency_days))  AS r_score,
        NTILE(4) OVER (ORDER BY frequency)           AS f_score,
        NTILE(4) OVER (ORDER BY monetary)            AS m_score
    FROM customer_rfm_raw
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2                   THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score = 1                    THEN 'Promising / New'
        WHEN r_score = 2 AND m_score >= 3                    THEN 'At-Risk High Value'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2   THEN 'Hibernating'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM scored
ORDER BY rfm_total DESC;

-- Segment summary: size and revenue contribution
WITH ref_date AS (
    SELECT MAX(order_date) AS today FROM orders
),
customer_rfm_raw AS (
    SELECT
        c.customer_id,
        CAST(julianday((SELECT today FROM ref_date)) - julianday(MAX(o.order_date)) AS INTEGER) AS recency_days,
        COUNT(o.order_id)                AS frequency,
        ROUND(SUM(o.order_total), 2)     AS monetary
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'returned')
    GROUP BY c.customer_id
),
scored AS (
    SELECT
        customer_id, monetary,
        (5 - NTILE(4) OVER (ORDER BY recency_days))  AS r_score,
        NTILE(4) OVER (ORDER BY frequency)           AS f_score,
        NTILE(4) OVER (ORDER BY monetary)            AS m_score
    FROM customer_rfm_raw
),
segmented AS (
    SELECT
        customer_id, monetary,
        CASE
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 2                   THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score = 1                    THEN 'Promising / New'
            WHEN r_score = 2 AND m_score >= 3                    THEN 'At-Risk High Value'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2   THEN 'Hibernating'
            ELSE 'Needs Attention'
        END AS rfm_segment
    FROM scored
)
SELECT
    rfm_segment,
    COUNT(*)                      AS customers,
    ROUND(SUM(monetary), 2)       AS total_revenue,
    ROUND(100.0 * SUM(monetary) / (SELECT SUM(monetary) FROM segmented), 1) AS pct_of_revenue
FROM segmented
GROUP BY rfm_segment
ORDER BY total_revenue DESC;
