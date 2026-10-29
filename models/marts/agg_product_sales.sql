/*
  agg_product_sales  —  aggregate table: one row per product.
  Answers "Which products generate the most sales?"

  revenue_rank: 1 = the product that earned the most.

  No ORDER BY here: a stored table has no guaranteed row order in Snowflake.
  Sort when you read it (in a query, or in Tableau).
*/

with sales as (

    select * from {{ ref('fct_sales') }}

)

select
    product_id,
    product_name,
    product_category,
    count(*)                    as total_orders,      -- every status
    sum(case when is_revenue then 1 else 0 end)
                                as completed_orders,  -- only COMPLETED
    sum(revenue_amount)         as revenue,           -- GBP, COMPLETED orders only
    rank() over (order by sum(revenue_amount) desc)
                                as revenue_rank
from sales
group by product_id, product_name, product_category
