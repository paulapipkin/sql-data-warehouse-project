/*
=========================================
Stored procedure: Load Silver Tables ( Bronze --> Silver)
==========================================

This procedure performs ETL(Extract, transform and load) process to poplulate silver tables from bronze schema.

It will truncate existent table and  insert current data from bronze tables

*/



CREATE OR ALTER PROCEDURE silver.load_silver AS

BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME

	BEGIN TRY

		SET @batch_start_time = GETDATE();

		PRINT '===============================================';
		PRINT 'LOADING SILVER LAYER'
		PRINT '===============================================';


		PRINT'Load CRM Tables';

		/* bulk load crm customer info from bronze */
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_cust_info;

		INSERT INTO silver.crm_cust_info (
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_material_status,
cst_gndr,
cst_create_date)

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,

CASE	WHEN UPPER(TRIM(cst_material_status)) = 'S'THEN 'Single'
		WHEN UPPER(TRIM(cst_material_status)) = 'M'THEN 'Married'
		ELSE 'N/A'
		END cst_material_status,

CASE	WHEN UPPER(TRIM(cst_gndr)) = 'F'THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M'THEN 'Male'
		ELSE 'N/A'
		END cst_gndr,
cst_create_date
FROM(
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
	) t WHERE flag_last = 1 ;-- select the most recent record per customer

		SET @end_time = GETDATE();
		PRINT 'silver.crm_cust_info table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		
		
		/* bulk load crm product info from bronze */
		SET @start_time = GETDATE();

		TRUNCATE TABLE silver.crm_prd_info;

		INSERT INTO silver.crm_prd_info(
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt)

SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE  UPPER(TRIM(prd_line)) 
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a'
END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info;

		SET @end_time = GETDATE();
		PRINT 'silver.crm_prd_info table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

		/* bulk load crm sales details from bronze */
		SET @start_time = GETDATE();

		TRUNCATE TABLE silver.crm_sales_details;

		INSERT INTO silver.crm_sales_details(
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

select
sls_ord_num,
sls_prd_key,
sls_cust_id,

CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,

CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,

CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,

CASE WHEN sls_sales IS NULL OR sls_sales<0 OR sls_sales != sls_quantity*ABS(sls_price) THEN ABS(sls_quantity*sls_price)
	ELSE sls_sales
END AS sls_sales,

sls_quantity,

CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales/NULLIF(sls_quantity,0)
	 ELSE sls_price
END AS sls_price

from bronze.crm_sales_details;

		SET @end_time = GETDATE();
		PRINT 'silver.crm_sales_details table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		
		PRINT'_______________________________________';
		PRINT'Load ERP Tables';


		/* bulk load erp customer data from bronze */
		SET @start_time=GETDATE();

		TRUNCATE TABLE silver.erp_cust_az12;

		INSERT INTO silver.erp_cust_az12(
cid,
bdate,
gen
)

SELECT
CASE WHEN cid LIKE 'NAS%' then substring(cid,4,len(cid))
	else cid
end cid,
CASE WHEN bdate > getdate() or bdate < '1916-01-01' then null -- eliminate dates in the future and or 110y/o people
	else bdate
END bdate,
CASE WHEN UPPER(TRIM(gen)) in ('F', 'FEMALE') then 'Female'
	WHEN UPPER(TRIM(gen)) in ('M', 'MALE') then 'Male'
	Else 'n/a'
end gen
from bronze.erp_cust_az12;

		PRINT 'silver.erp_cust_az12 table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

		/* bulk load erp location data from bronze */
		SET @start_time = GETDATE();

		TRUNCATE TABLE silver.erp_loc_a101;

		insert into silver.erp_loc_a101(
cid,
cntry
)

select  
trim(replace(cid,'-','')) ,
CASE 
	when trim(cntry)in ('US', 'USA') then 'United States'
	when trim(cntry)= 'DE' then 'Germany'
	when trim(cntry)= '' or trim(cntry) is null then 'n/a'
	
ELSE trim(cntry)
END cntry
from bronze.erp_loc_a101;

		SET @end_time = GETDATE();
		PRINT 'silver.erp_loc_a101 table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

		/* bulk load erp product catalog data from csv file */
		SET @start_time = GETDATE();

		TRUNCATE TABLE silver.erp_px_cat_g1v2;

insert into silver.erp_px_cat_g1v2(
id,
cat,
subcat,
maintenance
)

select id,
cat,
subcat,
maintenance from bronze.erp_px_cat_g1v2;

		SET @end_time = GETDATE();
		PRINT 'silver.erp_px_cat_g1v2 table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

		SET @batch_end_time = GETDATE();
		PRINT '===== BATCH LOAD DURATION: '+ CAST(DATEDIFF(SECOND,@batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds ==='
	END TRY

	BEGIN CATCH
		PRINT '================================================================'
		PRINT 'ERROR OCCURED -  Error Message ' + ERROR_MESSAGE();
		PRINT 'ERROR OCCURED -  Error Number ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT '================================================================'

	END CATCH

END
