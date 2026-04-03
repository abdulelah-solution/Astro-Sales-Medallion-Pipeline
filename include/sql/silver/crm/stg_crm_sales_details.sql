/*
===============================================================================
Staging Process: CRM Sales Details
===============================================================================
Script Purpose:
    This script cleanses and validates raw sales transaction data from the 
    'bronze.crm_sales_details' table and populates 'silver.crm_sales_details'.

Cleaning & Data Integrity Transformations:
    1. Date Validation: Converts integer/string dates to SQL DATE format, 
       handling invalid lengths or zero-values as NULL.
    2. Sales Consistency: Re-calculates Sales Amount if the provided value 
       is inconsistent with (Quantity * Price) or is invalid.
    3. Logical Imputation: Derives missing Quantity or Price based on available 
       Sales metrics using NULLIF to prevent division-by-zero errors.
    4. Sign Correction: Ensures all financial metrics (Sales, Qty, Price) 
       are positive using the ABS function.
    5. Integrity Filtering: Removes records with missing Order Numbers or dates.

Loading Strategy:
    - TRUNCATE & INSERT: Refreshes the staging table with validated transactions.
===============================================================================
*/

BEGIN TRANSACTION;

-- Clear existing records in the silver table for a fresh load
TRUNCATE TABLE silver.crm_sales_details;

-- Insert validated and reconciled sales data
INSERT INTO silver.crm_sales_details
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE
        WHEN LEN(sls_order_dt) != 8 OR sls_order_dt <= 0 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE)
    END AS sls_order_dt, -- Transform and validate Order Date
    CASE
        WHEN LEN(sls_ship_dt) != 8 OR sls_ship_dt <= 0 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE)
    END AS sls_ship_dt, -- Transform and validate Shipping Date
    CASE
        WHEN LEN(sls_due_dt) != 8 OR sls_due_dt <= 0 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE)
    END AS sls_due_dt, -- Transform and validate Due Date
    CASE
        WHEN sls_sales != sls_quantity * sls_price
             OR sls_sales <= 0
             OR sls_sales IS NULL 
                THEN ABS(sls_quantity * sls_price)
        ELSE ABS(sls_sales)
    END AS sls_sales, -- Logical Reconciliation: Re-calculate Sales if invalid or inconsistent
    CASE
        WHEN sls_quantity <= 0 OR sls_quantity IS NULL
                THEN CAST(sls_sales / NULLIF(sls_price, 0) AS INT)
        ELSE ABS(sls_quantity)
    END AS sls_quantity, -- Logical Imputation: Derive Quantity if missing/invalid
    CASE
        WHEN sls_price <= 0 OR sls_price IS NULL
                THEN CAST(sls_sales / NULLIF(sls_quantity, 0) AS DECIMAL)
        ELSE ABS(sls_price)
    END AS sls_price -- Logical Imputation: Derive Price if missing/invalid
FROM 
    bronze.crm_sales_details
WHERE 
    sls_ord_num IS NOT NULL
    AND sls_ord_num != ''
    AND sls_order_dt IS NOT NULL
    AND sls_ship_dt IS NOT NULL
    AND sls_due_dt IS NOT NULL;

COMMIT TRANSACTION;