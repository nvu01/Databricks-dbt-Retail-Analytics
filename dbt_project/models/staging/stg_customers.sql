-- models/staging/stg_customers.sql
-- Cleans the raw customers table.
-- Standardizes state codes and trims whitespace.

with source as (
    select * from raw.customers
),

cleaned as (
    select
        customer_id,
        customer_unique_id,             -- true unique customer (can have multiple orders)
        trim(customer_zip_code_prefix)  as zip_code,
        initcap(trim(customer_city))    as city,
        upper(trim(customer_state))     as state_code
    from source
    where customer_id is not null
      and customer_unique_id is not null
)

select * from cleaned
