/*
================================================================================
Description:
    This script creates or modifies the 'gold.sales_order_date_report' view.
    It serves as a specialized time-intelligence staging view that extracts, 
    transforms, and formats chronological elements directly from sales transactions.

    The view implements several data engineering patterns:
    - Normalizes dates into descriptive calendar dimensions (Weekday name, formatted 
      Quarter strings, short Month names, and Year strings).
    - Pairs these temporal fields with foundational Customer and Product surrogate keys.
    - Applies a quality gate to ensure only valid data points falling between the 
      year 2000 and the current system year are passed downstream.
    - This view acts as the direct upstream data source for populating the physical 
      'gold.dim_date' table.

Source Tables & Views:
    - gold.sales (s)          : Core analytical transactional facts.
    - gold.dim_customers (c)  : Customer dimension used to guarantee key integrity.
    - gold.dim_products (p)   : Product dimension used to guarantee key integrity.
================================================================================
*/

CREATE OR ALTER VIEW gold.sales_order_date_report AS
SELECT 
    -- Dimensional Surrogate Keys
    c.Customer_key AS customer_key,             -- Verified surrogate customer identifier
    p.product_key,                              -- Verified surrogate product identifier
    
    -- Transformed Time Intelligence Attributes
    s.sls_order_dt AS order_date,               -- Base operational transaction date
    DATENAME(WEEKDAY, s.sls_order_dt) AS order_weekday, -- Full name of the day (e.g., 'Monday')
    CONCAT('Quarter', ' ', DATEPART(QUARTER, s.sls_order_dt)) AS date_quarter, -- Calendar quarter flag (e.g., 'Quarter 2')
    FORMAT(s.sls_order_dt, 'MMM') AS order_month,       -- Three-letter month abbreviation (e.g., 'Jan')
    FORMAT(s.sls_order_dt, 'yyyy') AS order_year       -- Four-digit calendar year string (e.g., '2026')

FROM gold.sales s

-- Validate and match transactional keys against Gold dimensions
LEFT JOIN gold.dim_customers c 
    ON s.Customer_key = c.Customer_key
LEFT JOIN gold.dim_products p 
    ON s.product_key = p.product_key

WHERE 
    -- Quality Gate: Eliminate rows missing vital date timestamps
    s.sls_order_dt IS NOT NULL
    
    -- Business Rule: Enforce reasonable temporal boundaries up to the current year
    AND YEAR(s.sls_order_dt) BETWEEN 2000 AND YEAR(GETDATE());
GO