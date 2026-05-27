-- models/staging/stg_products.sql
-- Cleans the raw products table.
-- Normalizes category names and handles nulls.

with source as (
    select * from raw.products
),

cleaned as (
    select
        product_id,

        -- Clean up category names: replace underscores, title case
        initcap(replace(
            coalesce(product_category_name, 'uncategorized'),
            '_', ' '
        )) as category_name,

        -- Physical dimensions (nullable)
        cast(product_weight_g        as double) as weight_grams,
        cast(product_length_cm       as double) as length_cm,
        cast(product_height_cm       as double) as height_cm,
        cast(product_width_cm        as double) as width_cm,

        -- Calculated volume
        cast(product_length_cm as double)
            * cast(product_height_cm as double)
            * cast(product_width_cm  as double) as volume_cm3,

        cast(product_photos_qty as int) as photo_count,
        cast(product_name_lenght as int) as name_length,        -- note: source typo preserved
        cast(product_description_lenght as int) as desc_length  -- note: source typo preserved

    from source
    where product_id is not null
)

select * from cleaned
