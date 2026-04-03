/*
===============================================================================
Staging Process: ERP Product Categories (G1V2)
===============================================================================
Script Purpose:
    This script cleanses and transforms raw product category data from the 
    'bronze.erp_px_cat_g1v2' table and populates 'silver.erp_px_cat_g1v2'.

Cleaning Transformations:
    1. ID Standardization: Trims whitespaces and replaces underscores '_' with 
       hyphens '-' to ensure consistency with CRM product keys.
    2. Data Preservation: Migrates category, subcategory, and maintenance 
       attributes directly for downstream modeling.

Loading Strategy:
    - TRUNCATE & INSERT: Refreshes the staging table with standardized 
      category reference data.
===============================================================================
*/

BEGIN TRANSACTION;

-- Clear existing records to ensure a fresh and accurate load
TRUNCATE TABLE silver.erp_px_cat_g1v2;

-- Insert cleansed and standardized category data
INSERT INTO silver.erp_px_cat_g1v2
(
    id,
    cat,
    subcat,
    maintenance
)
SELECT
    REPLACE(TRIM(id), '_', '-') AS id, -- Normalizing the ID format by replacing underscores with hyphens
    cat,
    subcat,
    maintenance
FROM 
    bronze.erp_px_cat_g1v2;

COMMIT TRANSACTION;