/*
================================================================================
Description:
    This DDL script initializes the 'bronze' schema layer by creating its initial
    staging tables. The script adopts a "Drop and Recreate" strategy: it checks 
    for the existence of each table, drops it if found, and defines a fresh schema.

    The tables represent raw ingestion targets from two major source systems:
    1. CRM (Customer Relationship Management) - Demographics, Products, and Sales.
    2. ERP (Enterprise Resource Planning) - Locations, Customer Details, and Categories.

Components:
    - bronze.crm_cust_info     : Raw customer profiles from CRM.
    - bronze.crm_prd_info      : Product master records from CRM.
    - bronze.crm_sales_details : Transactional sales orders from CRM.
    - bronze.erp_loc_a101      : Customer location and country mapping from ERP.
    - bronze.erp_cust_az12     : Additional customer attributes (birthdate, gender) from ERP.
    - bronze.erp_px_cat_g1v2   : Product categorization and hierarchy from ERP.
================================================================================
*/

-- =============================================================================
-- 1. Table: bronze.crm_cust_info
-- =============================================================================

-- Drop the table if it already exists to ensure a clean deployment
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

-- Create table to capture raw CRM customer details
CREATE TABLE bronze.crm_cust_info (
    cst_id             INT,             -- Unique internal customer ID
    cst_key            NVARCHAR(50),    -- Business key for the customer
    cst_firstname      NVARCHAR(50),    -- Customer's first name
    cst_lastname       NVARCHAR(50),    -- Customer's last name
    cst_marital_status NVARCHAR(50),    -- Marital status (e.g., M, S)
    cst_gndr           NVARCHAR(50),    -- Gender string
    cst_create_date    DATE             -- Account creation date
);
GO

-- =============================================================================
-- 2. Table: bronze.crm_prd_info
-- =============================================================================

-- Drop the table if it already exists
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info; 
GO

-- Create table to capture raw CRM product metadata
CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,                   -- Unique internal product ID
    prd_key      NVARCHAR(50),          -- Business key/SKU for the product
    prd_nm       NVARCHAR(50),          -- Product name
    prd_cost     INT,                   -- Base cost of the product
    prd_line     NVARCHAR(50),          -- Product line classification
    prd_start_dt DATETIME,              -- Validity start date for the product record
    prd_end_dt   DATETIME               -- Validity end date for the product record
);
GO

-- =============================================================================
-- 3. Table: bronze.crm_sales_details
-- =============================================================================

-- Drop the table if it already exists
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

-- Create table to capture raw transactional sales details
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),          -- Sales order number
    sls_prd_key  NVARCHAR(50),          -- Product key associated with the sale
    sls_cust_id  INT,                   -- Customer ID associated with the sale
    sls_order_dt INT,                   -- Order date stored as an integer key (YYYYMMDD)
    sls_ship_dt  INT,                   -- Shipping date stored as an integer key (YYYYMMDD)
    sls_due_dt   INT,                   -- Payment due date stored as an integer key (YYYYMMDD)
    sls_sales    INT,                   -- Total sales amount
    sls_quantity INT,                   -- Quantity of items purchased
    sls_price    INT                    -- Unit price of the item
);
GO

-- =============================================================================
-- 4. Table: bronze.erp_loc_a101
-- =============================================================================

-- Drop the table if it already exists
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

-- Create table to capture customer location data from ERP
CREATE TABLE bronze.erp_loc_a101 (
    cid   NVARCHAR(50),                 -- Customer ID cross-reference key
    cntry NVARCHAR(50)                  -- Country of residence
);
GO

-- =============================================================================
-- 5. Table: bronze.erp_cust_az12
-- =============================================================================

-- Drop the table if it already exists
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

-- Create table to capture demographic attributes from ERP
CREATE TABLE bronze.erp_cust_az12 (
    cid   NVARCHAR(50),                 -- Customer ID cross-reference key
    bdate DATE,                         -- Customer birthdate
    gen   NVARCHAR(50)                  -- Gender code from ERP system
);
GO

-- =============================================================================
-- 6. Table: bronze.erp_px_cat_g1v2
-- =============================================================================

-- Drop the table if it already exists
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

-- Create table to capture product categorization and hierarchies from ERP
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),           -- Category or Subcategory ID reference
    cat         NVARCHAR(50),           -- Major product category name
    subcat      NVARCHAR(50),           -- Product subcategory name
    maintenance NVARCHAR(50)            -- Maintenance flag or tier description
);
GO