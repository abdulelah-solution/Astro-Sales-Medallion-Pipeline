/*
===============================================================================
Dimension Strategy: Gold Layer - Customers
===============================================================================
Script Purpose:
    This script creates the 'gold.dim_customers' view, representing the final 
    Customer Dimension in the Data Warehouse. It unifies customer data from 
    CRM and ERP systems into a single, enriched record.

Integration Logic:
    1. Primary Source: 'silver.crm_cust_info' (Core Customer Attributes).
    2. Enrichment: Integrates 'silver.erp_cust_az12' for Birthdate and Gender.
    3. Localization: Integrates 'silver.erp_loc_a101' for Geographic information.
    4. Conflict Resolution: Prioritizes CRM gender data, falling back to ERP 
       data via COALESCE if CRM is 'n/a'.
    5. Surrogate Key: Generates 'customer_key' using ROW_NUMBER() for Star Schema optimization.

Note:
    The use of 'CREATE OR ALTER VIEW' ensures that the presentation layer 
    is easily updatable without dropping dependencies.
===============================================================================
*/

CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
    -- Surrogate Key for Star Schema modeling
    ROW_NUMBER() OVER(ORDER BY ci.cst_id)   AS customer_key,
    ci.cst_id                               AS customer_id,
    ci.cst_key                              AS customer_number,
    ci.cst_firstname                        AS first_name,
    ci.cst_lastname                         AS last_name,
    cl.cntry                                AS country,
    ci.cst_marital_status                   AS marital_status,
    -- Conflict resolution: Use CRM gender unless it's unknown, then fallback to ERP
    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END                                     AS gender,
    ca.bdate                                AS birthdate,
    ci.cst_create_date                      AS create_date
FROM 
    silver.crm_cust_info ci
LEFT JOIN 
    silver.erp_cust_az12 ca
ON  ci.cst_key = ca.cid
LEFT JOIN 
    silver.erp_loc_a101 cl 
ON  ci.cst_key = cl.cid;