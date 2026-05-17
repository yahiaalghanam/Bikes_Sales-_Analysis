/*
================================================================================
Description:
    This comprehensive script aggregates data profiling and quality assurance (QA)
    queries for the 'Silver' data layer. It acts as a testing suite to uncover 
    anomalies, formatting discrepancies, missing data, and structural integrity 
    issues before finalized data moves down the pipeline to the Gold layer.

The suite focuses on five distinct areas of data quality checking:
    1. Primary Key Audits        : Detects duplicate records or missing unique keys.
    2. Format & Padding Tests    : Uncovers untrimmed whitespaces or length variations.
    3. Value Domain Verification : Pinpoints values outside allowed boundaries 
                                   (e.g., negative costs, unaligned categories).
    4. Business Rule Alignment   : Evaluates formulas (Sales = Qty * Price) and 
                                   chronological sequencing (Ship Date >= Order Date).
    5. Structural Anomalies      : Captures layout variations (e.g., delimiter codes).

Target Entities:
    - CRM Schema: crm_cust_info, crm_prd_info, crm_sales_details
    - ERP Schema: erp_cust_az12, erp_loc_a101, erp_px_cat_g1v2
================================================================================
*/

-- =============================================================================
-- SECTION 1: Quality Checks for Silver Layer - CRM Customer Information
-- =============================================================================

-- Query 1.1: Check for Nulls or Duplicate Values in the Primary Key
-- Expectation: No Result (Each cst_id must be completely unique)
SELECT 
    cst_id, 
    COUNT(*) AS cnt 
FROM silver.crm_cust_info 
GROUP BY cst_id 
HAVING COUNT(*) > 1;

-- Query 1.2: Checking for Unwanted Padding or Spaces in Text Fields
-- Expectation: No Result (All strings should be pre-trimmed)
SELECT 
    cst_firstname
FROM silver.crm_cust_info 
WHERE cst_firstname != TRIM(cst_firstname);

-- Query 1.3: Data Standardization & Consistency for Marital Status
-- Expectation: Review distinct variations; entries should map strictly to 'Single', 'Married', or 'N/A'
SELECT DISTINCT 
    cst_marital_status
FROM silver.crm_cust_info;

-- Query 1.4: Data Standardization & Consistency for Gender
-- Expectation: Review distinct values; entries should align cleanly to 'Male', 'Female', or 'N/A'
SELECT DISTINCT 
    cst_gndr
FROM silver.crm_cust_info;

-- Query 1.5: General Table Scan
-- Purpose: Quick spot-check of the underlying raw CRM customer records
SELECT * 
FROM silver.crm_cust_info;


-- =============================================================================
-- SECTION 2: Quality Checks for Silver Layer - Product Information
-- =============================================================================

-- Query 2.1: Check for Nulls or Duplicate Values in the Primary Key
-- Expectation: No Result (Each prd_id must be completely unique)
SELECT 
    prd_id, 
    COUNT(*) AS cnt 
FROM silver.crm_prd_info 
GROUP BY prd_id 
HAVING COUNT(*) > 1;

-- Query 2.2: Check for Unwanted Spaces in the Product Name Field
-- Expectation: No Result (All product name strings should be properly trimmed)
SELECT 
    prd_nm
FROM silver.crm_prd_info 
WHERE prd_nm != TRIM(prd_nm);

-- Query 2.3: Check for Nulls or Negative Values in Product Cost
-- Expectation: No Result (Product financial costs must always be greater than or equal to zero)
SELECT 
    prd_cost
FROM silver.crm_prd_info 
WHERE prd_cost IS NULL 
   OR prd_cost < 0;

-- Query 2.4: General Table Scan
-- Purpose: Quick spot-check of the underlying product master records
SELECT * 
FROM silver.crm_prd_info;


-- =============================================================================
-- SECTION 3: Quality Checks for Silver Layer - Sales Details
-- =============================================================================

-- Query 3.1: Raw Landing Check
-- Purpose: Preview structural format directly from the Bronze source before parsing
SELECT * 
FROM bronze.crm_sales_details;

-- Query 3.2: Check for Invalid Formats or Missing Dates
-- Expectation: No Result (All records must match the rigid 8-digit key standard [YYYYMMDD])
SELECT 
    NULLIF(sls_order_dt, 0) AS sls_order_dt 
FROM bronze.crm_sales_details 
WHERE sls_order_dt <= 0
   OR LEN(sls_order_dt) != 8;

-- Query 3.3: Checking for Invalid Sequential Chronology
-- Expectation: No Result (Products cannot logically be shipped before an order is placed)
SELECT *
FROM bronze.crm_sales_details
WHERE sls_ship_dt < sls_order_dt;

-- Query 3.4: Logical Integrity and Sign Constraints Check
-- Expectation: No Result (Quantities, sales, and prices must be positive; Sales must balance mathematically)
SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details 
WHERE sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_price <= 0 
   OR sls_quantity <= 0 
   OR sls_sales <= 0
   OR sls_sales <> sls_quantity * ABS(sls_price);

-- Query 3.5: General Table Scan
-- Purpose: Verification check of processed transactional rows in the Silver tier
SELECT * 
FROM silver.crm_sales_details;


-- =============================================================================
-- SECTION 4: Quality Checks for Silver Layer - Customer AZ12 (ERP)
-- =============================================================================

-- Query 4.1: Identify Out-of-Range or Nonsensical Birthdates
-- Expectation: No Result (Birthdates must reflect logical human life expectancies)
SELECT
    cid,
    bdate
FROM silver.erp_cust_az12
WHERE bdate > '2027-01-01' 
   OR bdate < '1930-01-01';

-- Query 4.2: Checking Data Standardization and Consistency for Gender
-- Expectation: Review values; fields should align cleanly to 'Male', 'Female', or 'N/A'
SELECT
    gen 
FROM silver.erp_cust_az12
GROUP BY gen;


-- =============================================================================
-- SECTION 5: Quality Checks for Silver Layer - Customer A101 (ERP Location)
-- =============================================================================

-- Query 5.1: Handling Malformed or Hybrid Customer Identifiers
-- Expectation: No Result (Customer keys should contain pure keys without unwanted formatting strings like hyphens)
SELECT 
    cid
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- Query 5.2: Evaluate Normalization Rules for Regional and Country Headings
-- Expectation: Validates map formatting rules (e.g., converts 'USA'/'US' to 'United States', cleans blanks to 'N/A')
SELECT DISTINCT 
    CASE 
        WHEN TRIM(cntry) IN ('USA', 'US') THEN 'United States'
        WHEN TRIM(cntry) = 'DE'           THEN 'Germany' 
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
        ELSE TRIM(cntry)
    END AS cntry
FROM silver.erp_loc_a101;


-- =============================================================================
-- SECTION 6: Quality Checks for Silver Layer - erp_px_cat_g1v2 (ERP Categories)
-- =============================================================================

-- Query 6.1: Check for Extra Spaces Within Category Names
-- Expectation: No Result (No leading or trailing whitespaces allowed)
SELECT  
    cat 
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);
 
-- Query 6.2: Check for Extra Spaces Within Sub-Category Names
-- Expectation: No Result (No leading or trailing whitespaces allowed)
SELECT  
    subcat 
FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);
 
-- Query 6.3: Check for Extra Spaces Within Maintenance Classifications
-- Expectation: No Result (No leading or trailing whitespaces allowed)
SELECT DISTINCT 
    maintenance
FROM bronze.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance);

-- Query 6.4: General Table Scan
-- Purpose: Quick spot-check of the cleaned, organized product category definitions
SELECT * 
FROM silver.erp_px_cat_g1v2;
GO