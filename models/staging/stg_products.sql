/*
  stg_products  —  staging model for products.
  One row per product. Same 20 rows as RAW_PRODUCTS, tidied up.
*/

with source as (

    select * from {{ source('raw', 'raw_products') }}

),

cleaned as (

    select
        cast(product_id as integer)     as product_id,     -- e.g. 209
        trim(product_name)              as product_name,   -- e.g. Laptop
        trim(category)                  as category        -- e.g. Electronics
    from source

)

select * from cleaned