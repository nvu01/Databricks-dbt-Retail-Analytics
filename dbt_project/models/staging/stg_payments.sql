-- models/staging/stg_payments.sql
-- Cleans the raw order payments table.

with source as (
    select * from raw.order_payments
),

cleaned as (
    select
        order_id,
        cast(payment_sequential    as int)    as payment_sequence,
        payment_type,
        cast(payment_installments  as int)    as installments,
        {{ cents_to_dollars('payment_value') }} as payment_amount_usd
    from source
    where order_id is not null
      and payment_value is not null
      and cast(payment_value as double) >= 0
)

select * from cleaned
