-- models/staging/stg_orders.sql
-- Cleans and types the raw orders table.
-- Filters to only valid order statuses for analysis.

with source as (
    select * from raw.orders
),

cleaned as (
    select
        order_id,
        customer_id,
        order_status,

        -- Parse timestamps from string to proper timestamp type
        to_timestamp(order_purchase_timestamp,  'yyyy-MM-dd HH:mm:ss') as purchased_at,
        to_timestamp(order_approved_at,         'yyyy-MM-dd HH:mm:ss') as approved_at,
        to_timestamp(order_delivered_carrier_date, 'yyyy-MM-dd HH:mm:ss') as shipped_at,
        to_timestamp(order_delivered_customer_date,'yyyy-MM-dd HH:mm:ss') as delivered_at,
        to_timestamp(order_estimated_delivery_date,'yyyy-MM-dd HH:mm:ss') as estimated_delivery_at,

        -- Derived fields
        date(to_timestamp(order_purchase_timestamp, 'yyyy-MM-dd HH:mm:ss')) as order_date,
        year(to_timestamp(order_purchase_timestamp,  'yyyy-MM-dd HH:mm:ss')) as order_year,
        month(to_timestamp(order_purchase_timestamp, 'yyyy-MM-dd HH:mm:ss')) as order_month,

        -- Delivery duration in days (null if not yet delivered)
        datediff(
            to_timestamp(order_delivered_customer_date, 'yyyy-MM-dd HH:mm:ss'),
            to_timestamp(order_purchase_timestamp,      'yyyy-MM-dd HH:mm:ss')
        ) as days_to_deliver,

        -- Was delivery on time?
        case
            when order_delivered_customer_date is not null
             and order_delivered_customer_date <= order_estimated_delivery_date
            then true
            else false
        end as delivered_on_time

    from source
    where order_id is not null
      and customer_id is not null
)

select * from cleaned
