/*
  fct_sales  —  "fct" = fact table: one row per business event, with the numbers to add up.
  Here the event is an order. One row per order, ALL statuses (20 rows).

  Why keep shipped, pending and cancelled orders in a sales table?
  So every raw order can be traced here (nothing silently dropped), and so the
  dashboard can also show them if needed.
  Revenue is NOT total_amount. It is revenue_amount, which is 0 for anything not COMPLETED.
  Example: order 106 is SHIPPED for £79.99, so total_amount = 79.99 but revenue_amount = 0.00.
  It becomes revenue on the day its status changes to COMPLETED.

  Personal data (customer name, email) is deliberately left out. Tableau only
  needs the region, and the guide says not to put personal data on dashboards.
*/

with orders as (

    -- ref() points at another dbt model. dbt builds stg_orders first, then this.
    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

joined as (

    select
        -- keys and dates
        o.order_id,
        o.order_date,
        date_trunc('month', o.order_date)       as order_month,   -- 2025-12-13 -> 2025-12-01
        o.customer_id,
        o.product_id,

        -- descriptive columns used as dashboard filters
        coalesce(c.region, 'Unknown')           as customer_region,
        p.product_name,
        p.category                              as product_category,

        -- status and money
        o.order_status,
        o.total_amount,

        -- THE revenue definition: only COMPLETED orders count
        (o.order_status = 'COMPLETED')          as is_revenue,
        case
            when o.order_status = 'COMPLETED' then o.total_amount
            else 0
        end                                     as revenue_amount,

        -- data-quality flag: false if the customer were ever missing or unknown
        (c.customer_id is not null)             as has_valid_customer,
        o.source_row_count

    -- LEFT JOIN keeps every order, even one whose customer or product were missing.
    -- An inner JOIN would silently drop such an order, and revenue would be too low.
    from orders as o
    left join customers as c
        on o.customer_id = c.customer_id
    left join products as p
        on o.product_id = p.product_id

)

select * from joined