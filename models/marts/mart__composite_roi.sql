with

source as (

    select * from {{ ref('int__composite_segments_lift') }}

)

select * from source