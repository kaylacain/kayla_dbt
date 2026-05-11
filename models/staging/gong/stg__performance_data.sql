with 

source as (

    select * from {{ source('gong', 'performance_data') }}

),

renamed as (

    select
        rep::varchar                                as rep_id,
        new_hire::boolean                           as is_new_hire,
        deal_size_q3::float                         as avg_deal_size_pre_period,
        deal_size_q4::float                         as avg_deal_size_post_period,
        number_of_deals_q3::int                     as deal_count_pre_period,
        number_of_deals_q4::int                     as deal_count_post_period,
        revenue_per_rep_q3::float                   as revenue_pre_period,
        revenue_per_rep_q4::float                   as revenue_post_period,
        time_to_first_deal_days::int                as days_to_first_deal

    from source

)

select * from renamed