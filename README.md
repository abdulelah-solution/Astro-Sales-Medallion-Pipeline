# 🚀 Unified Sales Data Platform: Medallion Architecture with Astro Airflow

[![Airflow](https://img.shields.io/badge/Orchestration-Apache%20Airflow%202.x-red.svg)](https://airflow.apache.org/)
[![Astro CLI](https://img.shields.io/badge/Environment-Astro%20CLI-blue.svg)](https://www.astronomer.io/docs/cloud/stable/develop/astro-cli)
[![SQL Server](https://img.shields.io/badge/Database-MS%20SQL%20Server-lightgrey.svg)](https://www.microsoft.com/en-us/sql-server/)
[![Python](https://img.shields.io/badge/Language-Python%203.12-yellow.svg)](https://www.python.org/)

## 🌟 Project Overview
Welcome to the upgraded version of the **Unified Sales Data Warehouse**. This project has evolved from a collection of standalone scripts into a robust, production-ready **ELT Pipeline**. 

By leveraging the **Medallion Architecture** and **Astro CLI (Apache Airflow)**, this platform automates the ingestion, transformation, and materialization of sales data from disparate CRM and ERP systems into a highly optimized Star Schema for Business Intelligence.

---

## 🏗️ Architecture: The Medallion Pattern
The pipeline is structured into three distinct layers to ensure data integrity and scalability:

### 🥉 Bronze (Raw Layer)
- **Source:** Automated CSV ingestion from multiple source systems (CRM & ERP).
- **Process:** Validates file existence, handles empty datasets, and injects technical metadata (`dwh_load_date`).
- **Storage:** Staged in SQL Server as raw-identical tables.

### 🥈 Silver (Cleansing & Integration Layer)
- **Process:** Executes modular SQL scripts to clean, cast, and unify data.
- **Logic:** Handles data type conversions, deduplication, and standardizes formats across different systems.

### 🥇 Gold (Analytics Layer)
- **Process:** Materializes the final **Star Schema** (Fact & Dimension tables).
- **Goal:** Provides a consumption-ready environment for PowerBI, Excel, and advanced financial reporting.

---

## 🛠️ Tech Stack & Key Features
- **Astro CLI:** Containerized Airflow environment for consistent deployment.
- **Dynamic Task Generation:** Automatically detects new data sources via `YAML` configuration.
- **Defensive Programming:** Robust error handling with `SQLAlchemy` and `Pandas` to prevent pipeline breaks.
- **Atomic Transactions:** Uses `engine.begin()` to ensure "All-or-Nothing" SQL executions.
- **Medallion Orchestrator:** A unified Python utility module managing the full data lifecycle.

---

## 📂 Project Structure
```bash
├── dags/
│   └── elt_pipeline.py         # The Maestro: Orchestrates all tasks
├── include/
│   ├── config/
│   │   └── sources.yaml        # Dynamic source management
│   ├── python/
│   │   ├── config.py           # Centralized logging & DB engine
│   │   └── database_utils.py   # Core ELT utility functions
│   └── sql/
│       ├── silver/             # Transformation logic (CRM/ERP)
│       └── gold/               # Dimension & Fact materialization
├── tests/                      # Unit tests for DAG integrity
└── Dockerfile                  # Containerized environment setup
```
---

## 🚀 How to Run
1. Prerequisites: Install Astro CLI.

2. Setup: Clone the repo and add your .env file with SQL Server credentials.

3. Start: Run astro dev start.

4. Monitor: Access the Airflow UI at localhost:8080 to trigger the elt_pipeline_dag_v1.

---

## 👨‍💻 Author
Abdulelah
Data Engineer | Finance & Supply Chain Professional 📍 Riyadh, Saudi Arabia

---

## 📬 Contact & Connect
I am currently looking for new opportunities in Data Engineering and Finance/Supply Chain Analytics in the Riyadh region. Feel free to reach out!

- **LinkedIn:** [**Abdulelah's Profile**](https://www.linkedin.com/in/abdulelah-muhmin-a215a41a1/)

- **GitHub:** [**Abdulelah's Repositories**](https://github.com/abdulelah-solution)
