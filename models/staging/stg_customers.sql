/*
  stg_customers  —  "stg" = staging: the cleaned copy of one raw table.
  One row per customer. Same 20 rows as RAW_CUSTOMERS, tidied up.

  Staging models only clean. They don't join tables or calculate business numbers.
  Example: region 'south' (customer 1) becomes 'South', so Tableau shows
  ONE South region instead of two.
*/

with source as (

    -- source() points at a raw table that dbt didn't create (see _sources.yml)
    select * from {{ source('raw', 'raw_customers') }}

),

cleaned as (

    select
        cast(customer_id as integer)    as customer_id,    -- whole number, e.g. 1
        trim(customer_name)             as customer_name,
        lower(trim(email))              as email,          -- 'A@Example.com' -> 'a@example.com'
        initcap(trim(region))           as region,         -- 'south' -> 'South'
        cast(signup_date as date)       as signup_date
    from source

)

select * from cleaned