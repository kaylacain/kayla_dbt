with 

source as (

    select * from {{ source('gong_pilot', 'performance_data') }}

),

renamed as (

    select
        rep                                         as rep_id,
        new_hire                                    as is_new_hire,
        deal_size_q3                                as avg_deal_size_pre_period,
        deal_size_q4                                as avg_deal_size_post_period,
        number_of_deals_q3                          as deal_count_pre_period,
        number_of_deals_q4                          as deal_count_post_period,
        revenue_per_rep_q3                          as revenue_pre_period,
        revenue_per_rep_q4                          as revenue_post_period,
        time_to_first_deal_days                     as days_to_first_deal

    from source

)

select * from renamed