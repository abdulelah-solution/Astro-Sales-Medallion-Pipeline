/*
===============================================================================
Staging Process: CRM Customer Info
===============================================================================
Script Purpose:
    This script cleanses and transforms raw customer data from the 'bronze.crm_cust_info' 
    table and populates the staging table 'silver.crm_cust_info'.

Cleaning Transformations:
    1. Trimming whitespace from key string columns.
    2. Handling NULL values by providing 'n/a' placeholders.
    3. Standardizing Gender and Marital Status codes into descriptive labels.
    4. Removing duplicates based on 'cst_id' (keeping the most recent record).
    5. Filtering out invalid or null customer IDs.

Loading Strategy:
    - TRUNCATE & INSERT: Ensures the silver table reflects the latest clean state.
    - Transaction-wrapped: Ensures data integrity during the load process.
===============================================================================
*/

BEGIN TRANSACTION;

-- Clear existing data in the silver table to ensure an idempotent load
TRUNCATE TABLE silver.crm_cust_info;

-- Insert cleansed and standardized records
INSERT INTO silver.crm_cust_info
(
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
    TRIM(cst_key) AS cst_key,
    ISNULL(TRIM(cst_firstname), 'n/a') AS cst_firstname,
    ISNULL(TRIM(cst_lastname), 'n/a') AS cst_lastname,
    CASE
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_marital_status, -- Standardizing Marital Status: S -> Single, M -> Married
    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr, -- Standardizing Gender: F -> Female, M -> Male
    cst_create_date
FROM (
    -- Internal subquery to identify and rank duplicates
    SELECT
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag,
        *
    FROM 
        bronze.crm_cust_info
    ) t 
WHERE 
    flag = 1                    -- Keep only the latest record per customer
    AND cst_id IS NOT NULL      -- Filter out records with missing IDs
    AND cst_id != 0;            -- Filter out invalid IDs

COMMIT TRANSACTION;