/*
================================================================================
Description:
    This script initializes and populates the 'gold.fact_sales' table, which 
    serves as the central Fact table in a classic Star Schema architecture for 
    the business's core transactional process. 

    The script employs a "Drop and Recreate" design pattern to ensure a clean 
    reload of transaction data. It introduces an auto-incrementing identity column 
    as the primary key for the physical records and establishes standard data types 
    (such as DECIMAL) for numeric metrics. 

    The data population pipeline extracts historical transactional facts from the 
    'gold.sales' view, maps them to existing reporting dimensions, and applies 
    strict temporal filters to eliminate orphan or invalid chronological records.

Target Relationships:
    - order_date   --> Links to gold.dim_date (date_key)
    - customer_key --> Links to gold.fact_dim_customers_report (customer_key)
    - product_key  --> Links to gold.fact_dim_products_report (product_key)
================================================================================
*/

-- =============================================================================
-- 1. Table Initialization (Drop & Recreate)
-- =============================================================================

-- Drop the table if it already exists to guarantee a clean state before reload
IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL
    DROP TABLE gold.fact_sales;
GO

-- Create the physical Star Schema Central Fact Table
CREATE TABLE gold.fact_sales (
    sales_order_key INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incrementing surrogate identity key for individual line items
    order_number    NVARCHAR(50),                  -- Degenerate dimension (Operational Sales Order ID)
    order_date      DATE,                          -- Foreign Key linking to the Date Dimension (gold.dim_date)
    customer_key    INT,                           -- Foreign Key linking to Customer Dimension (gold.fact_dim_customers_report)
    product_key     INT,                           -- Foreign Key linking to Product Dimension (gold.fact_dim_products_report)
    quantity        INT,                           -- Additive numeric metric: Total unit quantity sold
    sales_amount    DECIMAL(18, 2)                 -- Additive financial metric: Total gross revenue
);
GO

-- =============================================================================
-- 2. Data Population Pipeline (ETL / Ingestion)
-- =============================================================================

-- Populate the central fact table with daily transactional records
INSERT INTO gold.fact_sales (
    order_number, 
    order_date, 
    customer_key, 
    product_key, 
    quantity, 
    sales_amount
)
SELECT 
    sls_ord_num,        -- Maps to order_number
    sls_order_dt,       -- Maps to order_date
    customer_key,       -- Surrogated key mapping derived from upstream gold view
    product_key,        -- Surrogated key mapping derived from upstream gold view
    sls_quantity,       -- Maps to quantity
    sls_sales           -- Maps to financial sales_amount
FROM gold.sales
WHERE 
    -- Quality Gate: Ensure the transaction has a valid timestamp
    sls_order_dt IS NOT NULL
    
    -- Business Rule: Keep records within a sensible boundaries (Year 2000 up to the Current Year)
    AND YEAR(sls_order_dt) BETWEEN 2000 AND YEAR(GETDATE());
GO