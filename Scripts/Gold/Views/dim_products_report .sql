/*
================================================================================
Description:
    This script initializes and populates the 'gold.fact_dim_products_report' 
    table. It serves as a static product analytics and reporting mart within 
    the Gold layer.

    The script uses a "Drop and Recreate" pattern followed by an INSERT INTO 
    statement. It consolidates foundational product data with calculated business 
    metrics—such as financial cost tiers and performance segmentation flags—by 
    migrating data from a dynamic reporting view (gold.product_report) into a 
    physical table to optimize performance for BI dashboards and reporting tools.

Components:
    - gold.fact_dim_products_report : Target analytical product storage table.
    - gold.product_report           : Source gold view calculating product data 
                                      and business performance metrics.
================================================================================
*/

-- =============================================================================
-- 1. Table Initialization (Drop & Recreate)
-- =============================================================================

-- Drop the table if it already exists to guarantee a clean state before reload
IF OBJECT_ID('gold.fact_dim_products_report', 'U') IS NOT NULL
    DROP TABLE gold.fact_dim_products_report;
GO

-- Create the physical table structure for product performance reporting
CREATE TABLE gold.fact_dim_products_report (
    product_key         INT PRIMARY KEY,    -- Unique surrogate key identifying the product
    product_name        NVARCHAR(150),      -- Descriptive name of the product
    category            NVARCHAR(100),      -- Major product category classification
    sub_category        NVARCHAR(100),      -- Product sub-category classification
    cost                DECIMAL(18, 2),     -- Strongly typed product cost metric
    product_line        NVARCHAR(50),       -- Product line division mapping
    performance_segment NVARCHAR(50)        -- Performance metric categorization (e.g., High, Medium, Low)
);
GO

-- =============================================================================
-- 2. Data Population Pipeline
-- =============================================================================

-- Populate the newly created reporting table from the analytical source view
INSERT INTO gold.fact_dim_products_report (
    product_key,
    product_name,
    category,
    sub_category,
    cost,
    product_line,
    performance_segment
)
SELECT 
    product_key,
    product_name,
    category,
    sub_category,
    cost,
    product_line,
    performance_segment
FROM gold.product_report;
GO