/*
===============================================================================
View Name: gold.customers_report
===============================================================================

Description:
------------
This view provides a complete customer analytics and segmentation model
built from sales and customer dimension tables.

The view calculates:
    - Customer purchase behavior
    - Sales performance metrics
    - Customer Lifetime Value (CLV)
    - Average Order Value (AOV)
    - Recency and lifespan metrics
    - Age grouping
    - Customer segmentation (VIP / Regular / New)

Source Tables:
--------------
    - gold.sales
    - gold.dim_customers

Business Purpose:
-----------------
This view is designed for:
    - Customer analytics dashboards
    - Marketing segmentation
    - Retention analysis
    - Revenue analysis
    - Customer behavior reporting

===============================================================================
*/

CREATE OR ALTER VIEW gold.customers_report AS

/*=============================================================================
    STEP 1: Base Query
    ---------------------------------------------------------------------------
    Join sales and customer tables and prepare raw customer transaction data
=============================================================================*/
WITH base_query AS (

    SELECT 
        
        /*---------------------------------------------------------------------
            Order Information
        ---------------------------------------------------------------------*/
        s.sls_ord_num AS order_number,
        s.product_key,
        s.sls_order_dt AS order_date,

        /*---------------------------------------------------------------------
            Sales Metrics
        ---------------------------------------------------------------------*/
        s.sls_quantity AS quantity,
        s.sls_sales AS sales,

        /*---------------------------------------------------------------------
            Customer Information
        ---------------------------------------------------------------------*/
        c.customer_key,
        c.customer_number,
        c.full_name,
        c.country,
        c.maritial_status,
        c.gender,

        /*---------------------------------------------------------------------
            Customer Age
        ---------------------------------------------------------------------*/
        DATEDIFF(YEAR, c.birth_date, '2000') AS age

    FROM gold.sales s

    LEFT JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key

    WHERE s.sls_order_dt IS NOT NULL
    AND YEAR(s.sls_order_dt) BETWEEN 2000 AND YEAR(GETDATE())
),

/*=============================================================================
    STEP 2: Customer Aggregations
    ---------------------------------------------------------------------------
    Calculate customer-level KPIs and aggregated metrics
=============================================================================*/
customer_aggregations AS (

    SELECT

        /*---------------------------------------------------------------------
            Customer Details
        ---------------------------------------------------------------------*/
        customer_key,
        customer_number,
        full_name,
        country,
        maritial_status,
        gender,
        age,

        /*---------------------------------------------------------------------
            Purchase Metrics
        ---------------------------------------------------------------------*/
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,

        /*---------------------------------------------------------------------
            Customer Activity Metrics
        ---------------------------------------------------------------------*/
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date,

        /*---------------------------------------------------------------------
            Customer Lifespan
            Using DAY for more accurate calculations
        ---------------------------------------------------------------------*/
        DATEDIFF(
            DAY,
            MIN(order_date),
            MAX(order_date)
        ) AS life_span_days,

        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS life_span_months,

        /*---------------------------------------------------------------------
            Average Order Value (AOV)
        ---------------------------------------------------------------------*/
        CASE 
            WHEN COUNT(DISTINCT order_number) > 0
                THEN SUM(sales) / COUNT(DISTINCT order_number)
            ELSE 0
        END AS avg_order_value

    FROM base_query

    GROUP BY 
        customer_key,
        customer_number,
        full_name,
        country,
        maritial_status,
        gender,
        age
),

/*=============================================================================
    STEP 3: Final Customer Dataset
=============================================================================*/
final_customer_metrics AS (

    SELECT

        customer_key,
        customer_number,
        full_name,
        country,
        maritial_status,
        gender,
        age,

        total_orders,
        total_sales,
        total_quantity,
        total_products,

        first_order_date,
        last_order_date,

        life_span_days,
        life_span_months,

        avg_order_value,

        /*---------------------------------------------------------------------
            Recency
            Number of months since last purchase
        ---------------------------------------------------------------------*/
        DATEDIFF(
            MONTH,
            last_order_date,
            GETDATE()
        ) AS recency_months,

        /*---------------------------------------------------------------------
            Customer Lifetime Value (CLV)
            Formula:
                CLV = Average Order Value × Customer Lifespan
        ---------------------------------------------------------------------*/
        CASE 
            WHEN life_span_months > 0
                THEN avg_order_value * life_span_months
            ELSE avg_order_value
        END AS customer_lifetime_value,

        /*---------------------------------------------------------------------
            Average Monthly Spend
        ---------------------------------------------------------------------*/
        CASE 
            WHEN life_span_months > 0
                THEN total_sales / life_span_months
            ELSE total_sales
        END AS avg_monthly_spend

    FROM customer_aggregations
)

/*=============================================================================
    FINAL OUTPUT
=============================================================================*/
SELECT

    /*-------------------------------------------------------------------------
        Customer Details
    -------------------------------------------------------------------------*/
    customer_key,
    customer_number,
    full_name,
    country,
    gender,
    maritial_status,
    age,

    /*-------------------------------------------------------------------------
        Age Group Classification
    -------------------------------------------------------------------------*/
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS age_group,

    /*-------------------------------------------------------------------------
        Customer Segmentation
    -------------------------------------------------------------------------*/
    CASE 

        WHEN total_sales >= 4000
             AND total_orders >= 5
            THEN 'VIP'

        WHEN total_sales >= 2000
             AND total_orders >= 3
            THEN 'Regular'

        ELSE 'New'

    END AS customer_segment,

    /*-------------------------------------------------------------------------
        Customer Metrics
    -------------------------------------------------------------------------*/
    total_orders,
    total_sales,
    total_quantity,
    total_products,

    first_order_date,
    last_order_date,

    recency_months,

    life_span_days,
    life_span_months,

    avg_order_value,
    customer_lifetime_value,
    avg_monthly_spend

FROM final_customer_metrics;
