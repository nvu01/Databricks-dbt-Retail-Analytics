# Databricks notebook source
# MAGIC %md
# MAGIC # 02 — Load Raw Data into Delta Tables
# MAGIC
# MAGIC This notebook reads the Olist CSV files from DBFS and writes them
# MAGIC as Delta tables in the `raw` schema.
# MAGIC
# MAGIC **Before running:** Upload all 6 Olist CSVs via Data > Add Data > Upload File

# COMMAND ----------

# MAGIC %md
# MAGIC ## Configuration

# COMMAND ----------

# Base path where you uploaded the CSVs
UPLOAD_PATH = "/FileStore/tables"

# Map of table names to CSV filenames
RAW_TABLES = {
    "orders":        "olist_orders_dataset.csv",
    "customers":     "olist_customers_dataset.csv",
    "products":      "olist_products_dataset.csv",
    "order_payments":"olist_order_payments_dataset.csv",
    "order_items":   "olist_order_items_dataset.csv",
    "sellers":       "olist_sellers_dataset.csv",
}

# COMMAND ----------

# MAGIC %md
# MAGIC ## Helper Function

# COMMAND ----------

def load_csv_to_delta(table_name: str, csv_filename: str):
    """
    Reads a CSV from DBFS and writes it as a Delta table in the raw schema.
    Uses overwrite mode so the notebook is idempotent (safe to re-run).
    """
    csv_path = f"{UPLOAD_PATH}/{csv_filename}"
    
    print(f"Loading: {csv_path}")
    
    df = (
        spark.read
        .option("header", "true")
        .option("inferSchema", "true")
        .option("multiLine", "true")       # handles fields with newlines
        .option("escape", '"')             # handles quoted commas
        .csv(csv_path)
    )
    
    row_count = df.count()
    
    (
        df.write
        .format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(f"raw.{table_name}")
    )
    
    print(f"  ✅ raw.{table_name} — {row_count:,} rows loaded\n")
    return row_count

# COMMAND ----------

# MAGIC %md
# MAGIC ## Load All Tables

# COMMAND ----------

total_rows = 0
failed = []

for table_name, csv_file in RAW_TABLES.items():
    try:
        rows = load_csv_to_delta(table_name, csv_file)
        total_rows += rows
    except Exception as e:
        print(f"  ❌ Failed to load {table_name}: {e}\n")
        failed.append(table_name)

print("=" * 50)
print(f"Total rows loaded: {total_rows:,}")
if failed:
    print(f"Failed tables: {failed}")
else:
    print("All tables loaded successfully ✅")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Preview Raw Tables

# COMMAND ----------

# MAGIC %md ### Orders

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM raw.orders LIMIT 5

# COMMAND ----------

# MAGIC %md ### Customers

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM raw.customers LIMIT 5

# COMMAND ----------

# MAGIC %md ### Order Items

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM raw.order_items LIMIT 5

# COMMAND ----------

# MAGIC %md ### Payments

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM raw.order_payments LIMIT 5

# COMMAND ----------

# MAGIC %md
# MAGIC ## Basic Data Profiling

# COMMAND ----------

print("📊 Row counts per raw table:")
print("-" * 40)
for table in RAW_TABLES.keys():
    count = spark.table(f"raw.{table}").count()
    print(f"  raw.{table:<20} {count:>10,} rows")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Enable Delta Time Travel
# MAGIC
# MAGIC Delta tables automatically version every write.
# MAGIC You can query historical versions like this:

# COMMAND ----------

# MAGIC %sql
# MAGIC -- View the history of the orders table
# MAGIC DESCRIBE HISTORY raw.orders

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Example: query the table as it looked at version 0 (first load)
# MAGIC SELECT COUNT(*) AS row_count_at_version_0
# MAGIC FROM raw.orders VERSION AS OF 0

# COMMAND ----------

# MAGIC %md
# MAGIC ## ✅ Next Step
# MAGIC Run notebook `03_run_dbt_and_validate.py` to execute dbt transformations.
