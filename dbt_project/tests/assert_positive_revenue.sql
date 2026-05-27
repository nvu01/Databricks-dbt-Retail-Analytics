-- tests/assert_positive_revenue.sql
-- Custom singular test: asserts there are no rows with negative revenue
-- in the sales summary mart. Returns rows that FAIL the test (dbt convention).

select
    order_year,
    order_month,
    total_revenue_usd
from {{ ref('mart_sales_summary') }}
where total_revenue_usd < 0
