WITH customer_metrics AS (
    SELECT
        customer_name,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit,
        MIN(order_date) AS first_purchase,
        MAX(order_date) AS last_purchase,
        -- Calculate customer lifespan in days
        DATE_PART('day', MAX(order_date) - MIN(order_date)) AS lifespan_days
    FROM superstore_orders
    GROUP BY customer_name
),

customer_values AS (
    SELECT
        customer_name,
        total_orders,
        total_sales,
        total_profit,
        first_purchase,
        last_purchase,
        lifespan_days,
        -- Average order value
        CASE WHEN total_orders > 0 THEN total_sales / total_orders ELSE 0 END AS avg_order_value,
        -- Purchase frequency (orders per year)
        CASE WHEN lifespan_days > 0 
             THEN (total_orders / (lifespan_days / 365.0))
             ELSE total_orders END AS purchase_frequency_yearly,
        -- Customer value (profit per year)
        CASE WHEN lifespan_days > 0 
             THEN (total_profit / (lifespan_days / 365.0))
             ELSE total_profit END AS customer_value_yearly
    FROM customer_metrics
)

-- Calculate CLV (assuming 3-year customer lifespan if not enough data)
SELECT
    customer_name,
    total_orders,
    total_sales,
    total_profit,
    first_purchase,
    last_purchase,
    ROUND(avg_order_value::numeric, 2) AS avg_order_value,
    ROUND(purchase_frequency_yearly::numeric, 2) AS purchase_frequency_yearly,
    ROUND(customer_value_yearly::numeric, 2) AS customer_value_yearly,
    -- CLV calculation: yearly value * expected lifespan (3 years)
    ROUND((customer_value_yearly * 3)::numeric, 2) AS predicted_clv_3yr,
    -- Actual CLV based on observed lifespan
    ROUND(total_profit::numeric, 2) AS actual_clv_to_date
FROM customer_values
ORDER BY predicted_clv_3yr DESC;