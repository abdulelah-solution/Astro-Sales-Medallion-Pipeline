/*
===============================================================================
Fact Table Strategy: Gold Layer - Sales
===============================================================================
Script Purpose:
    This script creates the 'gold.fact_sales' view, which acts as the central 
    Fact Table in the Data Warehouse. It stores transactional sales data 
    linked to cleaned Dimension tables.

Integration Logic:
    1. Primary Source: 'silver.crm_sales_details' (Validated Sales Records).
    2. Dimension Linking: Joins 'gold.dim_customers' and 'gold.dim_products' 
       to replace natural keys with surrogate keys.
    3. Metrics: Includes core business measures: sales amount, quantity, and price.
    4. Data Integrity: Uses LEFT JOIN to ensure all sales records are preserved 
       even if a matching dimension record is missing (though our cleaning 
       layer aims to minimize this).

Architecture:
    Star Schema - The 'fact_sales' table is the center of the star, optimized 
    for fast aggregation and BI tool consumption.
===============================================================================
*/

CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
    s.sls_ord_num       AS order_number,
    p.product_key,      -- Linking to the surrogate key in the Product Dimension
    c.customer_key,     -- Linking to the surrogate key in the Customer Dimension
    s.sls_order_dt      AS order_date,
    s.sls_ship_dt       AS shipping_date,
    s.sls_due_dt        AS due_date,
    s.sls_sales         AS sales_amount,
    s.sls_quantity      AS quantity,
    s.sls_price         AS price
FROM 
    silver.crm_sales_details s
LEFT JOIN 
    gold.dim_customers c
ON  s.sls_cust_id = c.customer_id
LEFT JOIN
    gold.dim_products p  
ON  s.sls_prd_key = p.product_number;