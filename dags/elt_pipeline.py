from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.sdk.bases.operator import cross_downstream
from include.python.config import INCLUDE_DIR, SILVER_PATH, GOLD_PATH
from include.python.database_utils import (
    fetching_data, 
    loading_df_to_db, 
    run_sql_scripts, 
    build_gold_layer
)
import pendulum
from datetime import datetime, timedelta
import yaml

# --- Refined Config Loader ---
def load_config():
    # Dynamic path based on our project structure
    yaml_path = INCLUDE_DIR / 'config' / 'sources.yaml'
    with open(yaml_path, 'r') as f:
        return yaml.safe_load(f)
    
config_data = load_config()

# --- Atomic Ingestion Task ---
def ingestion_task(source_path, target_table, schema):
    """Handles the extraction of a single CSV and loads it to Bronze."""
    filename = source_path.split('/')[-1]
    df = fetching_data(filename=filename)
    
    if df is not None:
        loading_df_to_db(
            table_name=target_table,
            df=df, 
            schema=schema
        )

# --- Default Pipeline Settings ---
default_args = {
    'owner': 'Data_Engineer',
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

local_tz = pendulum.timezone('Asia/Riyadh')

with DAG(
    dag_id='elt_pipeline_dag_v1',
    default_args=default_args,
    start_date=datetime(2026, 4, 1, tzinfo=local_tz),
    schedule='@daily',
    catchup=False,
    tags=['dwh', 'medallion', 'finance']
) as dag:
    
    # --- 1. Bronze Layer (Dynamic Generation) ---
    bronze_tasks = []
    target_schema = config_data['database_config']['target_schema']

    for source in config_data['data_sources']:
        bronze_t = PythonOperator(
            task_id=f"load_{source['target_table']}",
            python_callable=ingestion_task,
            op_kwargs={
                'source_path': source['source_path'],
                'target_table': source['target_table'],
                'schema': target_schema
            }
        )
        bronze_tasks.append(bronze_t)

    # --- 2. Silver Layer (Automatic Transformation) ---
    silver_tasks = []
    all_silver_scripts = list(SILVER_PATH.rglob('*.sql'))

    for script in all_silver_scripts:
        silver_t = PythonOperator(
            task_id=f"transform_silver_{script.stem}",
            python_callable=run_sql_scripts,
            op_kwargs={'sql_script': script}
        )
        silver_tasks.append(silver_t)

    # --- 3. Gold Layer (Final Analytics) ---
    gold_tasks = []
    all_gold_scripts = list(GOLD_PATH.glob('*.sql'))

    for script in all_gold_scripts:
        gold_t = PythonOperator(
            task_id=f"gold_{script.stem}",
            python_callable=build_gold_layer,
            op_kwargs={'sql_script': script}
        )
        gold_tasks.append(gold_t)

    # --- Setting up Dependencies ---
    # Many-to-Many dependency mapping using cross_downstream
    cross_downstream(bronze_tasks, silver_tasks)
    cross_downstream(silver_tasks, gold_tasks)
