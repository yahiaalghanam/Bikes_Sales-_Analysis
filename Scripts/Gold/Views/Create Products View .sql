/*
================================================================================
Description:
    This script creates the 'gold.dim_products' dimension view. It curates, 
    cleanses, and normalizes product master data from the 'silver' layer into 
    a dimensional format suitable for BI and reporting.

    The view implements several dimensional modeling best practices:
    - Generates a unique surrogate key (product_key) using ROW_NUMBER().
    - Flattens product hierarchies by bringing in categories and sub-categories 
      via a LEFT JOIN.
    - Filters out historical records (WHERE prd_end_dt IS NULL) to ensure that 
      only the currently active product definitions are exposed to downstream users.

Source Tables (Silver Layer):
    - silver.crm_prd_info (prd)     : Base product records originating from CRM.
    - silver.erp_px_cat_g1v2 (cat)  : Product category mapping from the ERP system.
================================================================================
*/

CREATE VIEW gold.dim_products AS
SELECT 
    -- Generates a unique, sequential surrogate key for the product dimension
    ROW_NUMBER() OVER (ORDER BY prd.prd_id) AS product_key,
    
    -- Business/Operational SKU key used across source systems
    prd.prd_key AS product_number,
    
    -- Primary identifier from the source CRM system
    prd.prd_id AS product_id,
    
    -- Descriptive name of the product
    prd.prd_nm AS product_name,
    
    -- Foreign key to track categorization lineage
    prd.cat_id AS category_id,
    
    -- Flattened category hierarchy fields from the ERP metadata
    cat.cat AS category,
    cat.subcat AS sub_category,
    cat.maintenance,
    
    -- Financial and product classification attributes
    prd.prd_cost AS cost,
    prd.prd_line AS product_line,
    
    -- The effective start date for this active product configuration
    prd.prd_start_dt AS start_date

FROM silver.crm_prd_info prd

-- Enrich products with their descriptive category hierarchies from the ERP system
LEFT JOIN silver.erp_px_cat_g1v2 cat 
    ON cat.id = prd.cat_id

-- Filter out historical/expired records to capture only the current active version
WHERE prd.prd_end_dt IS NULL; 
GO