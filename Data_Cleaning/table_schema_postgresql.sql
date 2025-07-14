-- Create the table with appropriate data types
CREATE TABLE superstore_orders (
    order_id VARCHAR(50),
    order_date TIMESTAMP, 
    ship_date TIMESTAMP,
    ship_mode VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    state VARCHAR(100),
    country VARCHAR(50),
    market VARCHAR(50),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales NUMERIC(12,2),
    quantity INTEGER,
    discount NUMERIC(5,2),
    profit NUMERIC(12,4),
    shipping_cost NUMERIC(12,2),
    order_priority VARCHAR(20),
    year INTEGER,
    PRIMARY KEY (order_id, product_id)
);

-- Add comment
COMMENT ON TABLE superstore_orders IS 'Contains superstore sales data with order, customer, product and financial information';