with 

source as (

    select * from {{ source('gong', 'gong_data') }}

),

renamed as (

    select
        rep::varchar                                                         as rep_id,
        num_reps_calls_listened_by_their_manager::int                       as manager_calls_listened,
        num_peer_calls_rep_listened_to::int                                 as peer_calls_listened,
        num_times_rep_accessed_the_deal_board::int                          as deal_board_views,
        interactivity_score::float                                          as interactivity_score,
        longest_monologue_min::float                                        as longest_monologue_min,
        num_times_competitor_was_mentioned_by_the_prospect::int             as competitor_mentions,
        num_times_rep_used_new_sales_pitch::int                             as new_pitch_count,
        num_times_rep_used_old_sales_pitch::int                             as old_pitch_count

    from source

)

select * from renamed