"""
Project Configuration Module
----------------------------
Handles path configurations and database engine initialization.
Optimized for Astro CLI / Docker environments with defensive error handling.
"""

import os
import logging
import urllib.parse
from pathlib import Path
from sqlalchemy import create_engine

# --- Logging Configuration ---
# Directing logs to Airflow's internal task logger for UI visibility.
logger = logging.getLogger("airflow.task")

# --- Path Configuration (Astro/Docker Optimized) ---
# AIRFLOW_HOME is automatically set by Astro CLI inside the container.
AIRFLOW_HOME = Path(os.getenv('AIRFLOW_HOME', '/usr/local/airflow'))
INCLUDE_DIR  = AIRFLOW_HOME / 'include'

# SQL Transformation Paths
SILVER_PATH = INCLUDE_DIR / 'sql' / 'silver'
GOLD_PATH   = INCLUDE_DIR / 'sql' / 'gold'

# --- Database Credentials ---
# Fetched from the .env file automatically by Astro CLI.
DB_SERVER   = os.getenv('DB_SERVER')
DB_NAME     = os.getenv('DB_NAME')
DB_USER     = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')

def get_connection_url() -> str:
    """
    Constructs the SQLAlchemy connection URL for SQL Server.
    Validates presence of credentials before string construction.
    """
    secrets = [DB_SERVER, DB_NAME, DB_USER, DB_PASSWORD]
    
    if not all(secrets):
        logger.error('🛑 Missing database credentials in .env file (DB_SERVER, DB_NAME, etc.).')
        return ""

    # URL-encode the password to handle special characters safely.
    pwd_encoded = urllib.parse.quote_plus(DB_PASSWORD)

    # Note: 'TrustServerCertificate=yes' is critical for Docker-to-Host SQL connections.
    return (
        f'mssql+pyodbc://{DB_USER}:{pwd_encoded}@{DB_SERVER}/{DB_NAME}'
        '?driver=ODBC+Driver+18+for+SQL+Server'
        '&TrustServerCertificate=yes'
        '&Encrypt=yes'
    )

# --- SQLAlchemy Engine Initialization (Defensive Layer) ---
DATABASE_URL = get_connection_url()

# Default the engine to None to prevent crashes during DAG parsing if setup fails.
engine = None

if DATABASE_URL:
    try:
        # pool_pre_ping=True: Essential for long-running Airflow environments to 
        # recycle stale connections.
        engine = create_engine(DATABASE_URL, pool_pre_ping=True)
        logger.info("✅ Database engine defined and ready.")
        
    except Exception as e:
        # Catching system-level errors (e.g., missing ODBC driver, network isolation).
        logger.error(f"🛑 Critical Error during engine initialization: {str(e)}")
else:
    logger.warning("⚠️ Database engine skipped: Connection URL is empty.")