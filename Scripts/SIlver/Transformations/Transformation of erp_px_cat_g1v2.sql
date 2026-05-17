/*
===============================================================================
Script Name:    Load silver.erp_px_cat_g1v2
Description:    This script performs a full refresh of the silver.erp_px_cat_g1v2
                table from bronze.erp_px_cat_g1v2.

                Transformations applied:
                - Cleans text fields (cat, subcat, maintenance).
                - Handles NULL and empty values.
                - Standardizes text formatting.

                Data Quality Rules:
                - Ensures no leading/trailing spaces.
                - Replaces NULL or blank values with 'N/A'.
                - Keeps data consistent for downstream consumption.

Author:         Yahia Alghanam
===============================================================================
*/

BEGIN TRAN;

TRUNCATE TABLE silver.erp_px_cat_g1v2;

INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
SELECT 
    id,

    -- Clean category
    CASE 
        WHEN cat IS NULL OR LTRIM(RTRIM(cat)) = '' THEN 'N/A'
        ELSE LTRIM(RTRIM(cat))
    END AS cat,

    -- Clean subcategory
    CASE 
        WHEN subcat IS NULL OR LTRIM(RTRIM(subcat)) = '' THEN 'N/A'
        ELSE LTRIM(RTRIM(subcat))
    END AS subcat,

    -- Clean maintenance
    CASE 
        WHEN maintenance IS NULL OR LTRIM(RTRIM(maintenance)) = '' THEN 'N/A'
        ELSE LTRIM(RTRIM(maintenance))
    END AS maintenance

FROM bronze.erp_px_cat_g1v2;

-- Validation
SELECT COUNT(*) AS inserted_rows FROM silver.erp_px_cat_g1v2;

COMMIT;