with

performance as (
    select * from {{ ref('stg__performance_data') }}
),

gong as (
    select * from {{ ref('stg__gong_data') }}

),

joined as (
    select
        p.rep_id,
        p.is_new_hire,
        p.avg_deal_size_pre_period,
        p.avg_deal_size_post_period,
        p.deal_count_pre_period,
        p.deal_count_post_period,
        p.revenue_pre_period,
        p.revenue_post_period,
        p.days_to_first_deal,
        g.manager_calls_listened,
        g.peer_calls_listened,
        g.deal_board_views,
        g.interactivity_score,
        g.longest_monologue_min,
        g.competitor_mentions,
        g.new_pitch_count,
        g.old_pitch_count
    from performance p
    left join gong g
        on p.rep_id = g.rep_id
)

select * from joined