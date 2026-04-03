"""
Database Utilities Module (Medallion Architecture)
-------------------------------------------------
A centralized suite of helper functions for the end-to-end data lifecycle:
1. Bronze: Fetching CSV data and loading into staging tables.
2. Silver: Executing SQL transformation scripts for data cleaning.
3. Gold: Materializing final dimensions and facts for analytics.

Optimized for Astro CLI / Docker and built with Defensive Programming principles.
"""

import pandas as pd
import sqlalchemy.exc
from sqlalchemy import text
from pathlib import Path
from typing import Optional
from include.python.config import INCLUDE_DIR, logger, engine

def fetching_data(filename: str) -> Optional[pd.DataFrame]:
    """
    Reads a CSV file from the local data directory and adds metadata.
    """
    # path construction using pathlib
    file_path = INCLUDE_DIR / 'data' / 'raw' / filename.strip()

    if not file_path.exists():
        logger.warning(f"⚠️ File not found at: {file_path}")
        return None
    
    try:
        df = pd.read_csv(file_path)
        
        if df.empty:
            logger.warning(f'⚠️ File is empty: {filename}. Skipping ingestion.')
            return None
        
        # Add technical metadata for audit purposes
        df['dwh_load_date'] = pd.Timestamp.now()
        logger.info(f'✅ Successfully fetched: {filename} ({len(df)} rows)')
        return df
        
    except Exception as e:
        logger.error(f'❌ Unexpected error reading {filename}: {str(e)}')
        return None

def loading_df_to_db(table_name: str, df: pd.DataFrame, schema: str = 'bronze') -> None:
    """
    Loads a pandas DataFrame into a specific SQL Server table.
    Includes a safety check for the database engine.
    """
    # --- Critical Safety Check ---
    if engine is None:
        logger.error(f"🛑 Failure: Database engine is not initialized. Cannot load table [{table_name}].")
        # Raising an exception here ensures the Airflow Task fails visibly
        raise RuntimeError("Database Engine is None. Check .env and config.py")

    if df is not None:
        try:
            # chunksize=1000 helps manage memory for larger datasets
            df.to_sql(
                name=table_name,
                con=engine,
                schema=schema,
                if_exists='replace',
                index=False,
                chunksize=1000
            )
            logger.info(f'✅ Loaded {len(df)} rows into [{schema}].[{table_name}]')

        except Exception as e:
            logger.error(f'❌ SQL Error on table [{table_name}]: {str(e)}')
            raise # Re-raising the error to fail the Airflow Task
    else:
        logger.warning(f'⚠️ No data provided for table: {table_name}')

def run_sql_scripts(sql_script: Path) -> None:
    """
    Reads and executes a single SQL script within a database transaction.
    Uses 'engine.begin()' for automatic commit/rollback.
    """
    # --- Critical Safety Check ---
    if engine is None:
        logger.error(f"🛑 Failure: Database engine is not initialized. Cannot run script: {sql_script.name}")
        raise RuntimeError("Database Engine is None. Check .env and config.py")
    
    # Check if the file physically exists before attempting to read
    if not sql_script.exists():
        logger.error(f'❌ SQL File not found at path: {sql_script}')
        raise FileNotFoundError(f"Could not find SQL file: {sql_script}")

    try:
        # Read the SQL content from the file
        with open(sql_script, 'r', encoding='utf-8') as file:
            sql_command = file.read().strip()

            # Skip execution if the file is empty or contains only whitespace
            if not sql_command:
                logger.warning(f"⚠️ Script '{sql_script.name}' is empty. Skipping execution.")
                return

        # Execute the SQL command using a context manager for automatic commit/rollback
        with engine.begin() as connection:
            connection.execute(text(sql_command))
            logger.info(f'✅ Successfully executed Silver transformation: {sql_script.name}')

    except sqlalchemy.exc.SQLAlchemyError as e:
        # Handle database-specific errors (syntax, constraints, connectivity)
        logger.critical(f"🛑 Database error while running '{sql_script.name}': {e}")
        raise # Halt the pipeline if a transformation fails
    
    except Exception as e:
        # Handle general errors (file I/O, encoding, etc.)
        logger.error(f"❌ Unexpected error with script '{sql_script.name}': {e}")
        raise

def build_gold_layer(sql_script: Path) -> None:
    """
    Constructs the Gold Layer by executing Dimension and Fact SQL scripts.
    Unifies Silver data into a consumption-ready format (Data Marts).
    """
    logger.info(f'🏆 Initializing Gold Layer construction for: {sql_script.name}')

    try:
        run_sql_scripts(sql_script)
        logger.info(f'✅ Gold object [{sql_script.stem}] successfully materialized.')
        
    except Exception as e:
        logger.error(f'❌ Failed to build Gold Layer for {sql_script.name}: {str(e)}')
        raise