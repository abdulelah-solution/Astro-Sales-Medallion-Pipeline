/*
===============================================================================
Staging Process: CRM Product Info
===============================================================================
Script Purpose:
    This script cleanses and transforms raw product data from the 'bronze.crm_prd_info' 
    table and populates the staging table 'silver.crm_prd_info'.

Cleaning Transformations:
    1. Extracting 'cat_id' and 'prd_key' from a composite string using SUBSTRING.
    2. Handling NULL costs by defaulting to 0.
    3. Mapping short codes (M, R, S, T) to descriptive Product Line names.
    4. Calculating product validity end dates using the LEAD window function.

Loading Strategy:
    - TRUNCATE & INSERT: Refreshes the staging table with cleaned product records.
    - Transaction-wrapped: Ensures data consistency during execution.
===============================================================================
*/

BEGIN TRANSACTION;

-- Clear existing records in the silver table for a fresh load
TRUNCATE TABLE silver.crm_prd_info;

-- Insert cleansed and derived product data
INSERT INTO silver.crm_prd_info
(
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
    SUBSTRING(prd_key, 1, 5) AS cat_id, -- Extracting Category ID (first 5 characters)
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extracting the actual Product Key (starting from character 7)
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost, -- Replacing NULL costs with zero
    CASE
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line, -- Mapping Product Line codes to readable labels
    prd_start_dt,
    -- Calculating prd_end_dt based on the start date of the next version
    -- Subtracting 1 day to ensure non-overlapping validity periods
    DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
FROM
    bronze.crm_prd_info;

COMMIT TRANSACTION;