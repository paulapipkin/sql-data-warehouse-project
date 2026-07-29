/*
===========================================
Stored Procesure: load Bronze Layer (Source - > Bronze)
============================================
Script purpose:
	This stored procedure loads data into the bronze schema from external CSV files.
	It performes the following actions:
	- Truncates the bronze tables before loading data
	- Uses the 'BULK INSERT' command to load daat from csv files to bronze tables.
Parameters: None
	This procedure does not accept any parameters or return any values

Usage Example:
	EXEC bronze.load_bronze;

======================================================
*/



CREATE OR ALTER PROCEDURE bronze.load_bronze AS 

BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME

	BEGIN TRY

		SET @batch_start_time = GETDATE();

		PRINT '===============================================';
		PRINT 'LOADING BRONZE LAYER'
		PRINT '===============================================';


		PRINT'Load CRM Tables';

		/* bulk load crm customer info from csv file */
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info;

		BULK INSERT bronze.crm_cust_info
		FROM 
		'C:\Users\paula\OneDrive\Área de Trabalho\SQL Udemy\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'bronze.crm_cust_info table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		
		
		/* bulk load crm product info from csv file */
		SET @start_time = GETDATE();

		TRUNCATE TABLE bronze.crm_prd_info;

		BULK INSERT bronze.crm_prd_info
		FROM 
		'C:\Users\paula\OneDrive\Área de Trabalho\SQL Udemy\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'bronze.crm_prd_info table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

		/* bulk load crm sales details from csv file */
		SET @start_time = GETDATE();

		TRUNCATE TABLE bronze.crm_sales_details;

		BULK INSERT bronze.crm_sales_details
		FROM 
		'C:\Users\paula\OneDrive\Área de Trabalho\SQL Udemy\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'bronze.crm_sales_details table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		
		PRINT'_______________________________________';
		PRINT'Load ERP Tables';


		/* bulk load erp customer data from csv file */
		SET @start_time=GETDATE();

		TRUNCATE TABLE bronze.erp_cust_az12;

		BULK INSERT bronze.erp_cust_az12
		FROM 
		'C:\Users\paula\OneDrive\Área de Trabalho\SQL Udemy\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'bronze.erp_cust_az12 table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

		/* bulk load erp location data from csv file */
		SET @start_time = GETDATE();

		TRUNCATE TABLE bronze.erp_loc_a101;

		BULK INSERT bronze.erp_loc_a101
		FROM 
		'C:\Users\paula\OneDrive\Área de Trabalho\SQL Udemy\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'bronze.erp_loc_a101 table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

		/* bulk load erp product catalog data from csv file */
		SET @start_time = GETDATE();

		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 
		'C:\Users\paula\OneDrive\Área de Trabalho\SQL Udemy\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'bronze.erp_px_cat_g1v2 table loaded - Loading Duration: '+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		

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
