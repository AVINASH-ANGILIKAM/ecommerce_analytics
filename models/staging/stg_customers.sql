/*
  stg_customers — staging model for customers.
  Cleans customer names, emails, and regions.
  Region values are standardized to North, South, East, or West.
*/

with source as (

    select *
    from {{ source('raw', 'raw_customers') }}

),

cleaned as (

    select
        cast(customer_id as integer) as customer_id,

        trim(customer_name) as customer_name,

        lower(trim(email)) as email,

        case
            when upper(trim(region)) = 'NORTH' then 'North'
            when upper(trim(region)) = 'SOUTH' then 'South'
            when upper(trim(region)) = 'EAST'  then 'East'
            when upper(trim(region)) = 'WEST'  then 'West'
            else trim(region)
        end as region,

        signup_date

    from source

)

select *
from cleaned