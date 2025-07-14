-- RFM Segment Distribution Analysis
WITH rfm_data AS (
    SELECT
        customer_name,
        DATE_PART('day', (SELECT MAX(order_date) FROM superstore_orders) - MAX(order_date)) AS recency,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(sales) AS monetary
    FROM superstore_orders
    GROUP BY customer_name
),

rfm_quartiles AS (
    SELECT
        customer_name,
        recency,
        frequency,
        monetary,
        5 - NTILE(5) OVER (ORDER BY recency) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_data
),

rfm_segments AS (
    SELECT
        customer_name,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 2 THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score <= 2 AND m_score <= 2 THEN 'New Customers'
            WHEN r_score < 3 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
            WHEN r_score < 2 AND f_score >= 2 AND m_score >= 2 THEN 'Hibernating'
            WHEN r_score < 2 AND f_score < 2 AND m_score < 2 THEN 'Lost'
            ELSE 'Others'
        END AS segment
    FROM rfm_quartiles
)

-- Analyze segment distribution
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM rfm_segments
GROUP BY segment
ORDER BY customer_count DESC;