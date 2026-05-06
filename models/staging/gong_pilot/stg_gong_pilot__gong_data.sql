with 

source as (

    select * from {{ source('gong_pilot', 'gong_data') }}

),

renamed as (

    select
        rep                                                         as rep_id,
        num_reps_calls_listened_by_their_manager                    as manager_calls_listened,
        num_peer_calls_rep_listened_to                              as peer_calls_listened,
        num_times_rep_accessed_the_deal_board                       as deal_board_views,
        interactivity_score                                         as interactivity_score,
        longest_monologue_min                                       as longest_monologue_min,
        num_times_competitor_was_mentioned_by_the_prospect          as competitor_mentions,
        num_times_rep_used_new_sales_pitch                          as new_pitch_count,
        num_times_rep_used_old_sales_pitch                          as old_pitch_count

    from source

)

select * from renamed