

/*
==================================================================================
Stroed Procedure : Load Bronze Layer ( Source -> Bronze ) 
==================================================================================

Script Purpose : 
          This storde procedure loads data into the  'bronze' schema from external CSV files.
          It performs the following actions:
          - Truncates the bronze tables before loading data.
          - Uses the  ' BULK INSERT ' command to load data frokm csv files to bronze tables.


Parameters:
  None.
This stored procedure does not accept any paramenters or ruturn any values.


Usage Example:
  EXEC bronze.load_bronze;
====================================================================================
*/



CREATE OR ALTER PROCEDURE bronze.load_bronze As 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME;
	BEGIN TRY
		PRINT '===================================';
		PRINT ' Loading Bronze Layer ';
		PRINT '===================================';

		PRINT '--------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncting Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> INSERTING Data Into: bronze.crm_cust_info';
		BULK INSERT  bronze.crm_cust_info
		FROM 'C:\Users\Aryan Kumar\OneDrive\Desktop\DataWarehouse\dataset\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST( DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'second';
		PRINT '>> ---------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncting Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> INSERTING Data Into: bronze.crm_prd_info';
		BULK INSERT  bronze.crm_prd_info
		FROM 'C:\Users\Aryan Kumar\OneDrive\Desktop\DataWarehouse\dataset\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST( DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'second';
		PRINT '>> ---------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncting Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> INSERTING Data Into: bronze.crm_sales_details';
		BULK INSERT  bronze.crm_sales_details
		FROM 'C:\Users\Aryan Kumar\OneDrive\Desktop\DataWarehouse\dataset\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST( DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'second';
		PRINT '>> ---------------------';


		PRINT '--------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncting Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> INSERTING Data Into: bronze.erp_cust_az12';
		BULK INSERT  bronze.erp_cust_az12
		FROM 'C:\Users\Aryan Kumar\OneDrive\Desktop\DataWarehouse\dataset\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST( DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'second';
		PRINT '>> ---------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncting Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> INSERTING Data Into: bronze.erp_loc_a101';
		BULK INSERT  bronze.erp_loc_a101
		FROM 'C:\Users\Aryan Kumar\OneDrive\Desktop\DataWarehouse\dataset\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST( DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'second';
		PRINT '>> ---------------------';


		SET @start_time = GETDATE();
		PRINT '>> Truncting Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> INSERTING Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT  bronze.erp_px_cat_g1v2
		FROM 'C:\Users\Aryan Kumar\OneDrive\Desktop\DataWarehouse\dataset\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST( DATEDIFF(second, @start_time, @end_time) as NVARCHAR(40)) + 'second';
		PRINT '>> ---------------------';

	END TRY 
	BEGIN CATCH
	PRINT '=======================';
	PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
	PRINT 'Error Message' + ERROR_MESSAGE();
	PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
	PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
	PRINT ' ======================';
	END CATCH
END
