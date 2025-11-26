# Designing Sustainable Agriculture Databases

## Project Overview
This project involves the design, implementation, and deployment of a relational database system for tracking UK agricultural sustainability initiatives. The system manages complex relationships between farms, crops, resources, and environmental impact scores to support data-driven decision-making.

This submission fulfils the COMM108 Data Systems coursework requirements and extends them with a cloud-hosted implementation, a custom REST API, and a frontend interface.

## Tech Stack
* **Database:** MySQL (Local Development), Azure SQL (Cloud Production)
* **Backend:** Node.js, Express.js
* **Frontend:** HTML, JavaScript (Web Interface)
* **Data Engineering:** SQL (Staging, Cleaning, Normalisation), Python
* **DevOps:** GitHub Actions (CI/CD Workflows)
* **Documentation:** LaTeX, ERD Design

## Key Features

### 1. Advanced Relational Database Design (3NF)
The database was rigorously designed to the Third Normal Form (3NF) to ensure data integrity and minimise redundancy.
* **Normalisation:** Decomposed raw data to remove transitive dependencies.
* **Junction Tables:** Utilised tables like `Farm_Crop` and `Crop_Resource` to handle many-to-many relationships and store temporal data.

### 2. SQL ETL Pipeline
A robust SQL script was implemented to handle data ingestion:
* **Staging:** Loads raw CSV data into a temporary staging table.
* **Cleaning:** Standardises date formats and strings within the staging environment.
* **Population:** Transforms and inserts clean data into the final normalised schema.

### 3. Full-Stack Cloud Deployment
To extend the project beyond the basic requirements, the architecture was expanded into a full-stack application:
* **Backend:** A RESTful API built with **Node.js** and **Express** provides secure, programmatic access to the data (e.g., `GET /farms`).
* **Frontend:** A web interface allows users to visualise farm data and sustainability scores.
* **Cloud:** The database is hosted on **Microsoft Azure SQL** for production accessibility.

### 4. NoSQL Alternative Analysis
The project includes a comparative report analysing a Document-Based (NoSQL) approach, evaluating the trade-offs between the strict consistency of the relational model and the flexibility of a denormalised JSON structure.

## Folder Layout

```text
├── .github/workflows/      # CI/CD pipeline configurations
├── 720017170_Submission/   # Final submission package
├── backend/                # Node.js & Express API source code
├── code/                   # SQL scripts (Schema, Staging & Population)
├── data/                   # Raw agricultural datasets (CSV)
├── frontend/               # User interface code
├── images/                 # Entity Relationship Diagrams (ERD) & Assets
├── references/             # Bibliography and citation sources
├── report/                 # Project documentation
│   ├── Report.pdf          # Full technical report
│   └── Report.tex          # LaTeX source files
├── .gitignore              # Git ignore rules
├── coursework.pdf          # Assignment Brief
└── README.md               # Project documentation
