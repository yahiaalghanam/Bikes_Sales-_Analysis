/*
===============================================================================
Script Name:    Load silver.crm_prd_info
Description:    This script performs a full refresh of the silver.crm_prd_info
                table from bronze.crm_prd_info.

                Transformations applied:
                - Extracts category ID (cat_id) from prd_key.
                - Cleans product key and removes prefixes.
                - Handles NULL product cost (defaults to 0).
                - Standardizes product line values.
                - Converts start date to DATE format.
                - Derives prd_end_dt using LEAD (SCD Type 2 style).

                Data Quality Rules:
                - Prevents invalid substring operations.
                - Handles NULL and inconsistent text values.
                - Ensures valid date ranges.
                - Assigns NULL to prd_end_dt for latest active record.

Author:         Yahia Alghanam

===============================================================================
*/

BEGIN TRAN;

TRUNCATE TABLE silver.crm_prd_info;

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

transformed AS (
    SELECT
        prd_id,

        -- Safe category extraction
        CASE 
            WHEN LEN(prd_key) >= 5 
            THEN REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')
            ELSE NULL
        END AS cat_id,

        -- Safe product key extraction
        CASE 
            WHEN LEN(prd_key) >= 7 
            THEN SUBSTRING(prd_key, 7, LEN(prd_key))
            ELSE NULL
        END AS prd_key,

        LTRIM(RTRIM(prd_nm)) AS prd_nm,

        ISNULL(prd_cost, 0) AS prd_cost,

        -- Product line mapping
        CASE 
            WHEN prd_line IS NULL OR LTRIM(RTRIM(prd_line)) = '' THEN 'N/A'
            WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'S' THEN 'Other Sales'
            WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'M' THEN 'Mountain'
            WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'R' THEN 'Road'
            WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'T' THEN 'Touring'
            ELSE 'N/A'
        END AS prd_line,

        prd_start_dt,

        -- End date using LEAD (SCD logic)
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

    -- Keep NULL for current active record
    prd_end_dt

FROM transformed;

-- Validation
SELECT COUNT(*) AS inserted_rows FROM silver.crm_prd_info;

COMMIT;