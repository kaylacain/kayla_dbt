with

segments as (

    select * from {{ ref('int__all_metrics') }}

    --where not is_outlier

),

pivoted as (

    select
        engagement_signal,

        max(case when segment = 'High' then total_revenue_pre_period end)       as high_total_revenue_pre_period,
        max(case when segment = 'Low' then total_revenue_pre_period end)        as low_total_revenue_pre_period,

        max(case when segment = 'High' then total_deal_count_pre_period end)    as high_total_deal_count_pre_period,
        max(case when segment = 'Low' then total_deal_count_pre_period end)     as low_total_deal_count_pre_period,

        max(case when segment = 'High' then avg_deal_size_lift_pct end)         as high_avg_deal_size_lift_pct,
        max(case when segment = 'Low' then avg_deal_size_lift_pct end)          as low_avg_deal_size_lift_pct,

        max(case when segment = 'High' then revenue_lift_pct end)               as high_revenue_lift_pct,
        max(case when segment = 'Low' then revenue_lift_pct end)                as low_revenue_lift_pct,

        max(case when segment = 'High' then deal_count_lift_pct end)            as high_deal_count_lift_pct,
        max(case when segment = 'Low' then deal_count_lift_pct end)             as low_deal_count_lift_pct

    from segments
    group by engagement_signal

),

incremental as (

    select
        *,
        high_revenue_lift_pct - low_revenue_lift_pct                        as high_incremental_revenue_growth_pct,
        high_deal_count_lift_pct - low_deal_count_lift_pct                  as high_incremental_deal_count_growth_pct

    from pivoted

)

select
    engagement_signal,
    high_incremental_revenue_growth_pct,
    high_total_revenue_pre_period * high_incremental_revenue_growth_pct     as high_incremental_revenue,
    high_incremental_deal_count_growth_pct,
    high_total_deal_count_pre_period * high_incremental_deal_count_growth_pct as high_incremental_deal_count

from incremental