-- models/staging/stg_order_items.sql
-- Cleans the raw order items table.
-- Each row is one product within one order.

with source as (
    select * from raw.order_items
),

cleaned as (
    select
        order_id,
        cast(order_item_id   as int)    as item_sequence,   -- 1 = first item, 2 = second, etc.
        product_id,
        seller_id,
        to_timestamp(shipping_limit_date, 'yyyy-MM-dd HH:mm:ss') as shipping_deadline,
        {{ cents_to_dollars('price') }}         as item_price_usd,
        {{ cents_to_dollars('freight_value') }} as freight_usd,
        {{ cents_to_dollars('price') }} + {{ cents_to_dollars('freight_value') }} as item_total_usd
    from source
    where order_id is not null
      and product_id is not null
)

select * from cleaned
