-- Script to create the Azure SQL Database schema for the agricultural data system

-- drop existing tables if they exist to avoid errors during creation
IF OBJECT_ID('dbo.Labour', 'U') IS NOT NULL DROP TABLE dbo.Labour;
IF OBJECT_ID('dbo.Farm_Initiative', 'U') IS NOT NULL DROP TABLE dbo.Farm_Initiative;
IF OBJECT_ID('dbo.Crop_Initiative', 'U') IS NOT NULL DROP TABLE dbo.Crop_Initiative;
IF OBJECT_ID('dbo.Crop_Resource', 'U') IS NOT NULL DROP TABLE dbo.Crop_Resource;
IF OBJECT_ID('dbo.Farm_Crop', 'U') IS NOT NULL DROP TABLE dbo.Farm_Crop;
IF OBJECT_ID('dbo.Soil', 'U') IS NOT NULL DROP TABLE dbo.Soil;
IF OBJECT_ID('dbo.Initiative', 'U') IS NOT NULL DROP TABLE dbo.Initiative;
IF OBJECT_ID('dbo.Resource', 'U') IS NOT NULL DROP TABLE dbo.Resource;
IF OBJECT_ID('dbo.Crop', 'U') IS NOT NULL DROP TABLE dbo.Crop;
IF OBJECT_ID('dbo.Farm', 'U') IS NOT NULL DROP TABLE dbo.Farm;
GO

-- Core Tables

-- Farm Table
CREATE TABLE dbo.Farm ( -- creates a table called farm
    farmID INT NOT NULL PRIMARY KEY, -- creates a column called farmID that can't be empty and is the primary key
    farm_Location VARCHAR(255) -- creates the farm location column which is a varchar of max length 255
);
GO

-- Crops Table
CREATE TABLE dbo.Crop ( -- creates a crops table
    cropID INT NOT NULL PRIMARY KEY, -- creates a column called cropID that can't be empty and is the primary key
    crop_name VARCHAR(255) -- adds a column for the crop_name
);
GO

-- Soil Table
CREATE TABLE dbo.Soil ( -- creates a table for soils data
    soilID INT NOT NULL PRIMARY KEY, -- creates a column called soilID that can't be empty and is the primary key
    farmID INT NOT NULL, -- adds a column called farmID which can't be null
    ph_level DECIMAL(3,1), -- creates a column for ph level
    nitrogen_level INT, -- creates a column for nitrogen level
    phosphorus_level INT, -- creates a column for phosphorus level
    potassium_level INT, -- creates a column for potassium level
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID), -- sets the farmID as a FK from the farm table as 1 farm has one soil type
);
GO

-- Resources table
CREATE TABLE dbo.Resource ( -- create a table for the resources
    resourceID INT NOT NULL PRIMARY KEY, -- creates a column called resourceID that can't be empty and is the primary key
    resource_type VARCHAR(255) -- creates the resource type column which is a varchar of max length 255
);
GO

-- Initiatives
CREATE TABLE dbo.Initiative ( -- creates a table to store initiative details
    initiativeID INT NOT NULL PRIMARY KEY, -- creates a column called initiativeID that can't be empty and is the primary key
    initiative_description VARCHAR(255) -- adds a column for the description
);
GO

-- Junction Tables

-- Farm-Crop
CREATE TABLE dbo.Farm_Crop (
    farm_cropID INT NOT NULL IDENTITY PRIMARY KEY, -- surrogate key will auto increment
    farmID INT NOT NULL,
    cropID INT NOT NULL,
    planting_date DATE,
    harvest_date DATE,
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID),
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID)
);
GO

-- Crop-Resource 
CREATE TABLE dbo.Crop_Resource (
    crop_resourceID INT NOT NULL IDENTITY PRIMARY KEY, -- surrogate key will auto increment
    cropID INT NOT NULL, 
    resourceID INT NOT NULL,
    resource_quantity DECIMAL(10,2),
    date_of_application DATE,
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID),
    FOREIGN KEY (resourceID) REFERENCES dbo.Resource(resourceID)
);
GO

-- Crop-Initiative 
CREATE TABLE dbo.Crop_Initiative ( 
    crop_initiativeID INT NOT NULL IDENTITY PRIMARY KEY, -- surrogate key will auto increment
    cropID INT NOT NULL,
    initiativeID INT NOT NULL,
    crop_yield INT,
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID),
    FOREIGN KEY (initiativeID) REFERENCES dbo.Initiative(initiativeID)
);
GO

-- Farm-Initiative
CREATE TABLE dbo.Farm_Initiative (
    farm_initiativeID INT NOT NULL IDENTITY PRIMARY KEY, -- surrogate key will auto increment
    initiativeID INT NOT NULL,
    farmID INT NOT NULL,
    date_initiated DATE,
    expected_impact VARCHAR(255),
    ev_score INT,
    water_source VARCHAR(255),
    FOREIGN KEY (initiativeID) REFERENCES dbo.Initiative(initiativeID),
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID)
);
GO

-- Labour Table
CREATE TABLE dbo.Labour (
    labourID INT NOT NULL IDENTITY PRIMARY KEY, 
    farmID INT NOT NULL,
    initiativeID INT NOT NULL,
    cropID INT NOT NULL,
    resourceID INT NOT NULL, 
    labour_hours INT,    
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID),
    FOREIGN KEY (initiativeID) REFERENCES dbo.Initiative(initiativeID),
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID),
    FOREIGN KEY (resourceID) REFERENCES dbo.Resource(resourceID)
);
GO

-- References 
-- https://docs.azure.cn/en-us/azure-sql/database/design-first-database-tutorial?tabs=queryeditor
-- https://www.geeksforgeeks.org/sql/check-whether-a-table-exists-in-sql-server-database-or-not/
-- https://www.tutorialspoint.com/t_sql/t_sql_overview.htm
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql-identity-property?view=sql-server-ver17
-- https://www.atlassian.com/data/admin/how-to-define-an-auto-increment-primary-key-in-sql-server
