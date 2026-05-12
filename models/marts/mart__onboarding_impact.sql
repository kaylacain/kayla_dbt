with

source as (

    select * from {{ ref('int__onboarding') }}

),

/*
  Segment-level aggregation.
  Grain: one row per engagement_segment ('High' / 'Low').

  This is the consumption-layer model — referenced by dashboards,
  the What-If scenario tool, and insights__roi_projection.
  All metric definitions are finalised here, not upstream.
*/

segment_summary as (

    select
        engagement_segment,
        count(distinct rep_id)                                          as rep_count,

        -- Onboarding velocity
        avg(days_to_first_deal)                                         as avg_ttd,
        min(days_to_first_deal)                                         as min_ttd,
        max(days_to_first_deal)                                         as max_ttd,
        percentile_cont(0.5)
            within group (order by days_to_first_deal)                  as median_ttd,

        -- TTD improvement vs low baseline
        avg(ttd_days_saved_vs_low)                                      as avg_days_saved_vs_low,

        -- Revenue performance
        avg(revenue_pre_period)                                         as avg_revenue_pre,
        avg(revenue_post_period)                                        as avg_revenue_post,
        sum(revenue_post_period)                                        as total_revenue_post,
        avg(revenue_growth_pct)                                         as avg_revenue_growth_pct,

        -- Deal metrics
        avg(deal_count_pre_period)                                      as avg_deal_count_pre,
        avg(deal_count_post_period)                                     as avg_deal_count_post,
        avg(avg_deal_size_pre_period)                                   as avg_deal_size_pre,
        avg(avg_deal_size_post_period)                                  as avg_deal_size_post,

        -- Engagement score
        avg(gong_engagement_score)                                      as avg_engagement_score,
        min(gong_engagement_score)                                      as min_engagement_score,
        max(gong_engagement_score)                                      as max_engagement_score

    from source
    group by engagement_segment

),

/*
  Incrementality calculation.
  Method: difference-in-differences at segment level.
    - Low segment = counterfactual (what high-segment reps would
      likely have produced without meaningful Gong engagement)
    - Incremental revenue = (high_avg_post_rev - low_avg_post_rev)
                            * high_rep_count
    - Assumes parallel trends: both cohorts had similar pre-period
      baselines; any post-period gap is Gong-attributable.
*/

low_baseline as (

    select
        avg_revenue_post                                                as low_avg_revenue_post,
        avg_ttd                                                         as low_avg_ttd,
        rep_count                                                       as low_rep_count

    from segment_summary
    where engagement_segment = 'Low'

),

high_segment as (

    select
        avg_revenue_post                                                as high_avg_revenue_post,
        total_revenue_post                                              as high_total_revenue_post,
        avg_ttd                                                         as high_avg_ttd,
        rep_count                                                       as high_rep_count

    from segment_summary
    where engagement_segment = 'High'

),

incrementality as (

    select
        h.high_rep_count,
        l.low_rep_count,
        h.high_rep_count + l.low_rep_count                              as total_new_hire_count,

        -- TTD improvement
        l.low_avg_ttd - h.high_avg_ttd                                  as ttd_improvement_days,
        (l.low_avg_ttd - h.high_avg_ttd)
            / nullif(l.low_avg_ttd, 0)                                  as ttd_improvement_pct,

        -- Revenue incrementality (pilot cohort)
        h.high_avg_revenue_post - l.low_avg_revenue_post                as incremental_rev_per_high_rep,
        (h.high_avg_revenue_post - l.low_avg_revenue_post)
            * h.high_rep_count                                          as total_incremental_rev_pilot,

        -- Per-rep revenue lift pct
        (h.high_avg_revenue_post - l.low_avg_revenue_post)
            / nullif(l.low_avg_revenue_post, 0)                        as incremental_rev_lift_pct,

        -- Projection to 5,000-rep rollout
        -- Assumes: same new hire ratio (24.8%), same engagement distribution
        -- Sensitivity levers exposed for What-If tool
        0.248                                                           as assumed_new_hire_ratio,
        5000                                                            as rollout_rep_count,
        cast(5000 * 0.248 as int)                                       as projected_new_hire_count,

        cast(5000 * 0.248
            * (h.high_rep_count::float
                / nullif(h.high_rep_count + l.low_rep_count, 0))
        as int)                                                         as projected_high_segment_count,

        (h.high_avg_revenue_post - l.low_avg_revenue_post)
            * (5000 * 0.248
                * (h.high_rep_count::float
                    / nullif(h.high_rep_count + l.low_rep_count, 0))
              )                                                         as projected_incremental_rev_5k

    from high_segment h
    cross join low_baseline l

),

/*
  Final output: segment summary rows + one incrementality summary row.
  Union keeps grain consistent for dashboard consumption — filter on
  engagement_segment = 'Incrementality' for the rollup view.
*/

final as (

    select
        engagement_segment,
        rep_count,
        avg_ttd,
        median_ttd,
        avg_days_saved_vs_low,
        avg_revenue_pre,
        avg_revenue_post,
        total_revenue_post,
        avg_revenue_growth_pct,
        avg_deal_count_pre,
        avg_deal_count_post,
        avg_deal_size_pre,
        avg_deal_size_post,
        avg_engagement_score,
        null                                                            as ttd_improvement_days,
        null                                                            as ttd_improvement_pct,
        null                                                            as incremental_rev_per_high_rep,
        null                                                            as total_incremental_rev_pilot,
        null                                                            as incremental_rev_lift_pct,
        null                                                            as projected_incremental_rev_5k,
        null                                                            as projected_new_hire_count,
        null                                                            as rollout_rep_count

    from segment_summary

    union all

    select
        'Incrementality'                                                as engagement_segment,
        total_new_hire_count                                            as rep_count,
        null                                                            as avg_ttd,
        null                                                            as median_ttd,
        null                                                            as avg_days_saved_vs_low,
        null                                                            as avg_revenue_pre,
        null                                                            as avg_revenue_post,
        null                                                            as total_revenue_post,
        null                                                            as avg_revenue_growth_pct,
        null                                                            as avg_deal_count_pre,
        null                                                            as avg_deal_count_post,
        null                                                            as avg_deal_size_pre,
        null                                                            as avg_deal_size_post,
        null                                                            as avg_engagement_score,
        ttd_improvement_days,
        ttd_improvement_pct,
        incremental_rev_per_high_rep,
        total_incremental_rev_pilot,
        incremental_rev_lift_pct,
        projected_incremental_rev_5k,
        projected_new_hire_count,
        rollout_rep_count

    from incrementality

)

select * from final