/*
  stg_orders_assignment - TASK 3: staging model for the assignment's ORDERS table.
  (The brief calls it stg_orders. This project already has a stg_orders model from the
   practice project, and dbt model names must be unique, so this one is stg_orders_assignment.)

  Staging = a clean 1:1 copy of the raw table: same rows, same columns,
  tidy names and types, NO business rules yet.
  Built as a VIEW, so it always shows the latest raw data.
*/

{{ config(materialized='view') }}

select
    order_id,
    customer_id,
    upper(trim(order_status)) as order_status,   -- tidy text: ' completed' -> 'COMPLETED'
    order_amount

from {{ source('orders_assignment', 'orders') }}   -- = ECOM_DB.RAW.ORDERS
