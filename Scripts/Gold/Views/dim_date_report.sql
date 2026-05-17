/*
================================================================================
Description:
    This script initializes and populates the 'gold.dim_date' dimension table.
    In a Star Schema warehouse design, a dedicated Date Dimension is crucial 
    for performing time-series analysis, calculating trends, and grouping 
    metrics by standard calendar intervals (days, weeks, months, quarters, years).

    The script creates a physical table structure with a standard calendar DATE 
    as the primary key, then populates it with unique chronological records extracted 
    and transformed from an staging/reporting source view (gold.sales_order_date_report).

Components:
    - gold.dim_date               : Target dimension table for time intelligence.
    - gold.sales_order_date_report: Source view containing generated chronological 
                                    attributes from transaction logs.
================================================================================
*/

-- =============================================================================
-- 1. Table Initialization (Drop & Recreate)
-- =============================================================================

-- Drop the table if it already exists to guarantee a clean state before reload
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
    DROP TABLE gold.dim_date;
GO

-- Create the physical table structure for the Date Dimension
CREATE TABLE gold.dim_date (
    date_key      DATE PRIMARY KEY,    -- Date ID in standard 'YYYY-MM-DD' format
    order_weekday NVARCHAR(20),        -- Day name of the week (e.g., Monday, Tuesday)
    date_quarter  NVARCHAR(20),        -- Calendar quarter (e.g., Q1, Q2)
    order_month   NVARCHAR(10),        -- Month name or abbreviated name (e.g., January, Jan)
    order_year    INT                  -- Calendar year identifier (e.g., 2026)
);
GO

-- =============================================================================
-- 2. Data Population Pipeline
-- =============================================================================

-- Populate the dimension table with a clean, unique set of calendar attributes
INSERT INTO gold.dim_date (
    date_key,
    order_weekday,
    date_quarter,
    order_month,
    order_year
)
SELECT DISTINCT 
    order_date,                        -- Maps to date_key
    order_weekday,                     -- Maps to order_weekday string
    date_quarter,                      -- Maps to date_quarter string
    order_month,                       -- Maps to order_month string
    CAST(order_year AS INT)            -- Ensures the year attribute is strongly typed as an integer
FROM gold.sales_order_date_report;
GO