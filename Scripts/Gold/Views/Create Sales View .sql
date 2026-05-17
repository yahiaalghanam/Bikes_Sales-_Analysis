/*
================================================================================
Description:
    This script creates the 'gold.sales' fact view, representing the core 
    transactional business process for the analytical Gold layer. It acts as 
    the central fact table in a Star Schema design.

    The view implements key dimensional modeling concepts:
    - Resolves raw business keys into system-generated surrogate keys 
      (product_key and Customer_key) by joining the raw sales details to the 
      pre-defined Gold dimensions.
    - Preserves transaction metrics (quantity, sales amount, and price) alongside 
      critical operational dates for time-series analysis.

Source Tables & Views:
    - silver.crm_sales_details (sd) : Raw transactional sales data from the CRM system.
    - gold.dim_products (pr)        : Dimension view used to fetch surrogate product keys.
    - gold.dim_customers (cu)       : Dimension view used to fetch surrogate customer keys.
================================================================================
*/

CREATE VIEW gold.sales AS
SELECT 
    -- Transactional Line Identifiers
    sd.sls_ord_num,       -- Sales Order Number (Degenerate Dimension / Business Key)
    
    -- Dimension Surrogate Keys (Resolved via joins)
    pr.product_key,       -- Surrogated key pointing to gold.dim_products
    cu.Customer_key,      -- Surrogated key pointing to gold.dim_customers
    
    -- Operational and Financial Dates
    sd.sls_order_dt,      -- Order Date Key (YYYYMMDD format)
    sd.sls_ship_dt,       -- Shipping Date Key (YYYYMMDD format)
    sd.sls_due_dt,        -- Payment Due Date Key (YYYYMMDD format)
    
    -- Quantitative Fact Metrics
    sd.sls_quantity,      -- Number of product units sold
    sd.sls_sales,         -- Total gross sales amount for the line item
    sd.sls_price          -- Unit price of the item sold

FROM silver.crm_sales_details sd

-- Look up and map the surrogate Product Key using the natural business key (SKU)
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

-- Look up and map the surrogate Customer Key using the natural Customer ID
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.Customer_id;
GO