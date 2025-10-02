# Create Database
DROP DATABASE IF EXISTS Agriculture;
CREATE DATABASE Agriculture;
USE Agriculture;

SET GLOBAL local_infile = 1;

# Core Tables

# Farm Table
CREATE TABLE Farm (
    farmID INT NOT NULL PRIMARY KEY,
    farm_Location VARCHAR(255)
);

# Crops Table
CREATE TABLE Crops (
    cropID INT NOT NULL PRIMARY KEY,
    farmID INT NOT NULL,
    crop_name VARCHAR(255),
    planting_date DATE,
    harvest_date DATE,
    FOREIGN KEY (farmID) REFERENCES Farm(farmID)
);

# Soil Table
CREATE TABLE Soils (
    soilID INT NOT NULL PRIMARY KEY,
    farmID INT NOT NULL,
    ph_level DECIMAL(3,1),
    nitrogen_level INT,
    phosphorus_level INT,
    potassium_level INT,
    FOREIGN KEY (farmID) REFERENCES Farm(farmID)
);

# Resources table
CREATE TABLE Resources (
    resourceID INT AUTO_INCREMENT PRIMARY KEY,
    resource_type VARCHAR(255)
);

# Initiatives
CREATE TABLE Initiatives (
    sustainabilityID INT,
    farmID INT NOT NULL,
    initiative_description VARCHAR(255),
    date_initiated DATE,
    expected_impact VARCHAR(255),
    ev_score INT,
    water_source VARCHAR(255),
    labour_hours INT,
    PRIMARY KEY (sustainabilityID, farmID),
    FOREIGN KEY (farmID) REFERENCES Farm(farmID)
);

# Staging Table for Raw CSV
CREATE TABLE Staging (
    farmID INT,
    farm_location VARCHAR(255),
    cropID INT,
    crop_name VARCHAR(255),
    planting_date VARCHAR(10),
    harvest_date VARCHAR(10),
    soilID INT,
    ph_level DECIMAL(3,1),
    nitrogen_level INT,
    phosphorus_level INT,
    potassium_level INT,
    resourceID INT,
    resource_type VARCHAR(255),
    resource_quantity DECIMAL(10,2),
    date_of_application VARCHAR(10),
    initiativeID INT,
    initiative_description VARCHAR(255),
    date_initiated VARCHAR(10),
    expected_impact VARCHAR(255),
    crop_yield INT,
    ev_score INT,
    water_source VARCHAR(255),
    labour_hours INT
);

# Load Data into Staging Table

LOAD DATA LOCAL INFILE '/Users/joshlegrice/Desktop/University/Masters/Data Systems/Coursework/COMM108_Data_Coursework.csv'
INTO TABLE Staging
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Clean Dates

UPDATE Staging 
SET planting_date = CASE
    WHEN planting_date LIKE '%/%/%' THEN STR_TO_DATE(planting_date, '%d/%m/%Y')
    WHEN planting_date LIKE '%-%-%' THEN STR_TO_DATE(planting_date, '%Y-%m-%d')
    ELSE NULL
END,
harvest_date = CASE
    WHEN harvest_date LIKE '%/%/%' THEN STR_TO_DATE(harvest_date, '%d/%m/%Y')
    WHEN harvest_date LIKE '%-%-%' THEN STR_TO_DATE(harvest_date, '%Y-%m-%d')
    ELSE NULL
END,
date_of_application = CASE
    WHEN date_of_application LIKE '%/%/%' THEN STR_TO_DATE(date_of_application, '%d/%m/%Y')
    WHEN date_of_application LIKE '%-%-%' THEN STR_TO_DATE(date_of_application, '%Y-%m-%d')
    ELSE NULL
END,
date_initiated = CASE
    WHEN date_initiated LIKE '%/%/%' THEN STR_TO_DATE(date_initiated, '%d/%m/%Y')
    WHEN date_initiated LIKE '%-%-%' THEN STR_TO_DATE(date_initiated, '%Y-%m-%d')
    ELSE NULL
END;

ALTER TABLE Staging
MODIFY planting_date DATE,
MODIFY harvest_date DATE,
MODIFY date_of_application DATE,
MODIFY date_initiated DATE;


# Insert into Core Tables

# Farms
INSERT INTO Farm (farmID, farm_Location)
SELECT DISTINCT farmID, farm_location
FROM Staging;

# Crops
INSERT INTO Crops (cropID, farmID, crop_name, planting_date, harvest_date)
SELECT DISTINCT cropID, farmID, crop_name, planting_date, harvest_date
FROM Staging;

# Soils
INSERT INTO Soils (soilID, farmID, ph_level, nitrogen_level, phosphorus_level, potassium_level)
SELECT DISTINCT soilID, farmID, ph_level, nitrogen_level, phosphorus_level, potassium_level
FROM Staging;

# Resources
INSERT INTO Resources (resource_type)
SELECT DISTINCT resource_type
FROM Staging
WHERE resource_type IS NOT NULL;

# Initiatives
INSERT INTO Initiatives (sustainabilityID, farmID, initiative_description, date_initiated,
                         expected_impact, ev_score, water_source, labour_hours)
SELECT initiativeID, farmID,
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
CREATE TABLE Crop_Resource (
    cropID INT,
    resourceID INT,
    resource_quantity DECIMAL(10,2),
    date_of_application DATE,
    PRIMARY KEY (cropID, resourceID, date_of_application),
    FOREIGN KEY (cropID) REFERENCES Crops(cropID),
    FOREIGN KEY (resourceID) REFERENCES Resources(resourceID)
);

INSERT INTO Crop_Resource (cropID, resourceID, resource_quantity, date_of_application)
SELECT DISTINCT s.cropID, r.resourceID, s.resource_quantity, s.date_of_application
FROM Staging s
JOIN Resources r ON s.resource_type = r.resource_type;

# Crop-Initiative 
CREATE TABLE Crop_Initiative (
    cropID INT,
    sustainabilityID INT,
    farmID INT,
    crop_yield INT,
    PRIMARY KEY (cropID, sustainabilityID, farmID),
    FOREIGN KEY (cropID) REFERENCES Crops(cropID),
    FOREIGN KEY (sustainabilityID, farmID) REFERENCES Initiatives(sustainabilityID, farmID)
);

INSERT INTO Crop_Initiative (cropID, sustainabilityID, farmID, crop_yield)
SELECT DISTINCT cropID, initiativeID, farmID, crop_yield
FROM Staging;

# drop the staging table
DROP TABLE Staging;