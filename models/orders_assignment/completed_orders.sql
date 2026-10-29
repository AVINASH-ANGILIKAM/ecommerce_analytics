/*
  completed_orders - TASK 3: mart model with only the orders that brought in money.

  Mart = business-ready data that a dashboard (Tableau) or a CRM sync (Hightouch)
  can use directly. It reads the staging model with ref(), so dbt knows it must
  build stg_orders_assignment FIRST (ref = "this model depends on that one").
  Built as a TABLE, because reports read it again and again.
*/

{{ config(materialized='table') }}

select
    order_id,
    customer_id,
    order_status,
    order_amount

from {{ ref('stg_orders_assignment') }}

where order_status = 'COMPLETED'   -- business rule: only completed orders count as revenue
