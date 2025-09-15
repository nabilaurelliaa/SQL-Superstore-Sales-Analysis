# Superstore Sales Performance Analysis (SQL Project)

`SQL` `Data Analysis` `MariaDB` `Business Intelligence`

### 📝 Project Overview

This project uses the popular "Superstore" dataset to practice and apply fundamental SQL skills in a realistic data analysis scenario. As someone in the early stages of learning SQL, my main objective was to handle a dataset from start to finish: setting up the database, exploring the data, performing transformations, and answering key business questions. This project focuses on demonstrating a solid understanding of essential SQL techniques for turning data into clear findings.

---
### 📊 Dataset

The project utilizes the **Superstore Dataset** sourced from Kaggle.
* **Source**: [Superstore - Sales Dataset on Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)

---
### 🛠️ Tools & Technologies

* **Database**: MariaDB (via XAMPP)
* **IDE**: DBeaver
* **Language**: SQL

---
### 🚀 Project Workflow

The project follows a systematic data analysis workflow:
1.  **Database Setup**: Creating the database and table schema.
2.  **Data Exploration & Cleaning**: Understanding the structure and verifying the initial data quality.
3.  **Validation & Transformation**: Performing anomaly validation and feature engineering.
4.  **Data Analysis & Findings**: Executing a series of SQL queries to answer key business questions.

---
### 1. Database Setup

The first step is to prepare the environment by creating the database and the required table structure.

```sql
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
```
* After creating the table, the data from the Superstore Dataset.csv file was imported using DBeaver. During the import process, each column from the CSV was carefully mapped to the corresponding data type in the newly created table to ensure data integrity.

---
### 2. Data Exploration & Cleaning 🕵️‍♂️

This stage aims to fundamentally understand the dataset and verify the initial data quality before further analysis. This involves checking the data's scale, verifying its integrity, and cleaning any identified issues.

#### A. Initial Descriptive Analysis

1.  **Get the total number of records**
    To understand the size of the dataset.
    ```sql
    -- Get the total number of records
    SELECT COUNT(*) AS total_rows FROM superstore_data;
    ```
    * **Result**: 
      | **COUNT(*)** |
      |:------------:|
      |     9992     |
    * **Interpretation**: The dataset contains 9992 transaction records, providing a substantial data volume for statistical analysis.

2.  **Check the time span of the data**
    To understand the period covered by the sales data.
    ```sql
    -- Check the time span of the data
    SELECT MIN(order_date) AS start_date, MAX(order_date) AS end_date FROM superstore_data;
    ```
    * **Result**:
      | **start_date** | **end_date** |
      |:--------------:|:------------:|
      |   2014-01-03   |  2017-12-30  |
    * **Interpretation**: The data covers sales over a 4-year period, from the beginning of 2014 to the end of 2017, which is sufficient for trend analysis.

3.  **Count the number of unique customers**
    To understand the size of the customer base.
    ```sql
    -- Count the number of unique customers
    SELECT COUNT(DISTINCT customer_id) AS total_unique_customers FROM superstore_data;
    ```
    * **Result**:
      | total_unique_customers |
      |:----------------------:|
      |           793          |
    * **Interpretation**: There are 793 unique customers in this dataset. Compared to the total number of transactions, this indicates that customers typically make multiple purchases over time.

#### B. Data Quality Verification

1.  **Check for NULL values**
    To ensure there is no missing data in critical columns.
    ```sql
    -- Check for NULL values in key columns
    SELECT COUNT(*) AS rows_with_nulls
    FROM superstore_data
    WHERE order_id IS NULL OR order_date IS NULL OR customer_id IS NULL OR sales IS NULL;
    ```
    * **Result**:
      | **rows_with_nulls** |
      |:-------------------:|
      |          0          |
    * **Interpretation**: The query returned 0 rows, confirming that there are no NULL values in key columns. The data is structurally complete.

2.  **Check for duplicate transaction rows**
    To verify data integrity, ensuring that the same product within the same order is not recorded more than once.
    ```sql
    -- Check for duplicate rows based on key transaction identifiers
    SELECT order_id, product_id, COUNT(*)
    FROM superstore_data
    GROUP BY 1, 2
    HAVING COUNT(*) > 1;
    ```
    * **Result**:
      |  **order_id**  |  **product_id** | **COUNT(*)** |
      |:--------------:|:---------------:|:------------:|
      | CA-2015-103135 | OFF-BI-10000069 |       2      |
      | CA-2016-129714 | OFF-PA-10001970 |       2      |
      | CA-2016-137043 | FUR-FU-10003664 |       2      |
      | CA-2016-140571 | OFF-PA-10001954 |       2      |
      | CA-2017-118017 | TEC-AC-10002006 |       2      |
      | CA-2017-152912 | OFF-ST-10003208 |       2      |
      | US-2016-123750 | TEC-AC-10004659 |       2      |
    * **Finding**: The query identified several duplicate transaction rows. This data quality issue could skew aggregate analyses (e.g., sales and profit would be double-counted) and must be resolved.

#### C. Data Cleaning

Based on the finding above, the duplicate rows are removed to ensure the accuracy of the analysis.

1.  **Remove Duplicates**
    The strategy is to keep the instance with the minimum `id` for each duplicate group and delete the rest.
    ```sql
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
    ```
    * **Action**: Executed the `DELETE` statement, successfully removing 7 duplicate rows.

2.  **Verification**
    Run the duplicate check again to confirm that the data is now clean.
    ```sql
    -- Verify that all duplicates are gone
    SELECT order_id, product_id, COUNT(*)
    FROM superstore_data
    GROUP BY 1, 2
    HAVING COUNT(*) > 1;
    ```
    * **Result**: *(No rows returned)*
    * **Interpretation**: The verification query returned no results, confirming that all duplicate rows have been successfully removed. The dataset is now clean and ready for transformation and analysis.
---
### 3. Data Validation & Transformation 🔄

This stage focuses on creating new features to enhance our analytical capabilities through feature engineering.

#### Feature Engineering

1.  **Add shipping duration calculation**
    Create a new metric to analyze delivery performance across different shipping modes.
    ```sql
    -- Add a new column for shipping duration
    ALTER TABLE superstore_data ADD COLUMN shipping_duration INT;

    -- Calculate the shipping duration in days
    UPDATE superstore_data SET shipping_duration = DATEDIFF(ship_date, order_date);
    ```

2.  **Create customer value segmentation**
    Categorize transactions based on sales value to identify different customer tiers.
    ```sql
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
    ```

---
### 4. Data Analysis & Findings 📈

This section presents the core business analysis through targeted SQL queries designed to answer key strategic questions.

#### Q1. Which product sub-categories are the most and least profitable?

```sql
-- Calculate Profit Ratio for each sub-category
SELECT
    sub_category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit, 
    (SUM(profit) / SUM(sales)) AS profit_ratio
FROM superstore_data
GROUP BY 1 
ORDER BY 4 DESC;
```
* **Result**:
  | **sub_category** | **total_sales** | **total_profit** | **profit_ratio** |
  |:----------------:|:---------------:|:----------------:|:----------------:|
  |      Labels      |     12486.30    |      5546.18     |     0.444181     |
  |       Paper      |     78384.44    |     34009.24     |     0.433877     |
  |     Envelopes    |     16476.38    |      6964.10     |     0.422672     |
  |      Copiers     |    149528.01    |     55617.90     |     0.371956     |
  |     Fasteners    |     3024.25     |      949.53      |     0.313972     |
  |    Accessories   |    166986.01    |     41867.97     |     0.250727     |
  |        Art       |     27118.80    |      6527.96     |     0.240717     |
  |    Appliances    |    107532.14    |     18138.07     |     0.168676     |
  |      Binders     |    203322.71    |     30180.21     |     0.148435     |
  |    Furnishings   |     91418.74    |     12976.20     |     0.141942     |
  |      Phones      |    330007.10    |     44516.25     |     0.134895     |
  |      Storage     |    223299.21    |     21121.18     |     0.094587     |
  |      Chairs      |    328167.76    |     26602.21     |     0.081063     |
  |     Machines     |    189238.68    |      3384.73     |     0.017886     |
  |     Supplies     |     46673.52    |     -1188.99     |     -0.025475    |
  |     Bookcases    |    114618.09    |     -3514.47     |     -0.030662    |
  |      Tables      |    206965.68    |     -17725.59    |     -0.085645    |
  
**Key Findings:**
* **Most Profitable**: Labels (44.42% profit ratio), followed by Paper (43.39%) and Envelopes (42.27%)
* **Least Profitable**: Tables (-8.56% profit ratio), Bookcases (-3.07%) and Supplies (-2.55%)
* **Insight**: Office supplies like Labels and Paper have the highest profit margins, while furniture items (Tables, Bookcases) are consistently unprofitable

#### Q2. How much impact do discounts have on profitability?

```sql
-- Analyze the correlation between discount levels and profitability
SELECT
    discount, 
    AVG(profit) AS avg_profit,
    COUNT(*) AS transaction_count
FROM superstore_data
GROUP BY 1 
ORDER BY 1;
```
* **Result**:
  | **discount** | **avg_profit** |
  |:------------:|:--------------:|
  |     0.00     |    66.907245   |
  |     0.10     |    96.055426   |
  |     0.15     |    27.288077   |
  |     0.20     |    24.697497   |
  |     0.30     |   -45.828673   |
  |     0.32     |   -88.561481   |
  |     0.40     |   -111.927573  |
  |     0.45     |   -226.647273  |
  |     0.50     |   -310.704697  |
  |     0.60     |   -43.077101   |
  |     0.70     |   -95.874306   |
  |     0.80     |   -101.797100  |
**Key Findings:**
* **No Discount (0.0)**: Average profit of $66.91 per transaction
* **10% Discount**: Shows highest average profit at $96.06
* **20% and above**: Profit starts declining significantly
* **50% Discount**: Results in average loss of $310.70
* **Insight**: Small discounts can boost profitability, but heavy discounts (30%+) cause losses

#### Q3. What is the profit contribution from each customer value segment?

```sql
-- Analyze profit contribution by customer tier
SELECT
    customer_tier,
    COUNT(DISTINCT order_id) AS total_transactions,
    SUM(profit) AS total_profit,
    AVG(profit) AS avg_profit_per_transaction
FROM superstore_data
GROUP BY 1
ORDER BY 3 DESC;
```
* **Result**:
  |  **customer_tier**  | **total_transactions** | **total_profit** |
  |:-------------------:|:----------------------:|:----------------:|
  | High Value Customer |          1020          |     186894.05    |
  |  Mid Value Customer |          2059          |     65819.16     |
  |  Low Value Customer |          3864          |     33259.47     |
**Key Findings:**
* **High Value Customers**: 1,020 transactions generating $186,894 profit (65% of total profit)
* **Mid Value Customers**: 2,059 transactions generating $65,819 profit (23% of total profit)
* **Low Value Customers**: 3,864 transactions generating only $33,259 profit (12% of total profit)
* **Insight**: High-value customers are much more profitable despite being fewer in number

#### Q4. Analyze the average shipping duration per shipping mode

```sql
-- Analyze shipping performance by mode
SELECT
    ship_mode,
    AVG(shipping_duration) AS avg_shipping_days,
    MIN(shipping_duration) AS fastest_shipping,
    MAX(shipping_duration) AS slowest_shipping,
    COUNT(*) AS total_shipments
FROM superstore_data
GROUP BY 1
ORDER BY 2 ASC;
```
* **Result**:
  |  **ship_mode** | **avg_shipping_days** | **fastest_shipping** | **slowest_shipping** |
  |:--------------:|:---------------------:|:--------------------:|:--------------------:|
  |    Same Day    |         0.0442        |           0          |           1          |
  |   First Class  |         2.1828        |           1          |           4          |
  |  Second Class  |         3.2391        |           1          |           5          |
  | Standard Class |         5.0069        |           3          |           7          |
**Key Findings:**
* **Same Day**: 0.04 days average
* **First Class**: 2.18 days average
* **Second Class**: 3.24 days average
* **Standard Class**: 5.1 days average
* **Insight**: Shipping times are consistent with service levels, showing reliable delivery performance

#### Q5. Identify the highest and lowest monthly sales for each year to analyze seasonal trends

```sql
-- Calculate Highest and lowest monthly sales per year
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
```
* **Result**:
  | **sales_year** | **highest_sales** | **lowest_sales** |
  |:--------------:|:-----------------:|:----------------:|
  |      2014      |      81777.34     |      4519.92     |
  |      2015      |      75972.51     |     11951.40     |
  |      2016      |      96712.69     |     18542.52     |
  |      2017      |     117903.43     |     20301.12     |
**Key Findings:**
* **Peak Sales Months**: Highest monthly sales increased each year, with 2017 peaking at 117,903.43.
* **Lowest Sales Months**: Lowest monthly sales occurred in 2014 (4,519.92)
* **Yearly Growth Trend**: Overall peak sales show consistent upward growth from 2014 to 2017
* **Insight**: Consistent growth in peak sales suggests future sales may continue rising, while the gap between lowest and highest months indicates variable monthly demand for planning purposes.
---
