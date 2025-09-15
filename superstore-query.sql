# 1. DATABASE SETUP

-- CREATE DATABASE
CREATE DATABASE sql_project01;

-- CREATE TABLE 
CREATE TABLE superstore_data
(
    id            INT AUTO_INCREMENT PRIMARY KEY,
    order_id      VARCHAR(20),
    order_date    DATE,
    ship_date     DATE,
    ship_mode     VARCHAR(50),
    customer_id   VARCHAR(20),
    customer_name VARCHAR(100),
    segment       VARCHAR(50),
    country       VARCHAR(50),
    city          VARCHAR(100),
    state         VARCHAR(50),
    postal_code   VARCHAR(20),
    region        VARCHAR(50),
    product_id    VARCHAR(20),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    product_name  VARCHAR(200),
    sales         DECIMAL(10, 2),
    quantity      INT,
    discount      DECIMAL(4, 2),
    profit        DECIMAL(10, 2)
);


# 2. DATA EXPLORATION & CLEANING 

-- Get the total number of records
SELECT COUNT(*) FROM superstore_data;

-- Check the time span of the data
SELECT MIN(order_date) AS start_date, MAX(order_date) AS end_date FROM superstore_data;

-- Count the number of unique customers
SELECT COUNT(DISTINCT customer_id) AS total_unique_customers FROM superstore_data;

-- Check for NULL values in key columns
SELECT COUNT(*) AS rows_with_nulls
FROM superstore_data
WHERE order_id IS NULL OR order_date IS NULL OR customer_id IS NULL OR sales IS NULL;

-- Check for duplicate rows based on key transaction identifiers
SELECT order_id, product_id, COUNT(*) 
FROM superstore_data GROUP BY 1,2 HAVING COUNT(*) > 1;

-- Investigate a specific duplicate case
SELECT * FROM superstore_data
WHERE order_id = 'CA-2015-103135' AND product_id = 'OFF-BI-10000069';

-- Safely delete duplicate rows, keeping the one with the minimum ID
DELETE t1 FROM superstore_data t1
INNER JOIN (
    SELECT
        order_id,
        product_id,
        MIN(id) AS min_id
    FROM
        superstore_data
    GROUP BY
        order_id,
        product_id
    HAVING
        COUNT(*) > 1
) t2
  ON t1.order_id = t2.order_id
 AND t1.product_id = t2.product_id
 AND t1.id > t2.min_id;

-- Verify that all duplicates are gone
SELECT order_id, product_id, COUNT(*)
FROM superstore_data
GROUP BY 1, 2
HAVING COUNT(*) > 1;


# 3. DATA VALIDATION & TRANSFORMATION

-- Add a new column for shipping duration
ALTER TABLE superstore_data ADD COLUMN shipping_duration INT;

-- Calculate the shipping duration in days
UPDATE superstore_data SET shipping_duration = DATEDIFF(ship_date, order_date);

-- Add a new column for customer tier based on sales value
ALTER TABLE superstore_data ADD COLUMN customer_tier VARCHAR(50);

-- Categorize each transaction into a tier based on the sales amount
UPDATE superstore_data
SET customer_tier =
	CASE
		WHEN sales > 500 THEN "High Value Customer"
		WHEN sales > 100 AND sales <= 500 THEN "Mid Value Customer"
		ELSE "Low Value Customer"
	END;

# 4. DATA ANALYSIS & FINDINGS

/* Q1. Which product sub-categories are the most and least profitable? */
-- Calculate Profit Ratio for each sub-category
SELECT
	sub_category,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profit, 
	(SUM(profit)/ SUM(sales)) AS profit_ratio
FROM superstore_data
GROUP BY 1 ORDER BY 4 DESC; 

/* Q2. How much impact do discounts have on profitability? */
-- Analyze the correlation between discount levels and profitability
SELECT
	discount, 
	AVG(profit) AS avg_profit
FROM superstore_data
GROUP BY 1 ORDER BY 1;

/* Q3. What is the profit contribution from each customer value segment? */
SELECT
	customer_tier,
	COUNT(DISTINCT order_id) AS total_transactions,
	SUM(profit) AS total_profit
FROM superstore_data
GROUP BY 1
ORDER BY 3 DESC; 

/* Q4. Analyze the average shipping duration per shipping mode */ 
SELECT
    ship_mode,
    AVG(shipping_duration) AS avg_shipping_days,
    MIN(shipping_duration) AS fastest_shipping,
    MAX(shipping_duration) AS slowest_shipping
FROM superstore_data
GROUP BY 1
ORDER BY 2 ASC;

/* Q5. Analyze monthly sales trends to identify seasonality */
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    SUM(sales) AS total_sales
FROM superstore_data
GROUP BY 1
ORDER BY 1;

WITH monthly_sales AS (
    SELECT
        YEAR(order_date) AS sales_year,
        MONTH(order_date) AS sales_month,
        SUM(sales) AS total_sales
    FROM superstore_data
    GROUP BY 1,2
)
SELECT
    sales_year,
    MAX(total_sales) AS highest_sales,
    MIN(total_sales) AS lowest_sales
FROM monthly_sales
GROUP BY sales_year
ORDER BY sales_year;
