-- models/intermediate/int_orders_enriched.sql
-- Joins orders to customers and aggregates order-level item/payment totals.
-- One row per order.

with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

-- Aggregate items to order level
order_item_totals as (
    select
        order_id,
        count(*)                    as item_count,
        sum(item_price_usd)         as items_subtotal_usd,
        sum(freight_usd)            as total_freight_usd,
        sum(item_total_usd)         as order_gross_usd
    from {{ ref('stg_order_items') }}
    group by order_id
),

-- Aggregate payments to order level (handles split payments)
order_payment_totals as (
    select
        order_id,
        sum(payment_amount_usd)                                     as total_paid_usd,
        count(distinct payment_type)                                as payment_method_count,
        max(case when payment_type = 'credit_card' then 1 else 0 end) as used_credit_card,
        max(installments)                                           as max_installments
    from {{ ref('stg_payments') }}
    group by order_id
),

joined as (
    select
        o.order_id,
        o.customer_id,
        o.order_status,
        o.purchased_at,
        o.order_date,
        o.order_year,
        o.order_month,
        o.days_to_deliver,
        o.delivered_on_time,

        -- Customer geography
        c.customer_unique_id,
        c.city             as customer_city,
        c.state_code       as customer_state,

        -- Item metrics
        coalesce(it.item_count, 0)          as item_count,
        coalesce(it.items_subtotal_usd, 0)  as items_subtotal_usd,
        coalesce(it.total_freight_usd, 0)   as total_freight_usd,
        coalesce(it.order_gross_usd, 0)     as order_gross_usd,

        -- Payment metrics
        coalesce(pt.total_paid_usd, 0)          as total_paid_usd,
        coalesce(pt.payment_method_count, 0)    as payment_method_count,
        coalesce(pt.used_credit_card, 0)        as used_credit_card,
        coalesce(pt.max_installments, 1)        as max_installments

    from orders o
    left join customers c
        on o.customer_id = c.customer_id
    left join order_item_totals it
        on o.order_id = it.order_id
    left join order_payment_totals pt
        on o.order_id = pt.order_id
)

select * from joined
