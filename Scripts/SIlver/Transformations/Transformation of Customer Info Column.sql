/*
===============================================================================
Script Name:    Load silver.crm_cust_info
Description:    This script performs a full refresh of the silver.crm_cust_info
                table from bronze.crm_cust_info.

                Transformations applied:
                - Deduplicates records using ROW_NUMBER (latest cst_create_date).
                - Cleans first and last names (removes leading/trailing spaces).
                - Standardizes marital status:
                    * 'S' → 'Single'
                    * 'M' → 'Married'
                    * Null or Missing Values  → 'N/A'
                - Standardizes gender:
                    * 'M' → 'Male'
                    * 'F' → 'Female'
                    * Null or Empty Values  → 'N/A'

                Data Quality Rules:
                - Keeps only the most recent record per customer (cst_id).
                - Handles NULLs and inconsistent casing.
                - Ensures clean string values for downstream analytics.

Author:         Yahia Alghanam
===============================================================================
*/


TRUNCATE TABLE silver.crm_cust_info;

WITH dedup AS (
    SELECT
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS rn
    FROM bronze.crm_cust_info
)

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

    -- Clean names
    LTRIM(RTRIM(cst_firstname)) AS cst_firstname,
    LTRIM(RTRIM(cst_lastname))  AS cst_lastname,

    -- Marital Status Mapping
    CASE 
        WHEN cst_marital_status IS NULL 
             OR LTRIM(RTRIM(cst_marital_status)) = '' THEN 'N/A'
        WHEN UPPER(LTRIM(RTRIM(cst_marital_status))) = 'S' THEN 'Single'
        WHEN UPPER(LTRIM(RTRIM(cst_marital_status))) = 'M' THEN 'Married'
        ELSE 'N/A'
    END AS cst_marital_status,

    -- Gender Mapping
    CASE 
        WHEN cst_gndr IS NULL 
             OR LTRIM(RTRIM(cst_gndr)) = '' THEN 'N/A'
        WHEN UPPER(LTRIM(RTRIM(cst_gndr))) = 'M' THEN 'Male'
        WHEN UPPER(LTRIM(RTRIM(cst_gndr))) = 'F' THEN 'Female'
        ELSE 'N/A'
    END AS cst_gndr,

    -- Ensure consistent date type
    CAST(cst_create_date AS DATE) AS cst_create_date

FROM dedup
WHERE rn = 1 AND cst_id IS NOT NULL;

-- Validation
SELECT COUNT(*) AS inserted_rows FROM silver.crm_cust_info;
