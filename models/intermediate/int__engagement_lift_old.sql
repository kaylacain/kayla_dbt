with

segments as (

    select * from {{ ref('int__engagement_segments_old') }}

    --where not is_outlier

),

pivoted as (

    select
        engagement_signal,

        -- deal size
        max(case when segment = 'High' then avg_deal_size end)      as high_avg_deal_size,
        max(case when segment = 'Low' then avg_deal_size end)       as low_avg_deal_size,

        -- revenue
        max(case when segment = 'High' then avg_revenue end)        as high_avg_revenue,
        max(case when segment = 'Low' then avg_revenue end)         as low_avg_revenue,

        -- deal count
        max(case when segment = 'High' then avg_deal_count end)     as high_avg_deal_count,
        max(case when segment = 'Low' then avg_deal_count end)      as low_avg_deal_count,

        -- days to first deal (new hires only)
        max(case when segment = 'High' then avg_days_to_first_deal end) as high_avg_days_to_first_deal,
        max(case when segment = 'Low' then avg_days_to_first_deal end)  as low_avg_days_to_first_deal,

        -- rep counts
        max(case when segment = 'High' then rep_count end)          as high_rep_count,
        max(case when segment = 'Low' then rep_count end)           as low_rep_count

    from segments
    group by engagement_signal

),

lift as (

    select
        engagement_signal,
        high_rep_count,
        low_rep_count,

        -- deal size lift
        high_avg_deal_size                                              as high_avg_deal_size,
        low_avg_deal_size                                               as low_avg_deal_size,
        high_avg_deal_size - low_avg_deal_size                          as deal_size_lift,
        (high_avg_deal_size - low_avg_deal_size)
            / nullif(low_avg_deal_size, 0)                              as deal_size_lift_pct,

        -- revenue lift
        high_avg_revenue                                                as high_avg_revenue,
        low_avg_revenue                                                 as low_avg_revenue,
        high_avg_revenue - low_avg_revenue                              as revenue_lift,
        (high_avg_revenue - low_avg_revenue)
            / nullif(low_avg_revenue, 0)                                as revenue_lift_pct,

        -- deal count lift
        high_avg_deal_count                                             as high_avg_deal_count,
        low_avg_deal_count                                              as low_avg_deal_count,
        high_avg_deal_count - low_avg_deal_count                        as deal_count_lift,
        (high_avg_deal_count - low_avg_deal_count)
            / nullif(low_avg_deal_count, 0)                             as deal_count_lift_pct,

        -- onboarding lift (will be null for non-new-hire segments)
        high_avg_days_to_first_deal                                     as high_avg_days_to_first_deal,
        low_avg_days_to_first_deal                                      as low_avg_days_to_first_deal,
        low_avg_days_to_first_deal - high_avg_days_to_first_deal        as onboarding_days_saved,
        -- note: flipped so positive = improvement (fewer days is better)
        (low_avg_days_to_first_deal - high_avg_days_to_first_deal)
            / nullif(low_avg_days_to_first_deal, 0)                     as onboarding_lift_pct

    from pivoted

)

select * from lift
order by revenue_lift_pct desc