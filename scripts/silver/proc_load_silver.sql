
/* 
===================================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===================================================================================================
Script Purpose :
      This stored procedure performs the ETL (Extract, Transfrom Load ) process to
      populate  the 'silver' schema tables form the 'bronze' schema.
  Actions Performed:
        - Truncates Silver tables.
        - Inserts transformed and cleansed data from Bronze into silver tables.


Parameters:
      None.
      This  stored procedure does not accept any parameters or return amy values.


Usage Examples:
      EXEC Silver.load_silver;
==================================================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
			PRINT ' ================================================';
			PRINT 'Loading silver Layer';
			PRINT '=================================================';

			PRINT ' ------------------------------------------------';
			PRINT 'Loading CRM Tables';
			PRINT '-------------------------------------------------';

			--Loading silver.crm_cust_info
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table : silver.crm_cust_info';
			TRUNCATE TABLE silver.crm_cust_info;
			PRINT '>> Inserting Data Into : silver.crm_cust_info';

			INSERT INTO silver.crm_cust_info(
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_marital_status,
				cst_gender,
				cst_create_date
			)
			select 
				cst_id,
				cst_key,
				TRIM(cst_firstname) as FirstName,
				TRIM(cst_lastname) as LastName,
				CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' Then 'Single'
					WHEN UPPER(TRIM(cst_marital_status)) = 'M' Then 'Married'
					ELSE 'N/A'
				END cst_marital_status, -- Normalize marital status valures to readable fromat 

				CASE WHEN UPPER(TRIM(cst_gender)) = 'F' Then 'Female'
					WHEN UPPER(TRIM(cst_gender)) = 'M' Then 'Male'
					ELSE 'N/A'
				END CST_gender, -- Normalize gender values to readable format
				cst_create_date
			from (

				Select 
					*,
					row_number () over (partition by cst_id order by cst_create_date desc) as flag_last
					FROM bronze.crm_cust_info
					where cst_id is not null

			)t 
			where flag_last =1 ;  -- Select the most recent record per customer
			SET @end_time = GETDATE();
			PRINT '>> Load Duration:' + CAST(DATEDIFF(SECOND, @start_time, @end_time ) as NVARCHAR) + 'seconds';
			PRINT '>> -----------------------';

		--Loading silver.crm_prd_info;
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table : silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into : silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
			prd_id,
			prd_key,
			cat_id,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		Select 
			prd_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,           -- Extract product key
			REPLACE(SUBSTRING(prd_key, 1, 5 ), '-','_')  as  cat_id,  -- Extract category ID
			prd_nm,
			ISNULL(prd_cost, 0) as prd_cost,
			CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
				 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
				 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
				 WHEN UPPER(TRIM(prd_line)) = 'T'THEN  'Touring'
				 ELSE 'N/A'
			END AS prd_line,   --- Map product line codes to descriptive values

			CAST(prd_start_dt AS DATE)  as prd_start_dt,
			CAST(
				LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 
				AS DATE) as prd_end_dt -- Calculate end date as one day before the next start date
		From bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(SECOND, @start_time, @end_time ) as NVARCHAR) + 'seconds';
		PRINT '>> -----------------------';


		--Loading crm_sales_details;
		SET @start_time  = GETDATE();
		PRINT '>> Truncating Table : silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into : silver.crm_sales_details';
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
		Select
				sls_ord_num,
				sls_prd_key ,
				sls_cust_ID ,
				CASE 
					WHEN sls_order_dt = 0 or LEN(sls_order_dt) != 8 THEN NULL
					 ELSE CAST(CAST(sls_order_dt as varchar) as DATE )
				END AS sls_order_dt,
				CASE 
					WHEN sls_ship_dt = 0 or LEN(sls_ship_dt) != 8 THEN NULL
					 ELSE CAST(CAST(sls_ship_dt as varchar) as DATE )
				END AS sls_ship_dt,
				CASE 
					WHEN sls_due_dt = 0 or LEN(sls_due_dt) != 8 THEN NULL
					ELSE CAST(CAST(sls_due_dt as varchar) as DATE )
				END AS sls_due_dt,
				CASE 
					WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
						THEN sls_quantity * ABS (sls_price)
					ELSE sls_sales
				END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
				sls_quantity ,
				CASE 
					WHEN SLS_PRICE IS NULL OR sls_price <=0 
						THEN sls_sales / NULLIF(sls_quantity, 0) 
					ELSE sls_price  -- Derive price if original value is invalid
				END AS sls_price
		From bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(SECOND, @start_time, @end_time ) as NVARCHAR) + 'seconds';
		PRINT '>> -----------------------';


		--Loading silver erp_cust_az12
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table : silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data Into : silver.erp_cust_az12';
		INSERT INTO Silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		Select 
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4 , LEN(cid)) -- Remove 'NAS' prefix if present
				 ELSE cid
			END as cid,
			CASE WHEN bdate > GETDATE() THEN NULL
				else bdate
			end as bdate, -- Set furture birthdates is null
			Case when upper(trim(gen)) in ('F', 'Female') Then 'Female'
				When upper(trim(gen)) in ('M', 'Male') Then 'Male'
				Else 'n/a'
			End as gen  -- Normalize gender values and handles unknown cases
		from bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(SECOND, @start_time, @end_time ) as NVARCHAR) + 'seconds';
		PRINT '>> -----------------------';


		-- Loading silver.erp_loc_a101
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table : silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into : silver.erp_loc_a101';
		INSERT INTO Silver.erp_loc_a101(
			cid, 
			cntry
		)
		Select 
			REPLACE (cid, '-', '') cid, 
			CASE WHEN TRIM(cntry) = 'DE' Then 'Germany'
				When TRIM(cntry) in ('US' , 'USA') Then 'United States'
				When TRIM(cntry) = '' OR cntry is NULL Then 'n/a'
				Else TRIM(cntry)
			End as cntry  -- Normalize and Handle missing or blank country codes
		from bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(SECOND, @start_time, @end_time ) as NVARCHAR) + 'seconds';
		PRINT '>> -----------------------';

		--Loading silver.erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table : silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into : silver.erp_px_cat_g1v2';
		INSERT INTO Silver.erp_px_cat_g1v2(
			id, 
			cat,
			subcat,
			maintenance
		)
		Select 
			id,
			cat,
			subcat,
			maintenance 
		From bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(SECOND, @start_time, @end_time ) as NVARCHAR) + 'seconds';
		PRINT '>> -----------------------';


		SET @batch_end_time = GETDATE();
		PRINT '================================================';
		PRINT 'Loading Silver Layer is Completed';
		PRINT '    - Total Load Duration : ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) as NVARCHAR) + 'seconds';
		PRINT '================================================';
	
	END TRY
	BEGIN CATCH
		PRINT '======================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message'+ CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message'+ CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '======================================';
	END CATCH

END
