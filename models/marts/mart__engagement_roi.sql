with

source as (

    select * from {{ ref('int__engagement_lift') }}

)

select * from source