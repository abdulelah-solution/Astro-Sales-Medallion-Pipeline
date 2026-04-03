/*
===============================================================================
Dimension Strategy: Gold Layer - Products
===============================================================================
Script Purpose:
    This script creates the 'gold.dim_products' view, forming the Product 
    Dimension of the Data Warehouse. It integrates core product data from 
    the CRM system with category hierarchies from the ERP system.

Integration Logic:
    1. Primary Source: 'silver.crm_prd_info' (Core Product Attributes).
    2. Enrichment: Joins 'silver.erp_px_cat_g1v2' to provide Category, 
       Subcategory, and Maintenance info.
    3. SCD Filter: Filters for active records (prd_end_dt IS NULL) to ensure 
       only current product versions are presented.
    4. Surrogate Key: Assigns a 'product_key' for optimized Star Schema joins.

Note:
    This view enables cross-functional reporting by mapping CRM product keys 
    to ERP category structures.
===============================================================================
*/

CREATE OR ALTER VIEW gold.dim_products AS
SELECT
    -- Surrogate Key for dimensional modeling
    ROW_NUMBER() OVER(ORDER BY pi.prd_id)   AS product_key,
    pi.prd_id                               AS product_id,
    pi.prd_key                              AS product_number,
    pi.prd_nm                               AS product_name,
    pi.cat_id                               AS category_id,
    pa.cat                                  AS category,
    pa.subcat                               AS subcategory_id,
    pa.maintenance                          AS maintenance,
    pi.prd_cost                             AS product_cost,
    pi.prd_line                             AS product_line,
    pi.prd_start_dt                         AS start_dt
FROM 
    silver.crm_prd_info pi
LEFT JOIN
    silver.erp_px_cat_g1v2 pa
ON  pi.cat_id = pa.id
WHERE 
    pi.prd_end_dt IS NULL; -- Ensures only the latest/active version is loaded