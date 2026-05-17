/*
===============================================================================
Script Name:    Load silver.erp_loc_a101
Description:    This script performs a full refresh of the silver.erp_loc_a101
                table from bronze.erp_loc_a101.

                Transformations applied:
                - Cleans customer ID (cid) by removing hyphens.
                - Standardizes country values (cntry):
                    * 'USA', 'US' → 'United States'
                    * 'DE'        → 'Germany'
                    * NULL/empty  → 'N/A'
                    * Otherwise   → trimmed original value

                Data Quality Rules:
                - Handles NULL and blank country values.
                - Normalizes text for consistent reporting.
                - Ensures cleaned customer IDs.

Author:         Yahia Alghanam

===============================================================================
*/

BEGIN TRAN;

TRUNCATE TABLE silver.erp_loc_a101;

INSERT INTO silver.erp_loc_a101 (cid, cntry)
SELECT
    -- Clean CID (handle NULL safely)
    CASE 
        WHEN cid IS NOT NULL THEN REPLACE(cid, '-', '')
        ELSE NULL
    END AS cid,

    -- Standardize country values
    CASE 
        WHEN cntry IS NULL OR LTRIM(RTRIM(cntry)) = '' THEN 'N/A'
        WHEN UPPER(LTRIM(RTRIM(cntry))) IN ('USA', 'US') THEN 'United States'
        WHEN UPPER(LTRIM(RTRIM(cntry))) = 'DE' THEN 'Germany'
        ELSE LTRIM(RTRIM(cntry))
    END AS cntry

FROM bronze.erp_loc_a101;

-- Validation
SELECT COUNT(*) AS inserted_rows FROM silver.erp_loc_a101;

COMMIT;