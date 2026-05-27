-- models/intermediate/int_order_payments.sql
-- Enriches payment records with order metadata.
-- One row per payment (orders with split payments have multiple rows).

with payments as (
    select * from {{ ref('stg_payments') }}
),

orders as (
    select
        order_id,
        order_date,
        order_year,
        order_month,
        order_status
    from {{ ref('stg_orders') }}
)

select
    p.order_id,
    p.payment_sequence,
    p.payment_type,
    p.installments,
    p.payment_amount_usd,

    o.order_date,
    o.order_year,
    o.order_month,
    o.order_status

from payments p
left join orders o
    on p.order_id = o.order_id
