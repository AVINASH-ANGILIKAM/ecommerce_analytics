/*
  stg_orders  —  staging model for orders.
  One row per order.

  Cleaning rules applied here (see docs/data_dictionary.md):
    1. Status in capitals:   'Completed' -> 'COMPLETED', 'Shipped' -> 'SHIPPED'
       so every model can compare with one spelling.
    2. Exact duplicate rows count once. Your data has none today, but if the
       same order were ever loaded twice, it would be combined here.

  The guide says "do not silently remove records". So when duplicates are
  combined, source_row_count records how many raw rows became this one row.
  Example: today every order has source_row_count = 1. If order 105 were
  loaded twice, it would appear once here with source_row_count = 2.
*/

with source as (

    select * from {{ source('raw', 'raw_orders') }}

),

cleaned as (

    select
        cast(order_id as integer)           as order_id,
        cast(customer_id as integer)        as customer_id,    -- who bought  (links to stg_customers)
        cast(product_id as integer)         as product_id,     -- what they bought (links to stg_products)
        cast(order_date as date)            as order_date,
        upper(trim(order_status))           as order_status,   -- 'Completed' -> 'COMPLETED'
        cast(total_amount as number(10, 2)) as total_amount    -- money: 2 decimal places
    from source

),

deduplicated as (

    -- GROUP BY every column: rows that are identical in ALL columns become one row.
    -- If two rows ever shared an order_id but differed in any column (for example
    -- a different amount), they would stay as 2 rows. The unique test on order_id
    -- then FAILS and stops the run. That's deliberate: dbt shouldn't guess which
    -- version is right. A person checks with the source owner.
    select
        order_id,
        customer_id,
        product_id,
        order_date,
        order_status,
        total_amount,
        count(*) as source_row_count
    from cleaned
    group by
        order_id,
        customer_id,
        product_id,
        order_date,
        order_status,
        total_amount

)

select * from deduplicated