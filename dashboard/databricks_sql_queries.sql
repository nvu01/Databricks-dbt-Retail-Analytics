-- dashboard/databricks_sql_queries.sql
-- Copy each query block into Databricks SQL to build your dashboard.
-- Each query corresponds to one visualization tile.

-- ─────────────────────────────────────────────────────────────────
-- TILE 1: Monthly Revenue Trend (Line Chart)
-- X-axis: month_start | Y-axis: total_revenue_usd
-- ─────────────────────────────────────────────────────────────────
SELECT
    month_start,
    total_revenue_usd,
    total_orders,
    avg_order_value_usd
FROM marts.mart_sales_summary
ORDER BY month_start;


-- ─────────────────────────────────────────────────────────────────
-- TILE 2: Top 10 Product Categories by Revenue (Bar Chart)
-- X-axis: category_name | Y-axis: total_revenue_usd
-- ─────────────────────────────────────────────────────────────────
SELECT
    category_name,
    total_revenue_usd,
    total_orders,
    avg_item_price_usd,
    revenue_rank
FROM marts.mart_category_performance
WHERE revenue_rank <= 10
ORDER BY revenue_rank;


-- ─────────────────────────────────────────────────────────────────
-- TILE 3: Customer Segment Breakdown (Pie / Donut Chart)
-- Dimension: customer_segment | Measure: customer_count
-- ─────────────────────────────────────────────────────────────────
SELECT
    customer_segment,
    COUNT(*)                            AS customer_count,
    ROUND(AVG(total_spent_usd), 2)      AS avg_lifetime_value,
    ROUND(AVG(total_orders), 1)         AS avg_orders,
    SUM(total_spent_usd)                AS segment_total_revenue
FROM marts.mart_customer_segments
GROUP BY customer_segment
ORDER BY avg_lifetime_value DESC;


-- ─────────────────────────────────────────────────────────────────
-- TILE 4: Average Delivery Time by State (Table / Heatmap)
-- ─────────────────────────────────────────────────────────────────
SELECT
    customer_state,
    COUNT(*)                                AS total_customers,
    ROUND(AVG(avg_days_to_deliver), 1)      AS avg_delivery_days,
    ROUND(AVG(total_spent_usd), 2)          AS avg_customer_spend
FROM marts.mart_customer_segments
WHERE avg_days_to_deliver IS NOT NULL
GROUP BY customer_state
ORDER BY avg_delivery_days ASC;


-- ─────────────────────────────────────────────────────────────────
-- TILE 5: Payment Method Mix Over Time (Stacked Bar)
-- ─────────────────────────────────────────────────────────────────
SELECT
    month_start,
    credit_card_revenue,
    boleto_revenue,
    voucher_revenue,
    debit_card_revenue,
    total_revenue_usd
FROM marts.mart_sales_summary
ORDER BY month_start;


-- ─────────────────────────────────────────────────────────────────
-- TILE 6: KPI Counters (Single Value Tiles)
-- ─────────────────────────────────────────────────────────────────

-- Total Revenue
SELECT ROUND(SUM(total_revenue_usd), 2) AS total_revenue_all_time
FROM marts.mart_sales_summary;

-- Total Orders
SELECT SUM(total_orders) AS total_orders_all_time
FROM marts.mart_sales_summary;

-- Repeat Customer Rate
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN is_repeat_buyer THEN 1 ELSE 0 END) / COUNT(*), 1
    ) AS repeat_customer_pct
FROM marts.mart_customer_segments;

-- Average Delivery Days (all time)
SELECT
    ROUND(AVG(avg_days_to_deliver), 1) AS overall_avg_delivery_days
FROM marts.mart_customer_segments
WHERE avg_days_to_deliver IS NOT NULL;

-- On-Time Delivery Rate
SELECT
    ROUND(AVG(on_time_pct), 1) AS avg_on_time_delivery_pct
FROM marts.mart_sales_summary;
