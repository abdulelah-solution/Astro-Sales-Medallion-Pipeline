/*
===============================================================================
Staging Process: ERP Customer Data (AZ12)
===============================================================================
Script Purpose:
    This script cleanses and transforms raw customer data from the 'bronze.erp_cust_az12' 
    table and populates the 'silver.erp_cust_az12' table.

Cleaning Transformations:
    1. Key Standardization: Removes the 'NAS' prefix from 'cid' to ensure 
       compatibility with CRM customer keys.
    2. Date Validation: Nullifies any birth dates ('bdate') that are in the 
       future to maintain logical consistency.
    3. Gender Harmonization: Maps various gender inputs (F, Female, M, Male) 
       to a standardized format ('Female', 'Male').
    4. Quality Filter: Excludes records where birth date is missing.

Loading Strategy:
    - TRUNCATE & INSERT: Replaces current staging data with fresh, cleaned records.
===============================================================================
*/

BEGIN TRANSACTION;

-- Clear existing records to ensure an idempotent load process
TRUNCATE TABLE silver.erp_cust_az12;

-- Insert cleansed and standardized ERP customer data
INSERT INTO silver.erp_cust_az12
(
    cid,
    bdate,
    gen
)
SELECT 
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE TRIM(cid)
    END AS cid, -- Standardizing Customer ID by removing 'NAS' prefix if present
    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate, -- Validating birth dates to prevent future-dated entries
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'Male') THEN 'Male'
        ELSE 'n/a'
    END AS gen -- Standardizing Gender labels to match the Data Warehouse convention
FROM 
    bronze.erp_CUST_AZ12
WHERE 
    bdate IS NOT NULL; -- Ensure data quality by filtering out missing dates

COMMIT TRANSACTION;