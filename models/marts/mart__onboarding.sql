with

base as (

    select * from {{ ref('int__rep_performance') }}

),

new_hires as (

    select *
    from base
    where is_new_hire = 'Yes'

)

select * from new_hires