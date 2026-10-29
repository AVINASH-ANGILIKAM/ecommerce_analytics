/*
  row_count_reconciliation  —  Step 9: "Check row counts and monthly/product totals."
  Shows the number of orders at every stage of the pipeline, side by side.
  Run it the same way as revenue_reconciliation: open it in dbt Cloud and click Preview.
*/

select 1 as step, 'raw_orders: rows' as check_name, count(*) as row_count
from {{ source('raw', 'raw_orders') }}

union all
select 2, 'raw_orders: distinct order IDs', count(distinct order_id)
from {{ source('raw', 'raw_orders') }}

union all
select 3, 'stg_orders: rows (one per order)', count(*)
from {{ ref('stg_orders') }}

union all
select 4, 'stg_orders: SUM(source_row_count), should equal step 1', sum(source_row_count)
from {{ ref('stg_orders') }}

union all
select 5, 'fct_sales: rows, should equal step 3', count(*)
from {{ ref('fct_sales') }}

union all
select 6, 'agg_monthly_sales: SUM(total_orders), should equal step 3', sum(total_orders)
from {{ ref('agg_monthly_sales') }}

union all
select 7, 'agg_product_sales: SUM(total_orders), should equal step 3', sum(total_orders)
from {{ ref('agg_product_sales') }}

union all
select 8, 'fct_sales: orders with no valid customer (kept, flagged)',
       sum(case when has_valid_customer then 0 else 1 end)
from {{ ref('fct_sales') }}

order by step
