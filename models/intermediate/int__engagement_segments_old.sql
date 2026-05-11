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


, coaching_lift as (
    select
        'Manager Coaching'                  as engagement_signal,
        coaching_segment                    as segment,
        avg(avg_deal_size_post_period)      as avg_deal_size,
        avg(revenue_post_period)            as avg_revenue,
        avg(deal_count_post_period)         as avg_deal_count,
        avg(days_to_first_deal)             as avg_days_to_first_deal,
        count(distinct rep_id)              as rep_count
    from segmented
    group by coaching_segment
),

peer_learning_lift as (
    select
        'Peer Learning'             as engagement_signal,
        peer_learning_segment       as segment,
        avg(avg_deal_size_post_period)      as avg_deal_size,
        avg(revenue_post_period)            as avg_revenue,
        avg(deal_count_post_period)         as avg_deal_count,
        avg(days_to_first_deal)             as avg_days_to_first_deal,
        count(distinct rep_id)              as rep_count
    from segmented
    group by peer_learning_segment
),

deal_board_lift as (
    select
        'Deal Board Views'          as engagement_signal,
        deal_board_segment          as segment,
        avg(avg_deal_size_post_period)      as avg_deal_size,
        avg(revenue_post_period)            as avg_revenue,
        avg(deal_count_post_period)         as avg_deal_count,
        avg(days_to_first_deal)             as avg_days_to_first_deal,
        count(distinct rep_id)              as rep_count
    from segmented
    group by deal_board_segment
),

interactivity_lift as (
    select
        'Interactivity Score'          as engagement_signal,
        interactivity_segment          as segment,
        avg(avg_deal_size_post_period)      as avg_deal_size,
        avg(revenue_post_period)            as avg_revenue,
        avg(deal_count_post_period)         as avg_deal_count,
        avg(days_to_first_deal)             as avg_days_to_first_deal,
        count(distinct rep_id)              as rep_count
    from segmented
    group by interactivity_segment
),

monologue_lift as (
    select
        'Monologue Length'          as engagement_signal,
        monologue_segment          as segment,
        avg(avg_deal_size_post_period)      as avg_deal_size,
        avg(revenue_post_period)            as avg_revenue,
        avg(deal_count_post_period)         as avg_deal_count,
        avg(days_to_first_deal)             as avg_days_to_first_deal,
        count(distinct rep_id)              as rep_count
    from segmented
    group by monologue_segment
),

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