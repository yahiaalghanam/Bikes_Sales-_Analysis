/*
===============================================================================
View Name: gold.product_report
===============================================================================

Description:
------------
This view provides a comprehensive product performance and sales analysis
dataset built from sales transactions and product dimension tables.

The view calculates:
    - Product sales performance
    - Revenue metrics
    - Product lifecycle metrics
    - Customer reach metrics
    - Product recency analysis
    - Average selling price
    - Product performance segmentation

Source Tables:
--------------
    - gold.sales
    - gold.dim_products

Business Purpose:
-----------------
This view is designed for:
    - Product performance dashboards
    - Sales analysis
    - Inventory and category analysis
    - Revenue tracking
    - Product lifecycle monitoring
    - Executive reporting

===============================================================================
*/

CREATE OR ALTER VIEW gold.product_report AS

/*=============================================================================
    STEP 1: Sales Data Preparation
    ---------------------------------------------------------------------------
    Join sales and product tables and prepare transactional product data
=============================================================================*/
WITH sales_data AS (

    SELECT

        -- Order Information
        s.sls_ord_num AS order_number,
        s.sls_order_dt AS order_date,

        -- Customer Information
        s.customer_key,

        -- Sales Metrics
        s.sls_sales AS sales_amount,
        s.sls_quantity AS quantity,

        -- Product Information
        p.product_key,
        p.product_name,
        p.category,
        p.sub_category,
        p.cost,
        p.product_line

    FROM gold.sales s

    INNER JOIN gold.dim_products p
        ON s.product_key = p.product_key

    -- Exclude records with missing order dates
    WHERE s.sls_order_dt IS NOT NULL
    AND YEAR(s.sls_order_dt) BETWEEN 2000 AND YEAR(GETDATE())
),

/*=============================================================================
    STEP 2: Product Aggregations
    ---------------------------------------------------------------------------
    Calculate product-level KPIs and aggregated metrics
=============================================================================*/
aggregate_products AS (

    SELECT 

        -- Product Details
        product_key,
        product_name,
        category,
        sub_category,
        cost,
        product_line,

        /*-------------------------------------------------------------------------
            Product Lifecycle Metrics
        -------------------------------------------------------------------------*/

        -- Product sales lifespan in months
        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS order_life_span,

        -- Most recent order date
        MAX(order_date) AS last_order_date,

        /*-------------------------------------------------------------------------
            Product Performance Metrics
        -------------------------------------------------------------------------*/

        -- Total distinct orders
        COUNT(DISTINCT order_number) AS total_orders,

        -- Total distinct customers
        COUNT(DISTINCT customer_key) AS total_customers,

        -- Total revenue generated
        SUM(sales_amount) AS total_sales,

        -- Total quantity sold
        SUM(quantity) AS total_quantity,

        -- Total unique products
        COUNT(DISTINCT product_key) AS total_products,

        /*-------------------------------------------------------------------------
            Average Selling Price
            Formula:
                Sales Amount / Quantity
        -------------------------------------------------------------------------*/
        ROUND(
            AVG(
                CAST(sales_amount AS FLOAT)
                / NULLIF(quantity, 0)
            ),
            1
        ) AS avg_selling_price

    FROM sales_data

    GROUP BY 
        product_key,
        product_name,
        category,
        sub_category,
        cost,
        product_line
)

/*=============================================================================
    FINAL OUTPUT
    ---------------------------------------------------------------------------
    Generate product performance and analytical metrics
=============================================================================*/
SELECT 

    -- Product Details
    product_key,
    product_name,
    category,
    sub_category,
    cost,
    product_line,

    /*-------------------------------------------------------------------------
        Product Lifecycle Metrics
    -------------------------------------------------------------------------*/
    order_life_span,
    last_order_date,

    -- Number of months since the last order
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,

    /*-------------------------------------------------------------------------
        Product Performance Segmentation
    -------------------------------------------------------------------------*/
    CASE 
        WHEN total_sales >= 50000 THEN 'High Performance'
        WHEN total_sales >= 20000 THEN 'Medium Performance'
        ELSE 'Low Performance'
    END AS performance_segment,

    /*-------------------------------------------------------------------------
        Product KPIs
    -------------------------------------------------------------------------*/
    total_orders,
    total_customers,
    total_sales,
    total_quantity,
    total_products,
    avg_selling_price,

    /*-------------------------------------------------------------------------
        Average Order Revenue
        Formula:
            Total Sales / Total Orders
    -------------------------------------------------------------------------*/
    CASE 
        WHEN total_orders > 0 
            THEN ROUND(total_sales / total_orders, 1)
        ELSE 0
    END AS avg_order_revenue,

    /*-------------------------------------------------------------------------
        Average Monthly Revenue
        Formula:
            Total Sales / Product Lifespan
    -------------------------------------------------------------------------*/
    CASE 
        WHEN order_life_span > 0 
            THEN ROUND(total_sales / order_life_span, 1)
        ELSE 0
    END AS avg_monthly_revenue

FROM aggregate_products;