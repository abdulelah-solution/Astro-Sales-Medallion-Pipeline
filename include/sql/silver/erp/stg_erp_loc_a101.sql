/*
===============================================================================
Staging Process: ERP Location Data (A101)
===============================================================================
Script Purpose:
    This script cleanses and transforms raw location data from the 'bronze.erp_loc_a101' 
    table and populates the 'silver.erp_loc_a101' table.

Cleaning Transformations:
    1. ID Standardization: Removes hyphens '-' from 'cid' to ensure consistency 
       with customer keys in other systems.
    2. Country Name Mapping: Expands country codes (e.g., 'DE', 'US', 'USA') 
       into full, readable country names.
    3. Null Handling: Standardizes missing or empty country values to 'n/a'.
    4. Data Trimming: Removes leading and trailing whitespaces for consistency.

Loading Strategy:
    - TRUNCATE & INSERT: Refreshes the staging table with standardized location records.
===============================================================================
*/

BEGIN TRANSACTION;

-- Clear existing records to maintain a clean staging environment
TRUNCATE TABLE silver.erp_loc_a101;

-- Insert cleansed and standardized location data
INSERT INTO silver.erp_loc_a101
(
    cid,
    cntry
)
SELECT
    REPLACE(cid, '-', '') AS cid, -- Removing formatting characters (hyphens) to match master customer keys
    CASE 
        WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
        WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry -- Mapping standardized country codes to full descriptive names
FROM
    bronze.erp_loc_a101;

COMMIT TRANSACTION;