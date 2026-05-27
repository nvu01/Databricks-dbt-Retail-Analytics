# Retail Sales Analytics Pipeline

An end-to-end data engineering and analytics project built on **Databricks**, **Delta Lake**, and **dbt** using the [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

## Architecture

```
Raw CSV Files (Kaggle)
        │
        ▼
┌───────────────────┐
│   Databricks      │  ← Load CSVs into raw Delta tables
│   (PySpark)       │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│   dbt             │  ← Transform: staging → intermediate → marts
│   (SQL models)    │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Databricks SQL    │  ← Dashboard: revenue, categories, delivery
│ Dashboard         │
└───────────────────┘
```

## Project Structure

```
retail_analytics/
├── README.md
├── notebooks/
│   ├── 01_setup_environment.py       # Install dbt, configure connections
│   ├── 02_load_raw_data.py           # Load CSVs → raw Delta tables
│   └── 03_run_dbt_and_validate.py    # Run dbt models + view results
├── dbt_project/
│   ├── dbt_project.yml               # dbt project config
│   ├── profiles.yml                  # Databricks connection config
│   ├── models/
│   │   ├── staging/                  # Clean raw tables
│   │   │   ├── stg_orders.sql
│   │   │   ├── stg_customers.sql
│   │   │   ├── stg_products.sql
│   │   │   ├── stg_payments.sql
│   │   │   ├── stg_order_items.sql
│   │   │   └── schema.yml
│   │   ├── intermediate/             # Join staging models
│   │   │   ├── int_orders_enriched.sql
│   │   │   ├── int_order_payments.sql
│   │   │   └── schema.yml
│   │   └── marts/                    # Final analytics tables
│   │       ├── mart_sales_summary.sql
│   │       ├── mart_customer_segments.sql
│   │       ├── mart_category_performance.sql
│   │       └── schema.yml
│   ├── tests/
│   │   └── assert_positive_revenue.sql
│   └── macros/
│       └── cents_to_dollars.sql
└── dashboard/
    └── databricks_sql_queries.sql    # All dashboard queries
```

## Getting Started

### Prerequisites
- Databricks Community Edition account (free): https://community.cloud.databricks.com
- Kaggle account to download dataset (free)
- Python 3.8+

### Step 1: Download the Dataset
1. Go to https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Download and unzip the dataset
3. You'll need these files:
   - `olist_orders_dataset.csv`
   - `olist_customers_dataset.csv`
   - `olist_products_dataset.csv`
   - `olist_order_payments_dataset.csv`
   - `olist_order_items_dataset.csv`
   - `olist_sellers_dataset.csv`

### Step 2: Upload to Databricks
1. In Databricks, go to **Data > Add Data > Upload File**
2. Upload all 6 CSV files to DBFS

### Step 3: Run Notebooks in Order
Open each notebook in `notebooks/` and run them in sequence:
1. `01_setup_environment.py`: installs dbt and configures the connection
2. `02_load_raw_data.py`: creates raw Delta tables from CSVs
3. `03_run_dbt_and_validate.py`: runs all dbt models and tests

### Step 4: Build the Dashboard
Copy queries from `dashboard/databricks_sql_queries.sql` into Databricks SQL and create visualizations.

## Business Questions Answered

| Question | Mart Table |
|---|---|
| What is monthly revenue trend? | `mart_sales_summary` |
| Which product categories perform best? | `mart_category_performance` |
| How many customers are repeat buyers? | `mart_customer_segments` |
| What is average delivery time by state? | `mart_sales_summary` |
| What payment methods are most common? | `mart_sales_summary` |

## Data Quality Tests

dbt tests are defined in each `schema.yml` file:
- **Uniqueness**: primary keys are unique
- **Not null**: critical fields are never null
- **Accepted values**: order statuses are valid
- **Relationships**: foreign keys exist in parent tables
- **Custom test**: revenue is always positive

## Tech Stack

| Tool | Purpose |
|---|---|
| Databricks Community Edition | Compute + storage |
| Apache Spark (PySpark) | Data ingestion |
| Delta Lake | Storage format (ACID, time travel) |
| dbt Core + dbt-databricks | Data transformation |
| Databricks SQL | Dashboarding |


