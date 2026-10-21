/*
  revenue_reconciliation  —  Step 9 of the guide: "Compare prepared-model revenue
  with the source calculation... explain differences caused by filters,
  duplicates, returns, or cancelled orders."

  This is an ANALYSIS, not a model: dbt never builds it into a table.
  How to run it in dbt Cloud: open this file and click Preview.

  Read the result top to bottom, like a bank statement: it walks from ALL the
  money in the raw table down to revenue, explaining every step.
*/

with raw_data as (

    select * from {{ source('raw', 'raw_orders') }}

),

stg as (

    select * from {{ ref('stg_orders') }}

),

bridge as (

    -- Part 1: from every pound in RAW_ORDERS down to revenue
    select 1 as step, 'Raw: total_amount of ALL rows, every status' as line,
           sum(total_amount) as amount_gbp
    from raw_data

    union all
    select 2, 'minus: extra copies of duplicated orders (counted once)',
           -coalesce(sum(total_amount * (source_row_count - 1)), 0)
    from stg

    union all
    select 3, '= Staging: all orders, every status', sum(total_amount)
    from stg

    -- one line for each status that is NOT revenue (SHIPPED, PENDING, CANCELLED)
    union all
    select 4, 'minus: ' || order_status || ' orders (not revenue)', -sum(total_amount)
    from stg
    where order_status <> 'COMPLETED'
    group by order_status

    union all
    select 5, '= Expected revenue: COMPLETED orders only',
           sum(case when order_status = 'COMPLETED' then total_amount else 0 end)
    from stg

    -- Part 2: the report-ready models must all show the step 5 number
    union all
    select 6, 'Model: fct_sales, SUM(revenue_amount)', sum(revenue_amount)
    from {{ ref('fct_sales') }}

    union all
    select 7, 'Model: agg_monthly_sales, SUM(revenue)', sum(revenue)
    from {{ ref('agg_monthly_sales') }}

    union all
    select 8, 'Model: agg_product_sales, SUM(revenue)', sum(revenue)
    from {{ ref('agg_product_sales') }}

    -- Part 3: why the guide's example query (status = 'COMPLETED') gives a different number
    union all
    select 9, 'Guide example on raw: status exactly COMPLETED (capitals)',
           coalesce(sum(total_amount), 0)
    from raw_data
    where order_status = 'COMPLETED'

    union all
    select 10, 'plus: completed orders not written in capitals (e.g. Completed)',
           coalesce(sum(total_amount), 0)
    from raw_data
    where order_status <> 'COMPLETED'
      and upper(trim(order_status)) = 'COMPLETED'

    union all
    select 11, 'minus: extra copies of duplicated COMPLETED orders',
           -coalesce(sum(total_amount * (source_row_count - 1)), 0)
    from stg
    where order_status = 'COMPLETED'

)

select step, line, amount_gbp
from bridge
order by step, line