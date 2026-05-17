/*
===============================================================================
Procedure Name:  silver.load_silver

Description:
    This stored procedure performs a full refresh of all Silver Layer tables
    from Bronze Layer sources in the data warehouse.

    It is part of the ETL pipeline and is responsible for:
    - Data cleansing (trimming, null handling, standardization)
    - Data transformation (business rules, mapping, derivations)
    - Data deduplication (latest record selection using ROW_NUMBER)
    - Data type standardization (dates, numeric fixes)
    - Surrogate business logic preparation for analytics layer

Source Layers:
    - bronze.crm_cust_info
    - bronze.crm_prd_info
    - bronze.crm_sales_details
    - bronze.erp_cust_az12
    - bronze.erp_loc_a101
    - bronze.erp_px_cat_g1v2

Target Layer:
    - silver schema tables (cleaned and transformed data)

Load Type:
    - Full Load (TRUNCATE + INSERT)

Error Handling:
    - TRY...CATCH block captures runtime errors
    - Error messages are printed for debugging

Author:         Yahia Alghanam
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    BEGIN TRY
        -- =====================================================================
        -- Pipeline Logging Initialization
        -- =====================================================================
        PRINT '===============================================================================';
        PRINT ' BATCH RUN STARTED: Loading Silver Schema Tables...';
        PRINT '===============================================================================';

        -- =====================================================================
        -- 1. Table: silver.crm_cust_info
        -- =====================================================================
        PRINT '--> Loading Table: silver.crm_cust_info...';

        TRUNCATE TABLE silver.crm_cust_info;
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            
            -- Standardize Marital Status descriptions
            CASE 
                WHEN TRIM(UPPER(cst_marital_status)) = 'S' THEN 'Single'
                WHEN TRIM(UPPER(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'N/A'
            END AS cst_marital_status,

            -- Standardize Gender descriptions
            CASE 
                WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Male'
                WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'N/A'
            END AS cst_gndr,
            
            cst_create_date
        FROM (
            -- Window function to identify and isolate duplicate rows based on update history
            SELECT 
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC
                ) AS rn
            FROM bronze.crm_cust_info
        ) t
        WHERE rn = 1; -- Retain only the most recent customer state
        
        PRINT '   [SUCCESS] Loaded table: silver.crm_cust_info';

        -- =====================================================================
        -- 2. Table: silver.crm_prd_info
        -- =====================================================================
        PRINT '--> Loading Table: silver.crm_prd_info...';

        TRUNCATE TABLE silver.crm_prd_info;

        -- Extract base records and normalize start date
        WITH base AS (
            SELECT
                prd_id,
                prd_key,
                prd_nm,
                prd_cost,
                prd_line,
                CAST(prd_start_dt AS DATE) AS prd_start_dt
            FROM bronze.crm_prd_info
        ),

        -- Apply string manipulation and business transformations
        transformed AS (
            SELECT
                prd_id,

                -- Extract category key component out of composite operational SKU text
                CASE 
                    WHEN LEN(prd_key) >= 5 
                    THEN REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')
                    ELSE NULL
                END AS cat_id,

                -- Isolate pure product reference key string out of composite operational SKU text
                CASE 
                    WHEN LEN(prd_key) >= 7 
                    THEN SUBSTRING(prd_key, 7, LEN(prd_key))
                    ELSE NULL
                END AS prd_key,

                LTRIM(RTRIM(prd_nm)) AS prd_nm,
                ISNULL(prd_cost, 0) AS prd_cost,

                -- Map abbreviation flags into full product line system categories
                CASE 
                    WHEN prd_line IS NULL OR LTRIM(RTRIM(prd_line)) = '' THEN 'N/A'
                    WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'S' THEN 'Other Sales'
                    WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'M' THEN 'Mountain'
                    WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'R' THEN 'Road'
                    WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'T' THEN 'Touring'
                    ELSE 'N/A'
                END AS prd_line,

                prd_start_dt,

                -- Derive historical record closure bounds (SCD Type 2 validation logic)
                DATEADD(DAY, -1,
                    LEAD(prd_start_dt) OVER (
                        PARTITION BY prd_key 
                        ORDER BY prd_start_dt
                    )
                ) AS prd_end_dt
            FROM base
        )

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt -- Remaining active configurations properly preserve an explicit NULL value
        FROM transformed;
        
        PRINT '   [SUCCESS] Loaded table: silver.crm_prd_info';

        -- =====================================================================
        -- 3. Table: silver.crm_sales_details
        -- =====================================================================
        PRINT '--> Loading Table: silver.crm_sales_details...';

        TRUNCATE TABLE silver.crm_sales_details;
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Standardize and cast raw integers to strong DATE data types (style 112 = yyyymmdd)
            TRY_CONVERT(DATE, NULLIF(CAST(sls_order_dt AS VARCHAR(20)), '0'), 112) AS sls_order_dt,
            TRY_CONVERT(DATE, NULLIF(CAST(sls_ship_dt  AS VARCHAR(20)), '0'), 112) AS sls_ship_dt,
            TRY_CONVERT(DATE, NULLIF(CAST(sls_due_dt   AS VARCHAR(20)), '0'), 112) AS sls_due_dt,

            -- Audit and recalculate metrics if raw fields are missing or logically broken
            CASE 
                WHEN sls_quantity IS NULL OR sls_price IS NULL THEN NULL
                WHEN sls_sales IS NULL OR sls_sales <> (sls_quantity * ABS(sls_price))
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Fallback formula loop to reconstruct missing or negative line item prices
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0 THEN 
                    CASE 
                        WHEN sls_quantity IS NULL OR sls_quantity = 0 THEN NULL
                        ELSE sls_sales / NULLIF(sls_quantity, 0)
                    END
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;
        
        PRINT '   [SUCCESS] Loaded table: silver.crm_sales_details';

        -- =====================================================================
        -- 4. Table: silver.erp_cust_az12
        -- =====================================================================
        PRINT '--> Loading Table: silver.erp_cust_az12...';

        -- NOTE: Re-aligned target reference from erp_px_cat_g1v2 to the proper table matching block heading
        TRUNCATE TABLE silver.erp_cust_az12;
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT 
            -- Safely clean hyphens from structural ERP identifiers
            CASE 
                WHEN cid IS NOT NULL THEN REPLACE(cid, '-', '')
                ELSE NULL
            END AS cid,

            -- Handle future out-of-bounds birthdates cleanly
            CASE 
                WHEN bdate > GETDATE() THEN NULL 
                ELSE bdate 
            END AS bdate,

            -- Map and normalize structural system labels into standardized gender fields
            CASE 
                WHEN TRIM(UPPER(gen)) IN ('M', 'MALE')   THEN 'Male'
                WHEN TRIM(UPPER(gen)) IN ('F', 'FEMALE') THEN 'Female'
                ELSE 'N/A'
            END AS gen
        FROM bronze.erp_cust_az12;
        
        PRINT '   [SUCCESS] Loaded table: silver.erp_cust_az12';

        -- =====================================================================
        -- 5. Table: silver.erp_loc_a101
        -- =====================================================================
        PRINT '--> Loading Table: silver.erp_loc_a101...';

        TRUNCATE TABLE silver.erp_loc_a101;
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            -- Safely clean hyphens from spatial cross-reference indices
            CASE 
                WHEN cid IS NOT NULL THEN REPLACE(cid, '-', '')
                ELSE NULL
            END AS cid,

            -- Standardize heterogeneous country abbreviation variants to canonical values
            CASE 
                WHEN cntry IS NULL OR LTRIM(RTRIM(cntry)) = '' THEN 'N/A'
                WHEN UPPER(LTRIM(RTRIM(cntry))) IN ('USA', 'US') THEN 'United States'
                WHEN UPPER(LTRIM(RTRIM(cntry))) = 'DE' THEN 'Germany'
                ELSE LTRIM(RTRIM(cntry))
            END AS cntry
        FROM bronze.erp_loc_a101;

        PRINT '   [SUCCESS] Loaded table: silver.erp_loc_a101';

        -- =====================================================================
        -- 6. Table: silver.erp_px_cat_g1v2
        -- =====================================================================
        PRINT '--> Loading Table: silver.erp_px_cat_g1v2...';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT
            id,
            ISNULL(NULLIF(LTRIM(RTRIM(cat)), ''), 'N/A') AS cat,
            ISNULL(NULLIF(LTRIM(RTRIM(subcat)), ''), 'N/A') AS subcat,
            ISNULL(NULLIF(LTRIM(RTRIM(maintenance)), ''), 'N/A') AS maintenance
        FROM bronze.erp_px_cat_g1v2;

        PRINT '   [SUCCESS] Loaded table: silver.erp_px_cat_g1v2';

        -- =====================================================================
        -- Pipeline Logging Wrap-up
        -- =====================================================================
        PRINT '===============================================================================';
        PRINT ' BATCH RUN COMPLETE: Silver Schema Layer Refreshed Successfully!';
        PRINT '===============================================================================';

    END TRY
    BEGIN CATCH
        -- Fault isolation mechanism for capturing runtime errors
        PRINT '*******************************************************************************';
        PRINT ' CRITICAL INTERRUPT: Processing halted due to error in Silver Pipeline.';
        PRINT ' Details:';
        PRINT ERROR_MESSAGE();
        PRINT '*******************************************************************************';
    END CATCH
END;
GO