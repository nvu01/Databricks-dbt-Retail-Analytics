-- models/marts/mart_sales_summary.sql
-- Monthly sales summary with revenue, order volume, delivery, and payment metrics.
-- Primary table for the revenue trend dashboard tile.

with orders as (
    select * from {{ ref('int_orders_enriched') }}
    where order_status = 'delivered'   -- only count completed orders in revenue
),

payments as (
    select * from {{ ref('int_order_payments') }}
    where order_status = 'delivered'
),

monthly_orders as (
    select
        order_year,
        order_month,
        date_trunc('month', order_date)                 as month_start,

        count(distinct order_id)                        as total_orders,
        count(distinct customer_unique_id)              as unique_customers,
        sum(order_gross_usd)                            as total_revenue_usd,
        avg(order_gross_usd)                            as avg_order_value_usd,
        sum(total_freight_usd)                          as total_freight_usd,
        avg(total_freight_usd)                          as avg_freight_usd,

        -- Delivery metrics
        avg(days_to_deliver)                            as avg_days_to_deliver,
        sum(case when delivered_on_time then 1 else 0 end) as on_time_deliveries,
        round(
            100.0 * sum(case when delivered_on_time then 1 else 0 end)
            / nullif(count(*), 0), 1
        )                                               as on_time_pct,

        -- Basket size
        avg(item_count)                                 as avg_items_per_order,

        -- Credit card usage
        round(
            100.0 * sum(used_credit_card) / nullif(count(*), 0), 1
        )                                               as credit_card_pct

    from orders
    group by order_year, order_month, date_trunc('month', order_date)
),

-- Payment method breakdown per month
monthly_payment_methods as (
    select
        order_year,
        order_month,
        payment_type,
        count(distinct order_id)        as orders_using_method,
        sum(payment_amount_usd)         as revenue_by_method
    from payments
    group by order_year, order_month, payment_type
),

-- Pivot top payment types
payment_pivot as (
    select
        order_year,
        order_month,
        sum(case when payment_type = 'credit_card' then revenue_by_method else 0 end) as credit_card_revenue,
        sum(case when payment_type = 'boleto'      then revenue_by_method else 0 end) as boleto_revenue,
        sum(case when payment_type = 'voucher'     then revenue_by_method else 0 end) as voucher_revenue,
        sum(case when payment_type = 'debit_card'  then revenue_by_method else 0 end) as debit_card_revenue
    from monthly_payment_methods
    group by order_year, order_month
)

select
    mo.order_year,
    mo.order_month,
    mo.month_start,
    mo.total_orders,
    mo.unique_customers,
    round(mo.total_revenue_usd, 2)      as total_revenue_usd,
    round(mo.avg_order_value_usd, 2)    as avg_order_value_usd,
    round(mo.total_freight_usd, 2)      as total_freight_usd,
    round(mo.avg_freight_usd, 2)        as avg_freight_usd,
    round(mo.avg_days_to_deliver, 1)    as avg_days_to_deliver,
    mo.on_time_deliveries,
    mo.on_time_pct,
    round(mo.avg_items_per_order, 1)    as avg_items_per_order,
    mo.credit_card_pct,
    round(pp.credit_card_revenue, 2)    as credit_card_revenue,
    round(pp.boleto_revenue, 2)         as boleto_revenue,
    round(pp.voucher_revenue, 2)        as voucher_revenue,
    round(pp.debit_card_revenue, 2)     as debit_card_revenue
from monthly_orders mo
left join payment_pivot pp
    on mo.order_year  = pp.order_year
    and mo.order_month = pp.order_month
order by mo.order_year, mo.order_month
