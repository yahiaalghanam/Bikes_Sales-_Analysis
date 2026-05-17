/*
================================================================================
Description:
    This script contains two independent analytical and quality assurance queries
    designed to evaluate data merging logic and structural completeness within 
    the data warehouse pipeline.

    Query 1 (Gender Consolidation Profiling):
    Examines and validates the conditional logic used to unify customer gender 
    attributes across different source platforms (CRM vs. ERP). By grouping the 
    cross-system combinations, it tests the effectiveness of the fallback rules 
    intended for the 'gold.dim_customers' view.

    Query 2 (Star Schema Referential Integrity Audit):
    Performs a data quality scan across the completed Gold layer. It uses LEFT JOINs 
    extending from the central fact table out to the reporting dimensions. This 
    allows engineers to verify that all surrogate keys match properly and check for 
    any orphan records (rows in the fact table that lack corresponding dimensions).

Source Tables & Views:
    - silver.crm_cust_info (ci)  : Cleaned primary CRM customer registry.
    - silver.erp_cust_az12 (az)  : Supplementary ERP customer demographics.
    - gold.sales (s)             : Central transactional fact records.
    - gold.dim_customers (c)     : Curated customer reporting dimension.
    - gold.dim_products (p)      : Curated product reporting dimension.
================================================================================
*/

-- =============================================================================
-- SECTION 1: Cross-System Gender Mapping and Merging Test
-- =============================================================================

SELECT 
    ci.cst_gndr AS crm_gender,          -- Raw gender format present in the CRM platform
    az.gen      AS erp_gender,          -- Raw gender format present in the ERP platform
    
    -- Evaluates fallback logic: Prioritizes CRM data, falls back to ERP if CRM is 'N/A'
    CASE 
        WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
        ELSE COALESCE(az.gen, 'N/A')
    END AS new_gen

FROM silver.crm_cust_info ci

-- Map systems together using unique business keys to analyze overlap behaviors
LEFT JOIN silver.erp_cust_az12 az
    ON ci.cst_key = az.cid
LEFT JOIN silver.erp_loc_a101 loc
    ON ci.cst_key = loc.cid

-- Group by the source system elements to view all unique permutation combinations
GROUP BY 
    ci.cst_gndr, 
    az.gen;


-- =============================================================================
-- SECTION 2: Gold Layer Referential Integrity Audit
-- =============================================================================

SELECT 
    s.*,   -- Transactional metrics and surrogate keys from the fact table
    c.*,   -- Conjoined reporting attributes from the customer dimension
    p.*    -- Conjoined reporting attributes from the product dimension
FROM gold.sales s 

-- Audit Customer Linkages: Check for orphan sales records (where c.Customer_key returns NULL)
LEFT JOIN gold.dim_customers c
    ON s.Customer_key = c.Customer_key

-- Audit Product Linkages: Check for orphan sales records (where p.product_key returns NULL)
LEFT JOIN gold.dim_products p
    ON s.product_key = p.product_key;
GO