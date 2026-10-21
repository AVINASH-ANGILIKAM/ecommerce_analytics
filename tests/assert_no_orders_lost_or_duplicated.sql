/*
  Singular test: proves no order was silently lost or doubled on the way
  from raw -> stg_orders -> fct_sales.

  How a singular test works: dbt runs this query.
    0 rows returned  -> PASS
    1+ rows returned -> FAIL (the rows show what went wrong)

  Expected with your data: 20 everywhere
    (raw rows, distinct raw order IDs, staged orders, staged rows added
    back up with source_row_count, and fct_sales).
*/

with raw_counts as (

    select
        count(*)                    as raw_rows,
        count(distinct order_id)    as raw_distinct_orders
    from {{ source('raw', 'raw_orders') }}

),

staging_counts as (

    select
        count(*)                    as staged_orders,
        sum(source_row_count)       as staged_source_rows
    from {{ ref('stg_orders') }}

),

fact_counts as (

    select count(*)                 as fact_orders
    from {{ ref('fct_sales') }}

)

select *
from raw_counts
cross join staging_counts
cross join fact_counts
where raw_rows            <> staged_source_rows   -- every raw row is accounted for
   or raw_distinct_orders <> staged_orders        -- one staging row per order ID
   or staged_orders       <> fact_orders          -- joins didn't drop or repeat orders