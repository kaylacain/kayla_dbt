with

base as (

    select * from {{ ref('int__rep_metrics') }}
    where not is_outlier

),

segmented as (

    select
        rep_id,
        is_new_hire,
        revenue_pre_period,
        revenue_post_period,
        deal_count_pre_period,
        deal_count_post_period,
        avg_deal_size_pre_period,
        avg_deal_size_post_period,

        case when ntile(2) over (order by manager_calls_listened, rep_id) = 2
            then 'High' else 'Low' end                              as coaching_segment,

        case when ntile(2) over (order by peer_calls_listened, rep_id) = 2
            then 'High' else 'Low' end                              as peer_learning_segment,
        
        case when ntile(2) over (order by deal_board_views, rep_id) = 2
            then 'High' else 'Low' end                              as deal_board_segment,

        case when ntile(2) over (order by interactivity_score, rep_id) = 2
            then 'High' else 'Low' end                              as interactivity_segment,

        -- Inverted: shorter monologue = better, so order ascending and flip
        case when ntile(2) over (order by longest_monologue_min desc, rep_id) = 2
            then 'High' else 'Low' end                              as monologue_segment,

        case when ntile(2) over (order by pitch_adoption_rate, rep_id) = 2
            then 'High' else 'Low' end                              as pitch_adoption_segment

    from base

)

select * from segmented