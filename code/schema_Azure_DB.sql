-- Script to create the Azure SQL Database schema for the agricultural data system
-- drop existing tables if they exist to avoid errors during creation
IF OBJECT_ID('dbo.Crop_Resource', 'U') IS NOT NULL DROP TABLE dbo.Crop_Resource;
IF OBJECT_ID('dbo.Farm_Crop', 'U') IS NOT NULL DROP TABLE dbo.Farm_Crop;
IF OBJECT_ID('dbo.Crop_Initiative', 'U') IS NOT NULL DROP TABLE dbo.Crop_Initiative;
IF OBJECT_ID('dbo.Labour_Log', 'U') IS NOT NULL DROP TABLE dbo.Labour_Log;
IF OBJECT_ID('dbo.Farm_Initiative', 'U') IS NOT NULL DROP TABLE dbo.Farm_Initiative;
IF OBJECT_ID('dbo.Soil', 'U') IS NOT NULL DROP TABLE dbo.Soil;
IF OBJECT_ID('dbo.Resource', 'U') IS NOT NULL DROP TABLE dbo.Resource;
IF OBJECT_ID('dbo.Initiative', 'U') IS NOT NULL DROP TABLE dbo.Initiative;
IF OBJECT_ID('dbo.Crop', 'U') IS NOT NULL DROP TABLE dbo.Crop;
IF OBJECT_ID('dbo.Farm', 'U') IS NOT NULL DROP TABLE dbo.Farm;
GO


-- Farm Table
CREATE TABLE dbo.Farm ( -- creates a table called farm
    farmID INT NOT NULL PRIMARY KEY, -- creates a column called farmID that can't be empty and is the primary key
    farm_location VARCHAR(255) -- creates the farm location column which is a varchar of max length 255
);
GO

-- Crop Table
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
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID) -- sets the farmID as a FK from the farm table as 1 farm has one soil type
);
GO

-- Resource Table
CREATE TABLE dbo.Resource ( -- create a table for the resources
    resourceID INT NOT NULL PRIMARY KEY, -- creates a column called resourceID that can't be empty and is the primary key
    resource_type VARCHAR(255) -- creates the resource type column which is a varchar of max length 255
);
GO

-- Initiative Table
CREATE TABLE dbo.Initiative ( -- creates a table to store initiative details
    initiativeID INT NOT NULL PRIMARY KEY, -- creates a column called initiativeID that can't be empty and is the primary key
    initiative_description VARCHAR(255) -- adds a column for the description
);
GO

-- Junction Tables

-- Farm-Crop
CREATE TABLE dbo.Farm_Crop ( -- needed to store the harvest and planting date of a crop which has to occur on a farm
    farmID INT NOT NULL,
    cropID INT NOT NULL,
    planting_date DATE,
    harvest_date DATE,
    PRIMARY KEY (farmID, cropID),
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID),
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID)
);
GO

-- Crop-Resource
CREATE TABLE dbo.Crop_Resource ( -- needed as 1 crop can have more than one resource used on it
    cropID INT NOT NULL,
    resourceID INT NOT NULL,
    resource_quantity DECIMAL(10,2),
    date_of_application DATE,
    PRIMARY KEY (cropID, resourceID, date_of_application),
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID),
    FOREIGN KEY (resourceID) REFERENCES dbo.Resource(resourceID)
);
GO

-- Crop-Initiative
CREATE TABLE dbo.Crop_Initiative ( -- needed as multiple crops use one initiative
    cropID INT NOT NULL,
    initiativeID INT NOT NULL,
    crop_yield INT,
    PRIMARY KEY (cropID, initiativeID),
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID),
    FOREIGN KEY (initiativeID) REFERENCES dbo.Initiative(initiativeID)
);
GO

-- Farm-Initiative
CREATE TABLE dbo.Farm_Initiative ( -- stores the non-redundant details of the initiative setup on a farm
    initiativeID INT NOT NULL,
    farmID INT NOT NULL,
    date_initiated DATE,
    expected_impact VARCHAR(255),
    ev_score INT,
    water_source VARCHAR(255),
    PRIMARY KEY (initiativeID, farmID), -- PK is based only on the two FKs to avoid 2NF violation
    FOREIGN KEY (initiativeID) REFERENCES dbo.Initiative(initiativeID),
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID)
);
GO

-- Labour
CREATE TABLE dbo.Labour ( 
    farmID INT NOT NULL,
    initiativeID INT NOT NULL,
    cropID INT NOT NULL,
    resourceID INT NOT NULL,  
    labour_hours INT,
    
    PRIMARY KEY (farmID, initiativeID, cropID, resourceID),
    
    FOREIGN KEY (farmID) REFERENCES dbo.Farm(farmID),
    FOREIGN KEY (initiativeID) REFERENCES dbo.Initiative(initiativeID),
    FOREIGN KEY (cropID) REFERENCES dbo.Crop(cropID),
    FOREIGN KEY (resourceID) REFERENCES dbo.Resource(resourceID) 
    );
GO