# Databricks notebook source
# MAGIC %md
# MAGIC # 01 — Setup Environment
# MAGIC
# MAGIC This notebook installs dbt with the Databricks adapter and verifies the connection.
# MAGIC Run this once before anything else.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Install dbt-databricks

# COMMAND ----------

# MAGIC %pip install dbt-core dbt-databricks --quiet

# COMMAND ----------

# Restart Python to pick up newly installed packages
dbutils.library.restartPython()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Verify Installation

# COMMAND ----------

import subprocess
result = subprocess.run(["dbt", "--version"], capture_output=True, text=True)
print(result.stdout)
print(result.stderr)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Create Database Schemas
# MAGIC
# MAGIC We'll use three schemas mirroring our dbt layers:
# MAGIC - `raw`  — raw ingested data (loaded by PySpark)
# MAGIC - `staging` — cleaned staging models (dbt)
# MAGIC - `intermediate` — joined intermediate models (dbt)
# MAGIC - `marts` — final analytics-ready tables (dbt)

# COMMAND ----------

spark.sql("CREATE DATABASE IF NOT EXISTS raw COMMENT 'Raw ingested data from CSV sources'")
spark.sql("CREATE DATABASE IF NOT EXISTS staging COMMENT 'Cleaned and typed staging models'")
spark.sql("CREATE DATABASE IF NOT EXISTS intermediate COMMENT 'Joined intermediate models'")
spark.sql("CREATE DATABASE IF NOT EXISTS marts COMMENT 'Final analytics mart tables'")

print("✅ All schemas created successfully")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Get Databricks Connection Details for dbt
# MAGIC
# MAGIC You'll need these values to fill in `profiles.yml`.

# COMMAND ----------

# Get the current cluster's HTTP path for dbt profiles.yml
import json

ctx = dbutils.notebook.entry_point.getDbutils().notebook().getContext()
host = ctx.browserHostName().get()
token = ctx.apiToken().get()

print("=" * 60)
print("Add these values to your dbt profiles.yml:")
print("=" * 60)
print(f"host: {host}")
print(f"http_path: <find in Cluster > Advanced Options > JDBC/ODBC>")
print(f"token: {token}")
print("=" * 60)
print("\n⚠️  Never commit your token to GitHub! Use environment variables.")
