/*
================================================================================
Description:
    This stored procedure orchestrates a full TRUNCATE and RELOAD ETL pipeline 
    for the complete 'bronze' schema layer. It functions as the primary ingestion 
    mechanism for pulling raw source files directly into the SQL Server data warehouse.

Design Patterns & Mechanics:
    - Target Cleanse  : Truncates each destination table prior to file insertion, 
                        wiping historical landing records to prevent duplication.
    - Bulk Operations : Utilizes high-performance BULK INSERT commands with table 
                        locks (TABLOCK) optimized for large flat-file extractions.
    - Status Tracking : Emits real-time step-by-step console print logs, enabling 
                        engineers to easily trace pipeline execution velocity.
    - Fault Isolation : Wrapped completely inside a TRY...CATCH block to intercept 
                        file read anomalies, permission blocks, or data formatting 
                        errors without breaking the database thread.

Source Files (CSV Format):
    - CRM System Directory : source_crm/ (cust_info.csv, prd_info.csv, sales_details.csv)
    - ERP System Directory : source_erp/ (CUST_AZ12.csv, LOC_A101.csv, PX_CAT_G1V2.csv)
================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN 
    BEGIN TRY
        -- =============================================================================
        -- Pipeline Logging Initialization
        -- =============================================================================
        PRINT '===============================================================================';
        PRINT 'INITIALIZING BATCH RUN: Loading Bronze Schema Tables...';
        PRINT '===============================================================================';

        -- =============================================================================
        -- PHASE 1: Processing CRM System Flat Files
        -- =============================================================================
        PRINT '-------------------------------------------------------------------------------';
        PRINT 'PHASE 1: Processing CRM Source Extraction Files...';
        PRINT '-------------------------------------------------------------------------------';
        
        -- Ingesting CRM Customer Profile Data
        PRINT '>> Ingesting: cust_info.csv';
        TRUNCATE TABLE bronze.crm_cust_info;
        BULK INSERT bronze.crm_cust_info
        FROM 'E:\Data with Baraa Course\Data Warehouse Project Material\sql-data-warehouse-project\datasets\source_crm/cust_info.csv'
        WITH (
            FIRSTROW        = 2,    -- Ignore header columns
            FIELDTERMINATOR = ',',  -- Comma-separated variable mapping
            ROWTERMINATOR   = '\n', -- Standard newline record breaks
            TABLOCK                 -- Restricts indexing overhead during load
        );
        PRINT '   [SUCCESS] Loaded table: bronze.crm_cust_info';

        -- Ingesting CRM Product Master Data
        PRINT '>> Ingesting: prd_info.csv';
        TRUNCATE TABLE bronze.crm_prd_info;
        BULK INSERT bronze.crm_prd_info
        FROM 'E:\Data with Baraa Course\Data Warehouse Project Material\sql-data-warehouse-project\datasets\source_crm/prd_info.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK
        );
        PRINT '   [SUCCESS] Loaded table: bronze.crm_prd_info';

        -- Ingesting CRM Logistical Sales Fact Logs
        PRINT '>> Ingesting: sales_details.csv';
        TRUNCATE TABLE bronze.crm_sales_details;
        BULK INSERT bronze.crm_sales_details
        FROM 'E:\Data with Baraa Course\Data Warehouse Project Material\sql-data-warehouse-project\datasets\source_crm/sales_details.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK
        );
        PRINT '   [SUCCESS] Loaded table: bronze.crm_sales_details';

        -- =============================================================================
        -- PHASE 2: Processing ERP System Flat Files
        -- =============================================================================
        PRINT '===============================================================================';
        PRINT 'CRM Ingestion complete. Diverting pipeline to ERP extraction systems...'; 
        PRINT '===============================================================================';

        PRINT '-------------------------------------------------------------------------------';
        PRINT 'PHASE 2: Processing ERP Source Extraction Files...';
        PRINT '-------------------------------------------------------------------------------';

        -- Ingesting ERP Additional Demographics
        PRINT '>> Ingesting: CUST_AZ12.csv';
        TRUNCATE TABLE bronze.erp_cust_az12;
        BULK INSERT bronze.erp_cust_az12
        FROM 'E:\Data with Baraa Course\Data Warehouse Project Material\sql-data-warehouse-project\datasets\source_erp/CUST_AZ12.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK
        );
        PRINT '   [SUCCESS] Loaded table: bronze.erp_cust_az12';

        -- Ingesting ERP Regional Geographic Codes
        PRINT '>> Ingesting: LOC_A101.csv';
        TRUNCATE TABLE bronze.erp_loc_a101;
        BULK INSERT bronze.erp_loc_a101
        FROM 'E:\Data with Baraa Course\Data Warehouse Project Material\sql-data-warehouse-project\datasets\source_erp/LOC_A101.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK
        );
        PRINT '   [SUCCESS] Loaded table: bronze.erp_loc_a101';

        -- Ingesting ERP Hierarchical Product Categorization
        PRINT '>> Ingesting: PX_CAT_G1V2.csv';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'E:\Data with Baraa Course\Data Warehouse Project Material\sql-data-warehouse-project\datasets\source_erp/PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK
        );
        PRINT '   [SUCCESS] Loaded table: bronze.erp_px_cat_g1v2';

        -- =============================================================================
        -- Execution Wrap-up
        -- =============================================================================
        PRINT '===============================================================================';
        PRINT 'BATCH COMPLETE: All target file extractions successfully loaded into Bronze!';
        PRINT 'Data schema layer is primed and ready for Silver transformation routines.';
        PRINT '===============================================================================';
    END TRY
    
    BEGIN CATCH
        -- Catch block for capture, isolation, and routing of ingestion failures
        PRINT '*******************************************************************************';
        PRINT 'CRITICAL INTERRUPT: An error occurred during the staging process execution.';
        PRINT 'Error Log Message Output Detail:';
        PRINT ERROR_MESSAGE();
        PRINT '*******************************************************************************';
    END CATCH
END;
GO

-- =============================================================================
-- Execute Batch Pipeline Initialization Test Run
-- =============================================================================
EXECUTE bronze.load_bronze;
GO