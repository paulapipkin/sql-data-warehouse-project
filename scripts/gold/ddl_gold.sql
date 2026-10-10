/*_________________________________________________
GOLD LAYER VIEWS - DDL SCRIPT
_____________________________________________________
*/
-- *****************************
-- CUSTOMER  - DIMENSION TABLE
-- ****************************

CREATE VIEW gold.dim_customer AS
select 
ROW_NUMBER() Over (Order by cst_id) AS customer_key,
ci.cst_id as customer_id,
ci.cst_key as customer_number,
ci.cst_firstname as first_name,
ci.cst_lastname as last_name,
la.cntry as country,
ci.cst_material_status as marital_status,
Case when ci.cst_gndr = 'n/a' then Coalesce(ca.gen,'n/a')
else ci.cst_gndr end as gender,
ca.bdate as birthdate,
ci.cst_create_date as create_date


from silver.crm_cust_info ci

Left Join silver.erp_cust_az12 ca
on ci.cst_key = ca.cid

left join silver.erp_loc_a101 la
on ci.cst_key = la.cid

-- *****************************
-- PRODUCT VIEW - DIMENSION TABLE
-- ****************************

CREATE VIEW gold.dim_products AS

SELECT 

ROW_NUMBER() OVER (ORDER BY crm.prd_start_dt, crm.prd_key) AS product_key,
crm.prd_id as product_id,
crm.prd_key as product_number,
crm.prd_nm as product_name,
crm.cat_id as category_id,
erp.cat as category,
erp.subcat as subcategory,
erp.maintenance, 
crm.prd_cost as cost,
crm.prd_line as product_line,
crm.prd_start_dt as start_date


FROM silver.crm_prd_info  crm
LEFT JOIN silver.erp_px_cat_g1v2  erp on crm.cat_id = erp.id
WHERE crm.prd_end_dt is null --filter out historical data, keeps only current


-- *****************************
-- SALES DETAILS VIEW - FACT TABLE
-- ****************************

Create VIew gold.facts_sales AS

SELECT
sls_ord_num as order_number,
pr.product_key ,
ct.customer_key ,
sls_order_dt as order_date,
sls_ship_dt as shipping_date,
sls_due_dt as due_date,
sls_sales as sales_amount,
sls_quantity as quantity,
sls_price as price

FROM SILVER.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customer ct
ON sd.sls_cust_id = ct.customer_id
