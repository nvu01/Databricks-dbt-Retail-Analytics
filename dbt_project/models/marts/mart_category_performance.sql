-- models/marts/mart_category_performance.sql
-- Revenue and volume metrics broken down by product category.
-- Used for the "Top Categories" dashboard tile.

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

orders as (
    select order_id, order_status, order_year, order_month
    from {{ ref('stg_orders') }}
    where order_status = 'delivered'
),

-- Join items to products and filter to delivered orders
enriched_items as (
    select
        oi.order_id,
        oi.item_price_usd,
        oi.freight_usd,
        oi.item_total_usd,
        p.category_name,
        o.order_year,
        o.order_month
    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id
    left join products p
        on oi.product_id = p.product_id
),

aggregated as (
    select
        category_name,
        count(distinct order_id)        as total_orders,
        count(*)                        as total_items_sold,
        round(sum(item_price_usd), 2)   as total_revenue_usd,
        round(avg(item_price_usd), 2)   as avg_item_price_usd,
        round(sum(freight_usd), 2)      as total_freight_usd,
        round(avg(freight_usd), 2)      as avg_freight_usd,
        round(
            100.0 * sum(freight_usd) / nullif(sum(item_price_usd), 0), 1
        )                               as freight_as_pct_of_revenue
    from enriched_items
    group by category_name
),

-- Add revenue rank
ranked as (
    select
        *,
        row_number() over (order by total_revenue_usd desc) as revenue_rank
    from aggregated
)

select * from ranked
order by revenue_rank
