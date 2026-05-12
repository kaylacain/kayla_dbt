with

base as (

    select * from {{ ref('int__engagement_segments') }}

),

unpivoted as (

    select 'Manager Coaching'    as engagement_signal, coaching_segment         as segment, * from base
    union all
    select 'Peer Learning'       as engagement_signal, peer_learning_segment     as segment, * from base
    union all
    select 'Deal Board Views'    as engagement_signal, deal_board_segment        as segment, * from base
    union all
    select 'Interactivity Score' as engagement_signal, interactivity_segment     as segment, * from base
    union all
    select 'Monologue Length'    as engagement_signal, monologue_segment         as segment, * from base
    union all
    select 'Pitch Adoption Rate' as engagement_signal, pitch_adoption_segment    as segment, * from base

)

select
    engagement_signal,
    segment,
    count(distinct rep_id)                                                      as rep_count,
    sum(revenue_pre_period)                                                     as total_revenue_pre_period,
    sum(deal_count_pre_period)                                                  as total_deal_count_pre_period,
    avg(avg_deal_size_post_period / nullif(avg_deal_size_pre_period, 0) - 1)    as avg_deal_size_lift_pct,
    sum(revenue_post_period) / nullif(sum(revenue_pre_period), 0) - 1          as revenue_lift_pct,
    sum(deal_count_post_period) / nullif(sum(deal_count_pre_period), 0) - 1    as deal_count_lift_pct

from unpivoted
group by engagement_signal, segment