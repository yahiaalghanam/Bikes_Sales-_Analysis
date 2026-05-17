/*
================================================================================
Description:
    This DDL script initializes the 'silver' schema layer by creating cleansed 
    and structured tables. The script adopts a "Drop and Recreate" deployment 
    strategy to establish a fresh structure before ETL execution.

    Unlike the raw Bronze tier, the Silver layer represents processed data:
    - Standardizes fundamental data types (such as DATE types for transactions).
    - Features structural metadata (`dwh_create_date`) utilizing system defaults
      to record row-level processing lineage and ingestion timestamps.

Components:
    - silver.crm_cust_info     : Processed customer records from CRM.
    - silver.crm_prd_info      : Processed product metadata containing structural 
                                 category linkages (`cat_id`) from CRM.
    - silver.crm_sales_details : Processed sales transactions with cast date objects.
    - silver.erp_loc_a101      : Cleansed localized ERP country records.
    - silver.erp_cust_az12     : Processed demographic data points from ERP.
    - silver.erp_px_cat_g1v2   : Processed product master categorizations from ERP.
================================================================================
*/

-- =============================================================================
-- 1. Table: silver.crm_cust_info
-- =============================================================================

-- Safely drop the table if it already exists before recreating
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

-- Create table for cleansed and formatted CRM customer profiles
CREATE TABLE silver.crm_cust_info (
    cst_id             INT,                                 -- Unique internal customer ID
    cst_key            NVARCHAR(50),                        -- Business operational key
    cst_firstname      NVARCHAR(50),                        -- Customer first name
    cst_lastname       NVARCHAR(50),                        -- Customer last name
    cst_marital_status NVARCHAR(50),                        -- Marital status
    cst_gndr           NVARCHAR(50),                        -- Gender value
    cst_create_date    DATE,                                -- Source record creation date
    dwh_create_date    DATETIME DEFAULT GETDATE()           -- Warehouse metadata tracking timestamp
);
GO

-- =============================================================================
-- 2. Table: silver.crm_prd_info
-- =============================================================================

-- Safely drop the table if it already exists
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info; 
GO

-- Create table for cleansed and structured CRM product master data
CREATE TABLE silver.crm_prd_info (
    prd_id          INT,                                    -- Unique internal product ID
    cat_id          NVARCHAR(50),                           -- Subcategory foreign key linking to ERP mapping
    prd_key         NVARCHAR(50),                           -- Product SKU / Business key
    prd_nm          NVARCHAR(50),                           -- Standardized product name
    prd_cost        INT,                                    -- Product financial cost
    prd_line        NVARCHAR(50),                           -- Product line division mapping
    prd_start_dt    DATE,                                   -- Historical record activation date
    prd_end_dt      DATE,                                   -- Historical record expiration date
    dwh_create_date DATETIME DEFAULT GETDATE()              -- Warehouse metadata tracking timestamp
);
GO

-- =============================================================================
-- 3. Table: silver.crm_sales_details
-- =============================================================================

-- Safely drop the table if it already exists
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

-- Create table for cleansed transactional sales metrics with strongly typed fields
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),                           -- Sales order identification string
    sls_prd_key     NVARCHAR(50),                           -- Product SKU reference code
    sls_cust_id     INT,                                    -- Customer identifier code
    sls_order_dt    DATE,                                   -- Transaction date object
    sls_ship_dt     DATE,                                   -- Fulfilled shipping date object
    sls_due_dt      DATE,                                   -- Invoice due date object
    sls_sales       INT,                                    -- Gross sales metric
    sls_quantity    INT,                                    -- Item purchase count metric
    sls_price       INT,                                    -- Item price metric
    dwh_create_date DATETIME DEFAULT GETDATE()              -- Warehouse metadata tracking timestamp
);
GO

-- =============================================================================
-- 4. Table: silver.erp_loc_a101
-- =============================================================================

-- Safely drop the table if it already exists
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

-- Create table for cleansed geographic location metrics from ERP
CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR(50),                           -- Customer entity cross-reference key
    cntry           NVARCHAR(50),                           -- Cleansed target country name
    dwh_create_date DATETIME DEFAULT GETDATE()              -- Warehouse metadata tracking timestamp
);
GO

-- =============================================================================
-- 5. Table: silver.erp_cust_az12
-- =============================================================================

-- Safely drop the table if it already exists
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

-- Create table for cleansed additional core demographic data from ERP
CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR(50),                           -- Customer entity cross-reference key
    bdate           DATE,                                   -- Customer birthdate timestamp
    gen             NVARCHAR(50),                           -- Cleansed gender value
    dwh_create_date DATETIME DEFAULT GETDATE()              -- Warehouse metadata tracking timestamp
);
GO

-- =============================================================================
-- 6. Table: silver.erp_px_cat_g1v2
-- =============================================================================

-- Safely drop the table if it already exists
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

-- Create table for processed descriptive product hierarchies from ERP
CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR(50),                           -- Category classification key identifier
    cat             NVARCHAR(50),                           -- Master category designation
    subcat          NVARCHAR(50),                           -- Sub-category designation
    maintenance     NVARCHAR(50),                           -- Service tier metadata
    dwh_create_date DATETIME DEFAULT GETDATE()              -- Warehouse metadata tracking timestamp
);
GO