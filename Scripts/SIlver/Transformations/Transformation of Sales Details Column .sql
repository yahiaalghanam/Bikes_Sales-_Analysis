/*
===============================================================================
Script Name:    Load silver.crm_sales_details
Description:    This script performs a full refresh of silver.crm_sales_details
                from bronze.crm_sales_details.

                Transformations applied:
                - Converts date fields using safe conversion (handles invalid '0').
                - Recalculates sales if inconsistent with quantity × price.
                - Derives price if missing or invalid.
                - Ensures data consistency for analytical reporting.

                Data Quality Rules:
                - Invalid dates ('0') are converted to NULL.
                - Sales is validated against business formula.
                - Price is derived when missing or zero.
                - Prevents divide-by-zero errors.

Author:         Yahia Alghanam
===============================================================================
*/

BEGIN TRAN;

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

    -- Safe date parsing (style 112 = yyyymmdd)
    TRY_CONVERT(DATE, NULLIF(CAST(sls_order_dt AS VARCHAR(20)), '0'), 112) AS sls_order_dt,
    TRY_CONVERT(DATE, NULLIF(CAST(sls_ship_dt  AS VARCHAR(20)), '0'), 112) AS sls_ship_dt,
    TRY_CONVERT(DATE, NULLIF(CAST(sls_due_dt   AS VARCHAR(20)), '0'), 112) AS sls_due_dt,

    -- Validate / recalculate sales
    CASE 
        WHEN sls_quantity IS NULL OR sls_price IS NULL THEN NULL
        WHEN sls_sales IS NULL 
             OR sls_sales <> (sls_quantity * ABS(sls_price))
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    -- Validate / derive price
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0 THEN 
            CASE 
                WHEN sls_quantity IS NULL OR sls_quantity = 0 THEN NULL
                ELSE sls_sales / NULLIF(sls_quantity, 0)
            END
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details;

-- Validation
SELECT COUNT(*) AS inserted_rows 
FROM silver.crm_sales_details;

COMMIT;