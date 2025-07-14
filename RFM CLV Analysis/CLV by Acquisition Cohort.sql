WITH customer_first_purchase AS (
    SELECT
        customer_name,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM superstore_orders
    GROUP BY customer_name
),

customer_cohort_metrics AS (
    SELECT
        cfp.customer_name,
        cfp.cohort_month,
        COUNT(DISTINCT so.order_id) AS total_orders,
        SUM(so.sales) AS total_sales,
        SUM(so.profit) AS total_profit,
        MIN(so.order_date) AS first_purchase,
        MAX(so.order_date) AS last_purchase,
        DATE_PART('day', MAX(so.order_date) - MIN(so.order_date)) AS lifespan_days
    FROM superstore_orders so
    JOIN customer_first_purchase cfp ON so.customer_name = cfp.customer_name
    GROUP BY cfp.customer_name, cfp.cohort_month
),

cohort_clv AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_name) AS customer_count,
        -- Cast to numeric before rounding
        ROUND(AVG(total_orders)::numeric, 2) AS avg_orders,
        ROUND(AVG(total_sales)::numeric, 2) AS avg_sales,
        ROUND(AVG(total_profit)::numeric, 2) AS avg_profit,
        ROUND(AVG(lifespan_days)::numeric, 2) AS avg_lifespan_days,
        -- Calculate average CLV per cohort (3-year projection)
        ROUND(AVG(CASE 
            WHEN lifespan_days > 0 
                THEN (total_profit / (lifespan_days / 365.0)) * 3
                ELSE total_profit * 3 
        END)::numeric, 2) AS avg_projected_clv,
        -- Customer retention rate (percentage still active in the last month)
        ROUND(100.0 * COUNT(CASE 
            WHEN last_purchase >= (SELECT DATE_TRUNC('month', MAX(order_date) - INTERVAL '1 month') 
                                  FROM superstore_orders)
            THEN 1 ELSE NULL 
        END) / NULLIF(COUNT(*), 0)::numeric, 2) AS retention_rate
    FROM customer_cohort_metrics
    GROUP BY cohort_month
)

SELECT
    cohort_month,
    customer_count,
    avg_orders,
    avg_sales,
    avg_profit,
    avg_lifespan_days,
    avg_projected_clv,
    retention_rate,
    -- Calculate CLV trend (comparing to overall average)
    ROUND(100.0 * avg_projected_clv / NULLIF((SELECT AVG(avg_projected_clv) FROM cohort_clv), 0) - 100, 2) AS clv_vs_overall_avg
FROM cohort_clv
ORDER BY cohort_month;