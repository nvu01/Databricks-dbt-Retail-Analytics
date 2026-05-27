# Databricks notebook source
# MAGIC %md
# MAGIC # 03 — Run dbt Models & Validate Results
# MAGIC
# MAGIC This notebook runs the full dbt project and validates the output.
# MAGIC Make sure you've completed notebooks 01 and 02 first.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup: Write dbt Project to Driver

# COMMAND ----------

import os
import subprocess

# Write the profiles.yml to the default dbt location
# In production you'd use environment variables or Databricks secrets
os.makedirs("/root/.dbt", exist_ok=True)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Run dbt Commands

# COMMAND ----------

def run_dbt(command: str):
    """Run a dbt command from the dbt_project directory and print output."""
    project_dir = "/Workspace/retail_analytics/dbt_project"  # adjust if needed
    result = subprocess.run(
        f"cd {project_dir} && dbt {command}",
        shell=True,
        capture_output=True,
        text=True
    )
    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)
    return result.returncode

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1. Check dbt connection

# COMMAND ----------

run_dbt("debug")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2. Install dbt packages

# COMMAND ----------

run_dbt("deps")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3. Run all models (staging → intermediate → marts)

# COMMAND ----------

run_dbt("run")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4. Run all dbt tests

# COMMAND ----------

run_dbt("test")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 5. Generate and serve docs (optional)

# COMMAND ----------

run_dbt("docs generate")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Validate Mart Tables

# COMMAND ----------

# MAGIC %md ### Sales Summary

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT
# MAGIC   order_year,
# MAGIC   order_month,
# MAGIC   total_orders,
# MAGIC   total_revenue_usd,
# MAGIC   avg_order_value_usd
# MAGIC FROM marts.mart_sales_summary
# MAGIC ORDER BY order_year, order_month

# COMMAND ----------

# MAGIC %md ### Category Performance

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT *
# MAGIC FROM marts.mart_category_performance
# MAGIC ORDER BY total_revenue_usd DESC
# MAGIC LIMIT 10

# COMMAND ----------

# MAGIC %md ### Customer Segments

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT
# MAGIC   customer_segment,
# MAGIC   COUNT(*) AS customer_count,
# MAGIC   ROUND(AVG(total_spent_usd), 2) AS avg_spend,
# MAGIC   ROUND(AVG(total_orders), 1) AS avg_orders
# MAGIC FROM marts.mart_customer_segments
# MAGIC GROUP BY customer_segment
# MAGIC ORDER BY avg_spend DESC

# COMMAND ----------

# MAGIC %md
# MAGIC ## Quick Sanity Checks

# COMMAND ----------

checks = {
    "mart_sales_summary row count":       "SELECT COUNT(*) FROM marts.mart_sales_summary",
    "mart_category_performance row count": "SELECT COUNT(*) FROM marts.mart_category_performance",
    "mart_customer_segments row count":    "SELECT COUNT(*) FROM marts.mart_customer_segments",
    "Any null revenue in summary":         "SELECT COUNT(*) FROM marts.mart_sales_summary WHERE total_revenue_usd IS NULL",
    "Any negative revenue":                "SELECT COUNT(*) FROM marts.mart_sales_summary WHERE total_revenue_usd < 0",
}

print("📋 Sanity Check Results:")
print("-" * 55)
for label, query in checks.items():
    result = spark.sql(query).collect()[0][0]
    status = "✅" if (result > 0 if "count" in label.lower() and "null" not in label.lower() and "negative" not in label.lower() else result == 0) else "⚠️"
    print(f"  {status}  {label:<40} {result:>8,}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## ✅ Pipeline Complete!
# MAGIC
# MAGIC Your mart tables are ready. Head to Databricks SQL to build your dashboard
# MAGIC using the queries in `dashboard/databricks_sql_queries.sql`.
