with

source as (

    select * from {{ ref('int__rep_metrics') }}

),

source2 as (

    select * from {{ ref('int__composite_segments') }}

),


source3 as (

    select * from {{ ref('int__engagement_segments') }}

)

select a.* from source a

left join source2 b
on a.rep_id = b.rep_id
left join source3 c
on a.rep_id = c.rep_id