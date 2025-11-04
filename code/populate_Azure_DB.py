# Script to populate the azure database
# Based off - 
# https://www.youtube.com/watch?v=svOgLQ7Qmjk

import pandas as pd
from sqlalchemy import create_engine, text
import urllib.parse
import sys
import os
from dotenv import load_dotenv


# Configuration

load_dotenv()  # loads variables from .env into the environment

SERVER = os.getenv("SERVER")
DATABASE = os.getenv("DATABASE")
USERNAME = os.getenv("USERNAME")
PASSWORD = os.getenv("PASSWORD")
CSV_PATH = os.getenv("CSV_PATH")
ODBC_DRIVER = os.getenv("ODBC_DRIVER")

# encodes the connection string so special cahracters don't break the url
quoted_password = urllib.parse.quote_plus(PASSWORD)

# builds the connection string to access the database
CONNECTION_STRING = (
    f"mssql+pyodbc://{USERNAME}:{quoted_password}@{SERVER}/{DATABASE}?"
    f"driver={ODBC_DRIVER}&Encrypt=yes&TrustServerCertificate=no&ConnectionTimeout=30"
)

# Create the engine to connect
try:
    engine = create_engine(CONNECTION_STRING) # try connect to the database and create the engine
    print("Connected to Azure SQL successfully.")
except Exception as e: # if it breaks return the error
    print(f"Connection error: {e}")
    sys.exit(1)

# Exccute SQL helper
def execute_sql_transaction(sql_commands):
    try:
        with engine.begin() as conn: # starts the connection to the database
            for cmd in sql_commands: # iterate through the commands executing them
                conn.execute(text(cmd))
        print("SQL normalization executed successfully.")
        return True
    except Exception as e:
        print(f"SQL execution error: {e}")
        return False


# ETL pipeline
def run_etl_pipeline():
    print("\n Starting ETL pipeline...")

    # Extract
    try:
        df = pd.read_csv(CSV_PATH)
        print(f"CSV loaded successfully with {len(df)} rows.")
    except Exception as e:
        print(f"Error loading CSV: {e}")
        return

    # Transform

    # Force column names to match your Azure schema
    df.columns = [
        "FarmID", "Farm_Location", "CropID", "Crop_Name", "Planting_Date", "Harvest_Date",
        "SoilID", "Ph_Level", "Nitrogen_Level", "Phosphorus_Level", "Potassium_Level",
        "ResourceID", "Resource_Type", "Resource_Quantity", "Date_Of_Application",
        "InitiativeID", "Initiative_Description", "Date_Initiated", "Expected_Impact",
        "Crop_Yield", "EV_Score", "Water_Source", "Labour_Hours"
    ]

    # Clean up date fields
    date_cols = ["Planting_Date", "Harvest_Date", "Date_Of_Application", "Date_Initiated"]
    for col in date_cols:
        df[col] = pd.to_datetime(df[col], errors="coerce", dayfirst=True)
        df[col] = df[col].dt.strftime("%Y-%m-%d")

    # Convert int columns
    int_cols = [
        "FarmID", "CropID", "SoilID", "ResourceID", "InitiativeID",
        "Nitrogen_Level", "Phosphorus_Level", "Potassium_Level",
        "EV_Score", "Labour_Hours", "Crop_Yield"
    ]
    for col in int_cols:
        if col in df.columns:
            df[col] = df[col].fillna(0).astype(int)

    # Load
    print("Loading into Staging table")

    try:
        # Creating a staging table 
        staging_ddl = """
        IF OBJECT_ID('dbo.Staging', 'U') IS NOT NULL DROP TABLE dbo.Staging;
        CREATE TABLE dbo.Staging (
            FarmID INT, Farm_Location VARCHAR(255), CropID INT, Crop_Name VARCHAR(255),
            Planting_Date DATE, Harvest_Date DATE, SoilID INT, Ph_Level DECIMAL(3,1),
            Nitrogen_Level INT, Phosphorus_Level INT, Potassium_Level INT, ResourceID INT,
            Resource_Type VARCHAR(255), Resource_Quantity DECIMAL(10,2), Date_Of_Application DATE,
            InitiativeID INT, Initiative_Description VARCHAR(255), Date_Initiated DATE,
            Expected_Impact VARCHAR(255), Crop_Yield INT, EV_Score INT, Water_Source VARCHAR(255),
            Labour_Hours INT
        );
        """
        execute_sql_transaction([staging_ddl])
        df.to_sql("Staging", con=engine, schema="dbo", if_exists="append", index=False)
        print("Data successfully loaded into dbo.Staging.")
    except Exception as e:
        print(f"Error loading Staging: {e}")
        return

    # Normalize the tables
    print("Populating all other tables")

    normalisation_sql = [        
        # Farm
        """
        INSERT INTO dbo.Farm (farmID, farm_Location)
        SELECT DISTINCT FarmID, Farm_Location
        FROM dbo.Staging
        WHERE FarmID IS NOT NULL;
        """,

        # Crop
        """
        INSERT INTO dbo.Crop (cropID, crop_name)
        SELECT DISTINCT CropID, Crop_Name
        FROM dbo.Staging
        WHERE CropID IS NOT NULL;
        """,

        # Initiative
        """
        INSERT INTO dbo.Initiative (initiativeID, initiative_description)
        SELECT DISTINCT InitiativeID, Initiative_Description
        FROM dbo.Staging
        WHERE InitiativeID IS NOT NULL;
        """,
        
        # Resource
        """
        INSERT INTO dbo.Resource (resourceID, resource_type)
        SELECT DISTINCT ResourceID, Resource_Type
        FROM dbo.Staging
        WHERE ResourceID IS NOT NULL;
        """,
        
        # Soil
        """
        INSERT INTO dbo.Soil (soilID, farmID, ph_level, nitrogen_level, phosphorus_level, potassium_level)
        SELECT DISTINCT SoilID, FarmID, Ph_Level, Nitrogen_Level, Phosphorus_Level, Potassium_Level
        FROM dbo.Staging
        WHERE SoilID IS NOT NULL;
        """,

        # Junction Tables
        
        # Farm_Initiative
        """
        INSERT INTO dbo.Farm_Initiative (initiativeID, farmID, date_initiated, expected_impact, ev_score, water_source)
        SELECT DISTINCT InitiativeID, FarmID, Date_Initiated, Expected_Impact, EV_Score, Water_Source
        FROM dbo.Staging
        WHERE InitiativeID IS NOT NULL AND FarmID IS NOT NULL;
        """,
        
        # Farm_Crop
        """
        INSERT INTO dbo.Farm_Crop (farmID, cropID, planting_date, harvest_date)
        SELECT DISTINCT FarmID, CropID, Planting_Date, Harvest_Date
        FROM dbo.Staging
        WHERE FarmID IS NOT NULL AND CropID IS NOT NULL;
        """,

        # Crop_Initiative
        """
        INSERT INTO dbo.Crop_Initiative (cropID, initiativeID, crop_yield)
        SELECT DISTINCT CropID, InitiativeID, Crop_Yield
        FROM dbo.Staging
        WHERE CropID IS NOT NULL AND InitiativeID IS NOT NULL;
        """,
        
        # Crop_Resource
        """
        INSERT INTO dbo.Crop_Resource (cropID, resourceID, resource_quantity, date_of_application)
        SELECT DISTINCT CropID, ResourceID, Resource_Quantity, Date_Of_Application
        FROM dbo.Staging
        WHERE CropID IS NOT NULL AND ResourceID IS NOT NULL;
        """,

        # Labour
        """
        INSERT INTO dbo.Labour (farmID, initiativeID, cropID, resourceID, labour_hours)
        SELECT DISTINCT FarmID, InitiativeID, CropID, ResourceID, Labour_Hours
        FROM dbo.Staging
        WHERE Labour_Hours IS NOT NULL 
          AND FarmID IS NOT NULL 
          AND InitiativeID IS NOT NULL
          AND CropID IS NOT NULL
          AND ResourceID IS NOT NULL; -- CRUCIAL: All PK components checked
        """,

        # Drop Staging
        "IF OBJECT_ID('dbo.Staging', 'U') IS NOT NULL DROP TABLE dbo.Staging;"
    ]

    if execute_sql_transaction(normalisation_sql):
        print("\nETL pipeline completed successfully.")
    else:
        print("\nETL pipeline failed during normalization.")

# run the pipeline
if __name__ == "__main__":
    run_etl_pipeline()