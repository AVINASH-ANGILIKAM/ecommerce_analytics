/*
  Singular test: for every month, agg_monthly_sales revenue must equal a
  calculation done straight from the RAW table (worksheet check 8g).

  Two different routes to the same answer:
    source route: RAW_ORDERS -> remove exact duplicates -> COMPLETED only -> sum by month
    model route : raw -> stg_orders -> fct_sales -> agg_monthly_sales
  If they ever disagree, a model has a bug. Returns the months that disagree.
*/

with source_calculation as (

    select
        date_trunc('month', order_date)     as order_month,
        sum(total_amount)                   as source_revenue
    from (
        select distinct *                   -- exact duplicate rows count once
        from {{ source('raw', 'raw_orders') }}
    ) as raw_distinct
    where upper(trim(order_status)) = 'COMPLETED'
    group by date_trunc('month', order_date)

),

model as (

    select
        order_month,
        revenue                             as model_revenue
    from {{ ref('agg_monthly_sales') }}

)

-- FULL OUTER JOIN keeps months that exist on only one side, so a missing month is caught too
select
    coalesce(s.order_month, m.order_month)  as order_month,
    s.source_revenue,
    m.model_revenue
from source_calculation as s
full outer join model as m
    on s.order_month = m.order_month
where coalesce(s.source_revenue, 0) <> coalesce(m.model_revenue, 0)