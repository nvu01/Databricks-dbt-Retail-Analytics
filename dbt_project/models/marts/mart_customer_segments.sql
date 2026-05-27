-- models/marts/mart_customer_segments.sql
-- Customer-level aggregation with RFM-inspired segmentation.
-- Segments: Champion, Loyal, At Risk, New, One-Time

with orders as (
    select * from {{ ref('int_orders_enriched') }}
    where order_status = 'delivered'
),

-- Aggregate to unique customer level
customer_stats as (
    select
        customer_unique_id,
        customer_state,
        customer_city,

        count(distinct order_id)                    as total_orders,
        sum(order_gross_usd)                        as total_spent_usd,
        avg(order_gross_usd)                        as avg_order_value_usd,
        min(order_date)                             as first_order_date,
        max(order_date)                             as last_order_date,
        avg(days_to_deliver)                        as avg_days_to_deliver,
        sum(case when delivered_on_time then 1 else 0 end) as on_time_orders,
        avg(item_count)                             as avg_items_per_order,

        -- Days since most recent order (relative to latest date in dataset)
        datediff(
            max(max(order_date)) over (),
            max(order_date)
        )                                           as days_since_last_order

    from orders
    group by customer_unique_id, customer_state, customer_city
),

-- Apply simple segmentation logic
segmented as (
    select
        *,
        case
            when total_orders >= 3 and days_since_last_order <= 90
                then 'Champion'
            when total_orders >= 2 and days_since_last_order <= 180
                then 'Loyal'
            when total_orders >= 2 and days_since_last_order > 180
                then 'At Risk'
            when total_orders = 1 and days_since_last_order <= 90
                then 'New'
            else 'One-Time'
        end as customer_segment,

        case
            when total_orders = 1  then false
            else true
        end as is_repeat_buyer
    from customer_stats
)

select
    customer_unique_id,
    customer_state,
    customer_city,
    customer_segment,
    is_repeat_buyer,
    total_orders,
    round(total_spent_usd, 2)           as total_spent_usd,
    round(avg_order_value_usd, 2)       as avg_order_value_usd,
    first_order_date,
    last_order_date,
    days_since_last_order,
    round(avg_days_to_deliver, 1)       as avg_days_to_deliver,
    on_time_orders,
    round(avg_items_per_order, 1)       as avg_items_per_order
from segmented
