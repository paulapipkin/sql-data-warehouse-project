/*
=============================================
Create Database and Schemas
=============================================
Script purpose
This script creates a new database named DataWarehouseProject sfter checkinf if it already exists.
**If it exists, it will force users to disconnect, rollback any work/changes and proceed to delete it**, Including its tables and data if any. 
Then it will recreate it and proceed to create its 3 schemas.
*/




Use Master;
-- drop and recreate if exists:
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseProject')
BEGIN
  ALTER DATABASE DataWarehouseProject SET SINGLE_USER wITH ROLLBACK IMMEDIATE;
  DROP DATABASE DataWarehouseProject;
END;
GO

--Create the DataBase
CREATE DATABASE DataWarehouseProject;
GO

--Create schemas
USE DataWarehouseProject;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
