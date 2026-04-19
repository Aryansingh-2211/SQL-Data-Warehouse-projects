
/* 
==================================================================================================
DDL Script: Dreate Gold Views
==================================================================================================
Script Purpose:
        Thsi script creates view for the Gold layer in the data warehouse.
        The Gold layer represents the final dimension and fact tables (Star Schema)
        
        Each view performs transformations and combines data from the Silver layer 
        to produce a clean, enriched, and business-ready dataset.

Usage:
     - These views can ve queried directly for anlytics adn reporting
==================================================================================================

*/


-- ===============================================================================================
-- Create Dimension: gold.dim_customers
-- ===============================================================================================
IF OBJECT_ID (' gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW  gold.dim_customers;

GO

CREATE VIEW gold.dim_customers as
Select
	ROW_NUMBER() OVER(ORDER BY c.cst_id desc) as customer_key,
	c.cst_id As customer_id,
	c.cst_key As customer_number,
	c.cst_firstname As first_name,
	c.cst_lastname As last_name,
	la.cntry As country,
	c.cst_marital_status As marital_status,
	CASE WHEN c.cst_gender != 'n/a' THEN c.cst_gender --CRM is the Master for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END as gender,
	ca.bdate As birthdate,
	c.cst_create_date As create_date
from silver.crm_cust_info c
LEFT JOIN silver.erp_cust_az12 ca
On  c.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
On  c.cst_key = la.cid


-- ===============================================================================================
-- Create Dimension: gold.dim_products
-- ===============================================================================================


IF OBJECT_ID ('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;

GO

CREATE VIEW gold.dim_products as
Select 
	ROW_NUMBER () OVER(ORDER BY pr.prd_start_dt, pr.prd_key) as product_key,
	pr.prd_id AS product_id,
	pr.prd_key As product_number,
	pr.prd_nm AS product_name,
	pr.cat_id As category_id,
	pc.cat As category,
	pc.subcat As subcategory,
	pc.maintenance ,
	pr.prd_cost As product_cost,
	pr.prd_line As product_line,
	pr.prd_start_dt As product_start_date
from silver.crm_prd_info pr
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pr.cat_id = pc.id
WHERE prd_end_dt is null -- Filter out all historical data


-- ===============================================================================================
-- Create Dimension: gold.fact_sales
-- ===============================================================================================

	
IF OBJECT_ID ('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;

GO

CREATE VIEW gold.fact_sales as 
Select 
 sd.sls_ord_num As order_number,
 pr.product_key ,
 ca.customer_key,
 sd.sls_order_dt As order_date,
 sd.sls_ship_dt As shipping_date,
 sd.sls_due_dt As due_date,
 sd.sls_sales As sales_amount,
 sd.sls_quantity As quantity,
 sd.sls_price as price
from silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
On sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers ca
On sd.sls_cust_ID = ca.customer_id
