-- ================================================================================================
--                          SUPPLY CHAIN LATE DELIVERY ANALYSIS
--                                   SQL Project (MySQL)
-- ================================================================================================

-- --------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                       IMPORTANT
--           First Class Shipping mode shows 100% late_delivery. Every order should be shipped in 1 day but they have been shipped in 2 days.
--           This is not what happens practically but analysis of this dataset is done accordingly.
-- --------------------------------------------------------------------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                   KEY QUESTIONS ANSWERED
--          1. What percentage of orders are delivered late overall, and which order statuses should be excluded from this analysis?
--          2. Does shipping mode affect the likelihood of late delivery?
--          3. Are shipping_mode and days_for_shipment_scheduled actually two different variables, or the same information encoded twice?
--          4. Once shipping mode is accounted for, do region, category, customer state, market, segment, day of week, or month still
--             meaningfully affect late delivery — or is shipping mode the dominant driver?
--          5. Which financial columns (sales, order_item_total, order_profit_per_order, etc.) are independently meaningful,
--             and which are just derived/redundant calculations?
--          6. How much transaction value and profit is tied up in Canceled/Fraudulent orders that were never actually delivered?
--          7. Does profit margin vary meaningfully across shipping modes — and does that create a real trade-off between
--             profitability and on-time delivery?
-- --------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM flipkart.supply_chain;


-- ================================================================================================
--                                   OVERALL LATE DELIVERY RATE
-- ================================================================================================
SELECT 
    COUNT(*) AS 'total_orders_delivered',
    ROUND(SUM(late_delivery_risk) * 100 / (SELECT COUNT(*) FROM flipkart.supply_chain
                                            WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')), 2)
                                            AS 'late_delivery_pct',
    ROUND(SUM(late_delivery_risk) * 100 / (SELECT COUNT(*) FROM flipkart.supply_chain
                                            WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')), 2)
                                            AS 'on_time_delivery_pct'
FROM 
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD');


-- ================================================================================================
--                                   UNIVARIATE ANALYSIS
-- ================================================================================================

-- days_for_shipment_scheduled
SELECT 
    days_for_shipment_scheduled,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM 
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    days_for_shipment_scheduled
ORDER BY
    late_delivery_pct DESC;

-- days_for_shipping_real
SELECT 
    days_for_shipping_real,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM 
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    days_for_shipping_real
ORDER BY
    late_delivery_pct DESC;

-- shipping_mode
SELECT
    shipping_mode,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM 
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    shipping_mode
ORDER BY
    late_delivery_pct DESC;

-- order_status
SELECT 
    order_status,
    COUNT(*) AS 'orders_delivered',
    ROUND(SUM(CASE WHEN late_delivery_risk = '1' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS 'late_delivery_rate',
    ROUND(SUM(CASE WHEN late_delivery_risk = '0' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS 'ontime_delivery_rate'
FROM 
    flipkart.supply_chain
GROUP BY
    order_status
ORDER BY
    late_delivery_rate DESC;

-- payment type
SELECT 
    type,
    COUNT(*) AS 'orders_delivered',
    ROUND(SUM(CASE WHEN late_delivery_risk = '1' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS 'late_delivery_rate',
    ROUND(SUM(CASE WHEN late_delivery_risk = '0' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS 'ontime_delivery_rate'
FROM 
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    type
ORDER BY
    late_delivery_rate DESC;

-- customer_segment
SELECT 
    customer_segment,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM 
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    customer_segment
ORDER BY
    late_delivery_pct DESC;

-- customer_city has too many unique values so this won't be useful for analysing the cause of late_delivery
SELECT COUNT(DISTINCT(customer_city)) FROM flipkart.supply_chain;

-- customer_state
SELECT 
    customer_state,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM 
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    customer_state
ORDER BY
    late_delivery_pct DESC;

-- customer_country
SELECT 
    customer_country,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM
    flipkart.supply_chain
WHERE
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY 
    customer_country
ORDER BY 
    late_delivery_pct DESC;

-- PRODUCT_NAME is a subset of CATEGORY_NAME, which is further a subset of DEPARTMENT_NAME
-- product_name --> 118 unique values, category_name --> 50 unique values, department_name --> 11 unique values
-- Analysing category_name (best balance of granularity vs. generalizability)
SELECT
    category_name,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    category_name
ORDER BY
    late_delivery_pct DESC;

-- order_item_quantity
SELECT
    order_item_quantity,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    order_item_quantity
ORDER BY
    late_delivery_pct DESC;

-- product_price (binned)
SELECT
    CASE
        WHEN product_price < 50 THEN 'Low (<$50)'
        WHEN product_price BETWEEN 50 AND 199.99 THEN 'Medium ($50-$199.99)'
        WHEN product_price BETWEEN 200 AND 399.99 THEN 'High ($200-$399.99)'
        ELSE 'Premium ($400+)'
    END AS product_price_bin,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM
    flipkart.supply_chain
WHERE 
    order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY
    product_price_bin
ORDER BY
    late_delivery_pct DESC;

-- order_item_discount_rate (binned)
SELECT
    CASE
        WHEN order_item_discount_rate = 0 THEN 'No Discount (0%)'
        WHEN order_item_discount_rate BETWEEN 0.01 AND 0.05 THEN 'Low (1-5%)'
        WHEN order_item_discount_rate BETWEEN 0.06 AND 0.15 THEN 'Medium (6-15%)'
        WHEN order_item_discount_rate BETWEEN 0.16 AND 0.25 THEN 'High (16-25%)'
    END AS discount_rate_bin,
    COUNT(*) AS 'total_orders',
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS 'late_delivery_pct'
FROM supply_chain
GROUP BY discount_rate_bin
ORDER BY MIN(order_item_discount_rate);

-- order_item_profit_ratio (binned)
SELECT
    CASE
        WHEN order_item_profit_ratio < 0 THEN 'Loss (<0)'
        WHEN order_item_profit_ratio BETWEEN 0 AND 0.15 THEN 'Low Profit (0-0.15)'
        WHEN order_item_profit_ratio BETWEEN 0.16 AND 0.30 THEN 'Medium Profit (0.16-0.30)'
        WHEN order_item_profit_ratio BETWEEN 0.31 AND 0.50 THEN 'High Profit (0.31-0.50)'
    END AS profit_ratio_bin,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM supply_chain
GROUP BY profit_ratio_bin
ORDER BY MIN(order_item_profit_ratio);

-- order_region
SELECT
    order_region,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM supply_chain
GROUP BY order_region
ORDER BY late_delivery_pct DESC;

-- market
SELECT
    market,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM supply_chain
GROUP BY market
ORDER BY late_delivery_pct DESC;

-- order_datetime --> weekday vs weekend
SELECT
    CASE
        WHEN DAYOFWEEK(order_datetime) IN (1, 7) THEN 'Weekend' -- 1 = Sunday, 7 = Saturday
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM supply_chain
GROUP BY day_type;

-- order_datetime --> day of week
SELECT
    DAYNAME(order_datetime) AS order_day,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM
    supply_chain
GROUP BY 
    order_day, DAYOFWEEK(order_datetime)
ORDER BY 
    DAYOFWEEK(order_datetime);

-- order_datetime --> month
SELECT
    MONTHNAME(order_datetime) AS order_month,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM supply_chain
GROUP BY order_month, MONTH(order_datetime)
ORDER BY MONTH(order_datetime);

-- order_datetime --> year-month trend
SELECT
    DATE_FORMAT(order_datetime, '%Y-%m') AS 'year_months',
    COUNT(*) AS total_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM supply_chain
GROUP BY year_months
ORDER BY year_months;


-- ================================================================================================
--                                   BIVARIATE ANALYSIS
--                    (shipping_mode crossed against other variables to test for
--                     independent explanatory value vs. riding on shipping_mode)
-- ================================================================================================

-- Shipping Mode x Order Region
SELECT
    shipping_mode,
    order_region,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS 'late_orders',
    ROUND(SUM(late_delivery_risk) * 100 / COUNT(*), 2) AS 'late_delivery_pct'
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode, order_region
HAVING late_orders > 500
ORDER BY late_delivery_pct DESC;

-- Shipping Mode x Category Name
SELECT
    shipping_mode,
    category_name,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS 'late_orders',
    ROUND(SUM(late_delivery_risk) * 100 / COUNT(*), 2) AS 'late_delivery_pct'
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode, category_name
HAVING late_orders > 100
ORDER BY late_delivery_pct DESC;

-- Shipping Mode x Customer State
SELECT
    shipping_mode,
    customer_state,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode, customer_state
HAVING late_orders > 100
ORDER BY shipping_mode, late_delivery_pct DESC;

-- Shipping Mode x Day Type
SELECT 
    shipping_mode,
    CASE WHEN DAYOFWEEK(order_datetime) IN (1,7) THEN 'Weekend' ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS 'orders_delivered',
    SUM(late_delivery_risk) AS 'late_orders',
    ROUND(SUM(late_delivery_risk) * 100 / COUNT(*), 2) AS 'late_delivery_pct'
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode, day_type
ORDER BY shipping_mode, late_delivery_pct DESC;

-- Shipping Mode x Market
SELECT
    shipping_mode,
    market,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode, market
ORDER BY shipping_mode, late_delivery_pct DESC;

-- Shipping Mode x Customer Segment
SELECT
    shipping_mode,
    customer_segment,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode, customer_segment
ORDER BY shipping_mode, late_delivery_pct DESC;

-- Shipping Mode x Month
SELECT
    shipping_mode,
    MONTHNAME(order_datetime) AS order_month,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_pct
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode, order_month, MONTH(order_datetime)
ORDER BY shipping_mode, MONTH(order_datetime);


-- ================================================================================================
--                                   FRAUD DISTRIBUTION CHECK
--        (confirms Suspected Fraud orders are not concentrated in a small number of cities)
-- ================================================================================================
SELECT 
    COUNT(DISTINCT(order_city)) AS 'distinct_customer_city'
FROM flipkart.supply_chain 
WHERE order_status = 'SUSPECTED_FRAUD';

SELECT  
    COUNT(DISTINCT(order_city)) AS 'distinct_order_cities'
FROM flipkart.supply_chain 
WHERE order_status = 'SUSPECTED_FRAUD';


-- ================================================================================================
--                    ROOT CAUSE CHECK: WHY IS FIRST CLASS 100% LATE?
--        Confirms real shipping time is fixed (zero variance) for First Class specifically,
--        while other shipping modes show genuine, natural variation.
-- ================================================================================================
SELECT 
    shipping_mode, 
    AVG(days_for_shipping_real) AS avg_real,
    STDDEV(days_for_shipping_real) AS stddev_real,
    MIN(days_for_shipping_real) AS min_real,
    MAX(days_for_shipping_real) AS max_real
FROM supply_chain
GROUP BY shipping_mode;


-- ================================================================================================
--                          TOTAL REVENUE & PROFIT ANALYSIS BY SHIPPING MODE
-- ================================================================================================
SELECT
    shipping_mode,
    ROUND(SUM(order_item_total), 2) AS 'total_sales_value',
    ROUND(SUM(order_profit_per_order), 2) AS 'total_profit_value',
    ROUND(SUM(order_profit_per_order) * 100 / SUM(order_item_total), 2) AS 'profit_pct'
FROM flipkart.supply_chain
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY shipping_mode;

-- NOTE: If we choose on-time delivery by switching from First Class to other shipping classes,
-- profit margin will decrease slightly according to this data. However, we should still do it —
-- profit will eventually decrease anyway if customers are dissatisfied with late delivery.
-- In the long run, not switching away from an unfulfillable First Class promise risks losing
-- customers and degrading reviews, which is a larger cost than the ~1 point of margin at stake.


-- ================================================================================================
--            REVENUE/PROFIT EXPOSURE FROM CANCELED / SUSPECTED FRAUD ORDERS
--     (never actually delivered — shown separately, not blended into "actual" revenue figures)
-- ================================================================================================
SELECT
    order_status,
    COUNT(*) AS num_orders,
    ROUND(SUM(order_item_total), 2) AS total_transaction_value,
    ROUND(SUM(order_profit_per_order), 2) AS total_profit_value
FROM flipkart.supply_chain
WHERE order_status IN ('CANCELED','SUSPECTED_FRAUD')
GROUP BY order_status;
