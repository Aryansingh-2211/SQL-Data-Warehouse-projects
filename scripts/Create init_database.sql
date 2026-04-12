

/* 
--------------------------------------
Create Database and Schemas

--------------------------------------

Script Purpose:
			This script creates a new database named 'Datawarehouse' After checking if it already exists.
			If the database exists, it is dropped and recreated. Addditionally, the script sets up three schemas 
			within the database: 'broze', 'silver' and 'gold'.

WARNING:
	Running this script will drop the entire 'Datawarehouse' database if it exists.
	All data in the database will be permanently deleted. Proceed with caution 
	and ensuere you have proper backups before running this script.

*/


use master ;

Go 

-- Drop and recreate the 'Datawarehouse' database
IF EXISTS ( SELECT 1 FROM sys.databases WHERE  name = 'Datawarehouse')
BEGIN 
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DateWarehouse;
END;

GO

-- CREATE the 'DataWarehouse ' database
CREATE DATABASE DateWarehouse;
GO 

USE DataWarehouse;
GO

-- Create Schemas  
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;

