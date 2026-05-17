/*
================================================================================
Description:
    This script initializes and populates the 'gold.fact_dim_customers_report' 
    table. It functions as a static reporting or data mart table that captures 
    consolidated customer demographics and behavioral metrics.

    The script uses a "Drop and Recreate" pattern followed by an INSERT INTO 
    statement. It migrates enriched data from a dynamic reporting view 
    (gold.customers_report) into a physical table to optimize query performance 
    for downstream analytics, dashboards, or ML models.

Components:
    - gold.fact_dim_customers_report : Target analytical storage table.
    - gold.customers_report          : Source gold view calculating age, 
                                       age groups, and RFM/behavioral segments.
================================================================================
*/

-- =============================================================================
-- 1. Table Initialization (Drop & Recreate)
-- =============================================================================

-- Drop the table if it already exists to guarantee a clean state before reload
IF OBJECT_ID('gold.fact_dim_customers_report', 'U') IS NOT NULL
    DROP TABLE gold.fact_dim_customers_report;
GO

-- Create the physical table structure for customer reporting
CREATE TABLE gold.fact_dim_customers_report (
    customer_key     INT PRIMARY KEY,   -- Unique surrogate key identifying the customer
    customer_number  NVARCHAR(50),      -- Operational business key
    full_name        NVARCHAR(150),     -- Standardized full name (First + Last)
    country          NVARCHAR(100),     -- Geographic country classification
    gender           NVARCHAR(10),      -- Cleansed gender value
    maritial_status  NVARCHAR(20),      -- Marital status description
    age              INT,               -- Calculated current age of the customer
    age_group        NVARCHAR(20),      -- Categorical age bracket (e.g., Youth, Adult, Senior)
    customer_segment NVARCHAR(20)       -- Behavioral marketing segment (e.g., VIP, Regular, New)
);
GO

-- =============================================================================
-- 2. Data Population Pipeline
-- =============================================================================

-- Populate the newly created table from the analytical source view
INSERT INTO gold.fact_dim_customers_report (
    customer_key,
    customer_number,
    full_name,
    country,
    gender,
    maritial_status,
    age,
    age_group,
    customer_segment
)
SELECT 
    customer_key,
    customer_number,
    full_name,
    country,
    gender,
    maritial_status,
    age,
    age_group,
    customer_segment
FROM gold.customers_report;
GO