/*
===============================================================================
Script Name:    Load silver.erp_cust_az12
Description:    This script performs a full refresh of the silver.erp_cust_az12
                table from bronze.erp_cust_az12.

                Transformations applied:
                - Cleans customer ID (cid) by removing the first 3 characters.
                - Validates birthdate (bdate):
                    * Sets NULL if date is invalid, in the future, or before 1930-01-01.
                - Standardizes gender (gen):
                    * 'M', 'MALE'   → 'Male'
                    * 'F', 'FEMALE' → 'Female'
                    * Null or Missing values   → 'N/A'

                Data Quality Rules:
                - Prevents invalid substring operations.
                - Ensures consistent date format.
                - Normalizes text values for analytics use.

Author:         Yahia Alghanam
===============================================================================
*/

BEGIN TRAN;

TRUNCATE TABLE silver.erp_cust_az12;

INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
SELECT
    CASE 
        WHEN LEN(cid) > 3 THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE NULL
    END AS cid,

    CASE 
        WHEN bdate IS NULL 
             OR bdate > CAST(GETDATE() AS DATE)
             OR bdate < '1930-01-01'
        THEN NULL
        ELSE CAST(bdate AS DATE)
    END AS bdate,

    CASE
        WHEN UPPER(LTRIM(RTRIM(gen))) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(LTRIM(RTRIM(gen))) IN ('M', 'MALE') THEN 'Male'
        ELSE 'N/A'
    END AS gen

FROM bronze.erp_cust_az12;

SELECT COUNT(*) AS inserted_rows FROM silver.erp_cust_az12;

COMMIT;