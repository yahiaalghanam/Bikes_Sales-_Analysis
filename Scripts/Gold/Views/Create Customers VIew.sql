/*
================================================================================
Description:
    This script creates the 'Gold.dim_customers' dimension view. It consolidates 
    and refines customer data from the 'Silver' layer, merging core CRM customer 
    profiles with supplementary ERP demographics and geographic data.

    The view implements several data warehouse best practices:
    - Generates a surrogate key (Customer_key) using ROW_NUMBER().
    - Standardizes and cleanses names by trimming and concatenating fields.
    - Handles data enrichment via conditional fallback logic (COALESCE/CASE) 
      to patch missing gender values using cross-system data.

Source Tables (Silver Layer):
    - silver.crm_cust_info (ci)  : Primary customer registry from the CRM system.
    - silver.erp_cust_az12 (az)  : Supplementary ERP attributes (Birthdate, Gender).
    - silver.erp_loc_a101 (loc)  : Supplementary ERP localization data (Country).
================================================================================
*/

CREATE VIEW Gold.dim_customers AS
SELECT 
    -- Generates a unique, sequential surrogate key for the customer dimension
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS Customer_key,
    
    -- Primary identifier from the source CRM system
    ci.cst_id AS Customer_ID,
    
    -- Business/Operational key used for lookups and joins
    ci.cst_key AS Customer_Number,
    
    -- Cleanses, concatenates, and removes leading/trailing whitespaces from the name
    LTRIM(RTRIM(CONCAT(ci.cst_firstname, ' ', ci.cst_lastname))) AS Full_name,
    
    -- Marital status mapping
    ci.cst_marital_status AS Maritial_Status,
    
    -- Gender enrichment: uses CRM data unless it's 'N/A', falling back to ERP data
    CASE 
        WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
        ELSE COALESCE(az.gen, 'N/A')
    END AS Gender,
    
    -- Supplementary demographics and audit attributes
    az.bdate AS Birth_date,
    ci.cst_create_date AS Create_date,
    loc.cntry AS Country 
    
FROM silver.crm_cust_info ci

-- Enrich customer profiles with birthdate and gender from the ERP system
LEFT JOIN silver.erp_cust_az12 az
    ON ci.cst_key = az.cid

-- Enrich customer profiles with geographic/country data from the ERP system
LEFT JOIN silver.erp_loc_a101 loc
    ON ci.cst_key = loc.cid;
GO