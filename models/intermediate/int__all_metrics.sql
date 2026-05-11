with

base as (

    select * from {{ ref('int__rep_metrics') }}

),

composite as (

    select
        rep_id,
        engagement_segment  -- 'High' / 'Low' from int__composite_metric

    from {{ ref('int__composite_segments') }}

),

joined as (

    select
        b.*,
        c.engagement_segment

    from base b
    inner join composite c on b.rep_id = c.rep_id

)

select
    'Composite Engagement Score'                                        as engagement_signal,
    engagement_segment                                                  as segment,
    sum(revenue_pre_period)                                             as total_revenue_pre_period,
    sum(deal_count_pre_period)                                          as total_deal_count_pre_period,
    avg(avg_deal_size_post_period / avg_deal_size_pre_period - 1)       as avg_deal_size_lift_pct,
    sum(revenue_post_period) / sum(revenue_pre_period) - 1              as revenue_lift_pct,
    sum(deal_count_post_period) / sum(deal_count_pre_period) - 1        as deal_count_lift_pct,
    count(distinct rep_id)                                              as rep_count

from joined
group by engagement_segment
order by segment