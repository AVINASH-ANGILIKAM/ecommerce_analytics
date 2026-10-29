/*
  agg_monthly_sales  —  "agg" = aggregate: a summary table, already grouped.
  One row per month. Answers "What are the monthly sales trends?"

  Built from fct_sales, so it uses the exact same revenue definition.
  Example: if the revenue rule ever changes (say PENDING starts counting),
  we change fct_sales once, and this table follows on the next run.
*/

with sales as (

    select * from {{ ref('fct_sales') }}

)

select
    order_month,
    count(*)                    as total_orders,      -- every status
    sum(case when is_revenue then 1 else 0 end)
                                as completed_orders,  -- only COMPLETED
    sum(revenue_amount)         as revenue            -- GBP, COMPLETED orders only
from sales
group by order_month
