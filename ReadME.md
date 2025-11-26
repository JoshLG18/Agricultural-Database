# Designing Sustainable Agriculture Databases

## Project Overview
This project involves the design, implementation, and deployment of a relational database system for tracking UK agricultural sustainability initiatives. The system manages complex relationships between farms, crops, resources, and environmental impact scores to support data-driven decision-making.

This submission fulfills the COMM108 Data Systems coursework requirements and extends them with a cloud-hosted implementation and a custom API.

## Tech Stack
* **Database:** MySQL (Local Development), Azure SQL (Cloud Production)
* **Backend:** Node.js, Express.js
* **Data Engineering:** SQL (Staging, Cleaning, Normalization), Python
* **Documentation:** LaTeX, ERD Design

## Key Features

### 1. Advanced Relational Database Design (3NF)
The database was designed to the Third Normal Form (3NF) to ensure data integrity and minimize redundancy.
* **Normalization:** Decomposed raw data to remove transitive dependencies.
* **Junction Tables:** Utilized tables like `Farm_Crop` and `Crop_Resource` to handle many-to-many relationships and store temporal data.

### 2. SQL ETL Pipeline
A robust SQL script was implemented to handle data ingestion:
* **Staging:** Loads raw CSV data into a temporary staging table.
* **Cleaning:** Standardizes date formats and strings within the staging environment.
* **Population:** Transforms and inserts clean data into the final normalized schema.

### 3. RESTful API & Cloud Deployment
To extend the project beyond the basic requirements, the database was hosted on **Microsoft Azure SQL**. A RESTful API was developed using **Node.js** and **Express** to provide secure, programmatic access to the data (e.g., `GET /farms`, `GET /crops/:id`).

### 4. NoSQL Alternative Analysis
The project includes a comparative report analyzing a Document-Based (NoSQL) approach, evaluating the trade-offs between the strict consistency of the relational model and the flexibility of a denormalized JSON structure.

## Folder Layout

```text
├── README.md               # This file
├── .gitignore              # Ignore files
├── coursework.pdf          # Assignment Brief
├── data/
│   └── COMM108_Data_Coursework.csv   # Raw Data file
├── images/
│   └── DatabaseDiagram.png # Entity Relationship Diagram
├── report/
│   ├── Report.pdf          # Full PDF Report
│   └── Report.tex          # LaTeX source
└── code/
    └── database_creation_+_population.sql # Main SQL script
