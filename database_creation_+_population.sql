# Create Database
DROP DATABASE IF EXISTS Agriculture;
CREATE DATABASE Agriculture; -- creating a database called agriculture
USE Agriculture; -- sets up the rest of the file to use that database

SET GLOBAL local_infile = 1; -- allows the local file to be loaded into the database

# Core Tables

# Farm Table
CREATE TABLE Farm ( -- creates a table called farm
    farmID INT NOT NULL PRIMARY KEY, -- creates a column called farmID that can't be empty and is the primary key
    farm_Location VARCHAR(255) -- creates the farm location column which is a varchar of max length 255
);

# Crops Table
CREATE TABLE Crops ( -- creates a crops table
    cropID INT NOT NULL PRIMARY KEY, -- creates a column called cropID that can't be empty and is the primary key
    farmID INT NOT NULL, -- adds a column called farmID which can't be null
    crop_name VARCHAR(255), -- adds a column for the crop_name
    planting_date DATE, -- adds a column for planting data
    harvest_date DATE, -- adds a column for harvest date
    FOREIGN KEY (farmID) REFERENCES Farm(farmID) -- sets the farmID as a FK from the farm table as 2 crops can be grown on one farm
);

# Soil Table
CREATE TABLE Soils ( -- creates a table for soils data
    soilID INT NOT NULL PRIMARY KEY, -- creates a column called soilID that can't be empty and is the primary key
    farmID INT NOT NULL, -- adds a column called farmID which can't be null
    ph_level DECIMAL(3,1), -- creates a column for ph level
    nitrogen_level INT, -- creates a column for nitrogen level
    phosphorus_level INT, -- creates a column for phosphorus level
    potassium_level INT, -- creates a column for potassium level
    FOREIGN KEY (farmID) REFERENCES Farm(farmID) -- sets the farmID as a FK from the farm table as 1 farm has one soil type
);

# Resources table
CREATE TABLE Resources ( -- create a table for the resources
    resourceID INT AUTO_INCREMENT PRIMARY KEY, -- creates a column called resourceID that can't be empty and is the primary key
    resource_type VARCHAR(255) -- creates the resource type column which is a varchar of max length 255
);

# Initiatives
CREATE TABLE Initiatives ( -- create an initiatives table to store sustainable initative details
    sustainabilityID INT, -- creates a column called soilID that can't be empty and is the primary key
    farmID INT NOT NULL, -- adds a column called farmID which can't be null
    initiative_description VARCHAR(255),
    date_initiated DATE,
    expected_impact VARCHAR(255),
    ev_score INT,
    water_source VARCHAR(255),
    labour_hours INT,
    PRIMARY KEY (sustainabilityID, farmID), -- defines a composite key as initatives are unique to a farm
    FOREIGN KEY (farmID) REFERENCES Farm(farmID) -- defining the foreign key as farmID
);

# Staging Table for Raw CSV
CREATE TABLE Staging ( -- Create a temporary table to allow the data to be read it and split into its other tables easily
    farmID INT,
    farm_location VARCHAR(255),
    cropID INT,
    crop_name VARCHAR(255),
    planting_date VARCHAR(10), -- dates are read in as varchars because the dates columns have some differing styles
    harvest_date VARCHAR(10), -- dates are read in as varchars because the dates columns have some differing styles
    soilID INT,
    ph_level DECIMAL(3,1),
    nitrogen_level INT,
    phosphorus_level INT,
    potassium_level INT,
    resourceID INT,
    resource_type VARCHAR(255),
    resource_quantity DECIMAL(10,2),
    date_of_application VARCHAR(10), -- dates are read in as varchars because the dates columns have some differing styles
    initiativeID INT,
    initiative_description VARCHAR(255),
    date_initiated VARCHAR(10), -- dates are read in as varchars because the dates columns have some differing styles
    expected_impact VARCHAR(255),
    crop_yield INT,
    ev_score INT,
    water_source VARCHAR(255),
    labour_hours INT
);

# Load Data into Staging Table

LOAD DATA LOCAL INFILE '/Users/joshlegrice/Desktop/University/Masters/Data Systems/Coursework/COMM108_Data_Coursework.csv'
INTO TABLE Staging -- load the data from the above location into the temporary table
FIELDS TERMINATED BY ',' -- defines that the columns are delimated by a comma
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignores the header rows of the .csv 

# Clean Dates -- changing the dates into the correct formats from strings

UPDATE Staging -- update the staging table
SET planting_date = CASE
    -- when planting date is in the format d/m/y then convert it to a date
    WHEN planting_date LIKE '%/%/%' THEN STR_TO_DATE(planting_date, '%d/%m/%Y')
    -- when planting date is in the format y-m-d then convert it to a date
    WHEN planting_date LIKE '%-%-%' THEN STR_TO_DATE(planting_date, '%Y-%m-%d')
    ELSE NULL
END,
harvest_date = CASE
    -- when harvest date is in the format d/m/y then convert it to a date
    WHEN harvest_date LIKE '%/%/%' THEN STR_TO_DATE(harvest_date, '%d/%m/%Y')
    -- when harvest date is in the format y-m-d then convert it to a date
    WHEN harvest_date LIKE '%-%-%' THEN STR_TO_DATE(harvest_date, '%Y-%m-%d')
    ELSE NULL
END,
date_of_application = CASE
    -- when application date is in the format d/m/y then convert it to a date
    WHEN date_of_application LIKE '%/%/%' THEN STR_TO_DATE(date_of_application, '%d/%m/%Y')
    -- when application date is in the format y-m-d then convert it to a date
    WHEN date_of_application LIKE '%-%-%' THEN STR_TO_DATE(date_of_application, '%Y-%m-%d')
    ELSE NULL
END,
date_initiated = CASE
    -- when initiation data is in the format d/m/y then convert it to a date
    WHEN date_initiated LIKE '%/%/%' THEN STR_TO_DATE(date_initiated, '%d/%m/%Y')
    -- when initiation data is in the format y-m-d then convert it to a date
    WHEN date_initiated LIKE '%-%-%' THEN STR_TO_DATE(date_initiated, '%Y-%m-%d') 
    ELSE NULL
END;

-- '%Y-%m-%d' or '%d/%m/%Y' shows the format of the original date

ALTER TABLE Staging -- converts all date columns into date format from string
MODIFY planting_date DATE,
MODIFY harvest_date DATE,
MODIFY date_of_application DATE,
MODIFY date_initiated DATE;


# Insert into Core Tables

# Farms
INSERT INTO Farm (farmID, farm_Location) -- insert data into the farm table in farmID and farm_Location
SELECT DISTINCT farmID, farm_location -- select the unique `farmID` and `farm_Location` from staging
FROM Staging;

# Crops
INSERT INTO Crops (cropID, farmID, crop_name, planting_date, harvest_date)  -- insert these fields into the crop table
SELECT DISTINCT cropID, farmID, crop_name, planting_date, harvest_date -- select unique values from those fields in staging
FROM Staging;

# Soils
INSERT INTO Soils (soilID, farmID, ph_level, nitrogen_level, phosphorus_level, potassium_level) -- insert these fields into the soil table
SELECT DISTINCT soilID, farmID, ph_level, nitrogen_level, phosphorus_level, potassium_level -- select unique values from those fields in staging
FROM Staging;

# Resources
INSERT INTO Resources (resource_type) --insert resource_type into the resources table
SELECT DISTINCT resource_type -- select unique values from resource_type from staging
FROM Staging
WHERE resource_type IS NOT NULL; -- make sure resource type isn't null

# Initiatives
INSERT INTO Initiatives (sustainabilityID, farmID, initiative_description, date_initiated,
                         expected_impact, ev_score, water_source, labour_hours) -- insert these fields into the initiatives table
SELECT initiativeID, farmID, 
       -- Using aggregate functions to select a single value for each record
       MIN(initiative_description), 
       MIN(date_initiated),
       MIN(expected_impact),
       MIN(ev_score),
       MIN(water_source),
       MIN(labour_hours)
FROM Staging
GROUP BY initiativeID, farmID;

# Junction Tables

# Crop-Resource 
-- needed as 1 crop can have more than one resource used on it
-- also a single resource type can be applied to more than one type of crop - would be a m-m without this table
-- allows the ability to see how much of each resource is used on each crop
CREATE TABLE Crop_Resource (
    cropID INT,
    resourceID INT,
    resource_quantity DECIMAL(10,2),
    date_of_application DATE,
    PRIMARY KEY (cropID, resourceID, date_of_application),
    FOREIGN KEY (cropID) REFERENCES Crops(cropID),
    FOREIGN KEY (resourceID) REFERENCES Resources(resourceID)
);

-- insert the data from the staging and resources tables
INSERT INTO Crop_Resource (cropID, resourceID, resource_quantity, date_of_application)
SELECT DISTINCT s.cropID, r.resourceID, s.resource_quantity, s.date_of_application
FROM Staging s
JOIN Resources r ON s.resource_type = r.resource_type;

# Crop-Initiative 
-- needed as multiple crops use one initiative 
-- allows in future for multiple crops to be grown under one initiative
-- also allows to see which resource gives the best crop yeild on the certain crops
CREATE TABLE Crop_Initiative ( 
    cropID INT,
    sustainabilityID INT,
    farmID INT,
    crop_yield INT,
    --- Primary Key ensures each crop-initiative-farm combination is unique
    PRIMARY KEY (cropID, sustainabilityID, farmID),
    FOREIGN KEY (cropID) REFERENCES Crops(cropID),
    FOREIGN KEY (sustainabilityID, farmID) REFERENCES Initiatives(sustainabilityID, farmID)
);

-- insert the data from the staging and initiatives tables
INSERT INTO Crop_Initiative (cropID, sustainabilityID, farmID, crop_yield)
SELECT DISTINCT cropID, initiativeID, farmID, crop_yield
FROM Staging;

# drop the staging table
DROP TABLE Staging; -- drops the staging table as it is not needed anymore, avoid redundancy