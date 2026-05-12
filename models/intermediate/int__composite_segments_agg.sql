with

source as (

    select * from {{ ref('int__composite_segments') }}

)


select
    'Composite Engagement Score'                                        as engagement_signal,
    engagement_segment                                                  as segment,
    sum(revenue_pre_period)                                             as total_revenue_pre_period,
    sum(revenue_post_period)                                            as total_revenue_post_period,
    sum(deal_count_pre_period)                                          as total_deal_count_pre_period,
    sum(deal_count_post_period)                                         as total_deal_count_post_period,
    avg(avg_deal_size_post_period / avg_deal_size_pre_period - 1)       as avg_deal_size_lift_pct,
    sum(revenue_post_period) / sum(revenue_pre_period) - 1              as revenue_lift_pct,
    sum(deal_count_post_period) / sum(deal_count_pre_period) - 1        as deal_count_lift_pct,
    count(distinct rep_id)                                              as rep_count

from source
group by engagement_segment
order by segment