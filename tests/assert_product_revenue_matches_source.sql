/*
  Singular test: for every product, agg_product_sales revenue must equal a
  calculation done straight from the RAW table (worksheet check 8i).
  Returns the products that disagree.
*/

with source_calculation as (

    select
        product_id,
        sum(total_amount)                   as source_revenue
    from (
        select distinct *
        from {{ source('raw', 'raw_orders') }}
    ) as raw_distinct
    where upper(trim(order_status)) = 'COMPLETED'
    group by product_id

),

model as (

    select
        product_id,
        revenue                             as model_revenue
    from {{ ref('agg_product_sales') }}

)

select
    coalesce(s.product_id, m.product_id)    as product_id,
    s.source_revenue,
    m.model_revenue
from source_calculation as s
full outer join model as m
    on s.product_id = m.product_id
where coalesce(s.source_revenue, 0) <> coalesce(m.model_revenue, 0)