with base as (

    select * from {{ ref('int__rep_metrics') }}

),

segmented as (

    select
        rep_id,
        avg_deal_size_post_period,
        revenue_post_period,
        deal_count_post_period,
        days_to_first_deal,
        -- high/low flag for each signal based on median split
        case when manager_calls_listened >= percentile_cont(0.5) 
            within group (order by manager_calls_listened) over ()
            then 'High' else 'Low' 
        end as coaching_segment,

        case when peer_calls_listened >= percentile_cont(0.5) 
            within group (order by peer_calls_listened) over ()
            then 'High' else 'Low' 
        end as peer_learning_segment,

        case when deal_board_views >= percentile_cont(0.5) 
            within group (order by deal_board_views) over ()
            then 'High' else 'Low' 
        end as deal_board_segment,

        case when interactivity_score >= percentile_cont(0.5) 
            within group (order by interactivity_score) over ()
            then 'High' else 'Low' 
        end as interactivity_segment,

        case when longest_monologue_min <= percentile_cont(0.5) 
            within group (order by longest_monologue_min) over ()
            then 'High' else 'Low' 
        end as monologue_segment,
        -- note: flipped for monologue — shorter is better

       

    from base

)


, coaching_lift as ({{ lift_segment('Manager Coaching', 'coaching_segment') }}),
peer_learning_lift as ({{ lift_segment('Peer Learning', 'peer_learning_segment') }}),
deal_board_lift as ({{ lift_segment('Deal Board Views', 'deal_board_segment') }}),
interactivity_lift as ({{ lift_segment('Interactivity Score', 'interactivity_segment') }}),
monologue_lift as ({{ lift_segment('Monologue Length', 'monologue_segment') }}),

unioned as (
    select * from coaching_lift
    union all
    select * from peer_learning_lift
    union all
    select * from deal_board_lift
    union all
    select * from interactivity_lift
    union all
    select * from monologue_lift

)

select * from unioned
order by engagement_signal, segment