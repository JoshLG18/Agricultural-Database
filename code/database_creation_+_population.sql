-- Create Database
DROP DATABASE IF EXISTS Agriculture; -- drop the database if it exists - avoids any erros when altering tables
CREATE DATABASE Agriculture; -- creating a database called agriculture
USE Agriculture; -- sets up the rest of the file to use that database

SET GLOBAL local_infile = 1; -- allows the local file to be loaded into the database

-- Core Tables

-- Farm Table
CREATE TABLE Farm ( -- creates a table called farm
    farmID INT NOT NULL PRIMARY KEY, -- creates a column called farmID that can't be empty and is the primary key
    farm_Location VARCHAR(255) -- creates the farm location column which is a varchar of max length 255
);

-- Crops Table
CREATE TABLE Crop ( -- creates a crops table
    cropID INT NOT NULL PRIMARY KEY, -- creates a column called cropID that can't be empty and is the primary key
    crop_name VARCHAR(255) -- adds a column for the crop_name
);

-- Soil Table
CREATE TABLE Soil ( -- creates a table for soils data
    soilID INT NOT NULL PRIMARY KEY, -- creates a column called soilID that can't be empty and is the primary key
    farmID INT NOT NULL, -- adds a column called farmID which can't be null
    ph_level DECIMAL(3,1), -- creates a column for ph level
    nitrogen_level INT, -- creates a column for nitrogen level
    phosphorus_level INT, -- creates a column for phosphorus level
    potassium_level INT, -- creates a column for potassium level
    FOREIGN KEY (farmID) REFERENCES Farm(farmID) -- sets the farmID as a FK from the farm table as 1 farm has one soil type
);

-- Resources table
CREATE TABLE Resource ( -- create a table for the resources
    resourceID INT NOT NULL PRIMARY KEY, -- creates a column called resourceID that can't be empty and is the primary key
    resource_type VARCHAR(255) -- creates the resource type column which is a varchar of max length 255
);

-- Initiatives
CREATE TABLE Initiative ( -- creates a table to store initiative details
    initiativeID INT NOT NULL PRIMARY KEY, -- creates a column called initiativeID that can't be empty and is the primary key
    initiative_description VARCHAR(255) -- adds a column for the description
);

-- Staging Table for Raw CSV
CREATE TABLE Staging ( -- Create a temporary table to allow the data to be read it and split into its other tables easily
    farmID INT,
    farm_location VARCHAR(255),
    cropID INT,
    crop_name VARCHAR(255),
    planting_date VARCHAR(50),
    harvest_date VARCHAR(50),
    soilID INT,
    ph_level DECIMAL(3,1),
    nitrogen_level INT,
    phosphorus_level INT,
    potassium_level INT,
    resourceID INT,
    resource_type VARCHAR(255),
    resource_quantity DECIMAL(10,2),
    date_of_application VARCHAR(50),
    initiativeID INT,
    initiative_description VARCHAR(255),
    date_initiated VARCHAR(50),
    expected_impact VARCHAR(255),
    crop_yield INT,
    ev_score INT,
    water_source VARCHAR(255),
    labour_hours INT
);

-- Load Data into Staging Table
LOAD DATA LOCAL INFILE '/Users/joshlegrice/Desktop/University/Masters/Data Systems/Coursework/data/COMM108_Data_Coursework.csv'
INTO TABLE Staging -- load the data from the above location into the temporary table
FIELDS TERMINATED BY ',' -- defines the delimeter to seperate the columns by
OPTIONALLY ENCLOSED BY '"' -- ensures dates with slashes are read as strings not math
LINES TERMINATED BY '\n' -- defines where to start a new row in the file
IGNORE 1 ROWS; -- ignores the header rows of the .csv 

-- Clean Dates -- changing the dates into the correct formats from strings
UPDATE Staging
SET 
    -- convert strings to date format
    planting_date = STR_TO_DATE(TRIM(planting_date), '%d/%m/%Y'),
    harvest_date = STR_TO_DATE(TRIM(harvest_date), '%d/%m/%Y'),
    date_of_application = STR_TO_DATE(TRIM(date_of_application), '%d/%m/%Y'),
    date_initiated = STR_TO_DATE(TRIM(date_initiated), '%d/%m/%Y');


-- Insert into Core Tables

--  Farms
INSERT INTO Farm (farmID, farm_Location) -- insert data into the farm table in farmID and farm_Location
SELECT DISTINCT farmID, farm_location -- select the unique `farmID` and `farm_Location` from staging
FROM Staging
WHERE farmID IS NOT NULL; -- make sure farmID has a value

-- Crops
INSERT INTO Crop (cropID, crop_name)  -- insert these fields into the crop table
SELECT DISTINCT cropID, crop_name -- select unique values from those fields in staging
FROM Staging
WHERE cropID IS NOT NULL; -- make sure cropID has a value

-- Soils
INSERT INTO Soil (soilID, farmID, ph_level, nitrogen_level, phosphorus_level, potassium_level) -- insert these fields into the soil table
SELECT DISTINCT soilID, farmID, ph_level, nitrogen_level, phosphorus_level, potassium_level -- select unique values from those fields in staging
FROM Staging
WHERE soilID IS NOT NULL; -- make sure soilID has a value

-- Resources
INSERT INTO Resource (resourceID, resource_type) -- insert both ID and type into the resources table
SELECT DISTINCT resourceID, resource_type -- trim and lowercase to remove inconsistencies
FROM Staging
WHERE resource_type IS NOT NULL AND resourceID IS NOT NULL; -- make sure resource type has a value

-- Initiatives
INSERT INTO Initiative (initiativeID, initiative_description) -- insert these fields into the initiatives table
SELECT DISTINCT initiativeID, initiative_description -- select unique values from those fields in staging
FROM Staging
WHERE initiativeID IS NOT NULL; -- make sure initiativeID has a value

-- Junction Tables

-- Farm-Crop
-- needed to store the harvest and planting date of a crop which has to occur on a farm
CREATE TABLE Farm_Crop (
    farmID INT NOT NULL,
    cropID INT NOT NULL,
    planting_date DATE,
    harvest_date DATE,
    PRIMARY KEY (farmID, cropID), -- composite primary key as 1 farm can have multiple crops and vice versa
    FOREIGN KEY (farmID) REFERENCES Farm(farmID),
    FOREIGN KEY (cropID) REFERENCES Crop(cropID)
);

-- insert the data from the staging table
INSERT INTO Farm_Crop (farmID, cropID, planting_date, harvest_date)
SELECT DISTINCT farmID, cropID, planting_date, harvest_date
FROM Staging
WHERE farmID IS NOT NULL AND cropID IS NOT NULL;

-- Crop-Resource 
-- needed as 1 crop can have more than one resource used on it
-- also a single resource type can be applied to more than one type of crop - would be a m-m without this table
CREATE TABLE Crop_Resource (
    cropID INT NOT NULL, 
    resourceID INT NOT NULL,
    resource_quantity DECIMAL(10,2),
    date_of_application DATE NOT NULL, 
    PRIMARY KEY (cropID, resourceID, date_of_application),
    FOREIGN KEY (cropID) REFERENCES Crop(cropID),
    FOREIGN KEY (resourceID) REFERENCES Resource(resourceID)
);

-- insert the data from the staging and resources tables
INSERT INTO Crop_Resource (cropID, resourceID, resource_quantity, date_of_application)
SELECT DISTINCT s.cropID, s.resourceID, s.resource_quantity, s.date_of_application
FROM Staging s
WHERE s.resourceID IS NOT NULL AND s.cropID IS NOT NULL AND s.date_of_application IS NOT NULL;

-- Crop-Initiative 

-- needed as multiple crops use one initiative 
-- allows in future for multiple crops to be grown under one initiative
CREATE TABLE Crop_Initiative ( 
    cropID INT NOT NULL,
    initiativeID INT NOT NULL,
    crop_yield INT,
    PRIMARY KEY (cropID, initiativeID),
    FOREIGN KEY (cropID) REFERENCES Crop(cropID),
    FOREIGN KEY (initiativeID) REFERENCES Initiative(initiativeID)
);

-- insert the data from the staging and initiatives tables
INSERT INTO Crop_Initiative (cropID, initiativeID, crop_yield)
SELECT DISTINCT s.cropID, s.initiativeID, s.crop_yield
FROM Staging s
WHERE s.cropID IS NOT NULL AND s.initiativeID IS NOT NULL;


-- Farm-Initiative
-- needed as multiple farms can have multiple initiatives
-- allows in future for multiple farms to have one initiative
CREATE TABLE Farm_Initiative (
    initiativeID INT NOT NULL,
    farmID INT NOT NULL,
    date_initiated DATE,
    expected_impact VARCHAR(255),
    ev_score INT,
    water_source VARCHAR(255),
    PRIMARY KEY (initiativeID, farmID),
    FOREIGN KEY (initiativeID) REFERENCES Initiative(initiativeID),
    FOREIGN KEY (farmID) REFERENCES Farm(farmID)
);

-- insert the data from the staging and initiatives tables
INSERT INTO Farm_Initiative (initiativeID, farmID, date_initiated, expected_impact, ev_score, water_source)
SELECT DISTINCT -- Use DISTINCT to ensure only one setup record is created per farm/initiative
    s.initiativeID,
    s.farmID,
    s.date_initiated,
    s.expected_impact,
    s.ev_score,
    s.water_source
FROM Staging s
WHERE s.initiativeID IS NOT NULL 
  AND s.farmID IS NOT NULL;

-- Labour Table - to track labour hours associated with each farm, initiative, crop, and resource combination
CREATE TABLE Labour (
    farmID INT NOT NULL,
    initiativeID INT NOT NULL,
    cropID INT NOT NULL,
    resourceID INT NOT NULL, 
    labour_hours INT,
    
    PRIMARY KEY (farmID, initiativeID, cropID, resourceID),
    
    FOREIGN KEY (farmID) REFERENCES Farm(farmID),
    FOREIGN KEY (initiativeID) REFERENCES Initiative(initiativeID),
    FOREIGN KEY (cropID) REFERENCES Crop(cropID),
    FOREIGN KEY (resourceID) REFERENCES Resource(resourceID)
);

-- insert the data from the staging table
INSERT INTO Labour (farmID, initiativeID, cropID, resourceID, labour_hours)
SELECT DISTINCT 
    s.farmID,
    s.initiativeID,
    s.cropID,
    s.resourceID,
    s.labour_hours
FROM Staging s
WHERE s.labour_hours IS NOT NULL 
  AND s.farmID IS NOT NULL 
  AND s.initiativeID IS NOT NULL
  AND s.cropID IS NOT NULL
  AND s.resourceID IS NOT NULL;

-- drop the staging table
DROP TABLE Staging; -- drops the staging table as it is not needed anymore, avoid redundancy