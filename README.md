# Titanic ELT Pipeline

## Project Overview

The **Titanic ELT Pipeline** is a data engineering project that demonstrates how raw Titanic passenger data can be extracted, loaded into a MySQL database, transformed using SQL, and prepared for analytical reporting.

The project follows the ELT (Extract, Load, Transform) approach. Raw data is first loaded into the database, then cleaned and transformed using SQL queries. Analytical views and data quality checks are created to support further analysis.

## Project Objectives

- Extract the Titanic dataset using Python and Seaborn.
- Load raw passenger data into a MySQL database.
- Create a staging table with standardized data types and text values.
- Handle missing values and transform passenger attributes using SQL.
- Perform feature engineering to create useful analytical columns.
- Create SQL views to analyze passenger survival patterns.
- Validate the cleaned data using data quality checks.

## Technologies Used

| Technology | Purpose |
|---|---|
| Python | Pipeline execution and data loading |
| Pandas | Data handling |
| Seaborn | Loading the Titanic dataset |
| MySQL | Database storage and processing |
| SQL | Data staging, transformation, analytics, and validation |
| SQLAlchemy | Python–MySQL connectivity |
| PyMySQL | MySQL database driver |
| Python-dotenv | Environment variable management |

## Project Structure

```text
titanic_elt_pipeline/
│
├── sql/
│   ├── 01_staging.sql
│   ├── 02_transform.sql
│   ├── 03_analytics.sql
│   └── 04_quality_checks.sql
│
├── .env
├── .env.example
├── .gitignore
├── extract_load.py
├── run_elt.py
├── requirements.txt
└── README.md
```

## ELT Pipeline Workflow

### 1. Extract and Load

**File:** `extract_load.py`

- Loads the Titanic dataset using Seaborn.
- Adds `load_timestamp` and `batch_id` metadata columns.
- Loads the raw dataset into the MySQL table `raw_titanic`.
- Replaces the existing raw table during a fresh pipeline run.

### 2. Staging

**File:** `sql/01_staging.sql`

- Creates the `stg_titanic` staging table.
- Converts columns into appropriate data types.
- Standardizes selected text columns using `LOWER()` and `TRIM()`.
- Carries forward the load metadata.

### 3. Data Transformation

**File:** `sql/02_transform.sql`

Creates the `clean_passengers` table.

The transformation stage includes:

- Replacing missing age values with the average age grouped by passenger class and