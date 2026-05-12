with

/*
  Scope: new hires only, outlier-filtered.
  Grain: one row per rep.

  Purpose: join composite engagement segmentation onto new hire reps,
  calculate TTD and revenue metrics at rep level, and derive
  the counterfactual baseline needed for incrementality.

  Incrementality logic:
    - "Low" segment = counterfactual (what reps would do without
      meaningful Gong engagement during onboarding)
    - "High" segment = treated group
    - Incremental revenue = (high_avg_rev - low_avg_rev) * high_rep_count
*/

segmented as (

    select
        rep_id,
        days_to_first_deal,
        revenue_pre_period,
        revenue_post_period,
        deal_count_pre_period,
        deal_count_post_period,
        avg_deal_size_pre_period,
        avg_deal_size_post_period,
         engagement_segment,       -- 'High' / 'Low'
        gong_engagement_score     -- 0–1 normalized composite score

    from {{ ref('int__composite_segments') }}
    where
        is_new_hire
        and not is_outlier
        and days_to_first_deal >= 0  -- exclude data anomalies (2 reps with negative TTD)

),


/*
  Population-level baselines computed as window aggregates so they
  travel with each row — lets the mart aggregate flexibly without
  needing a second pass.
*/

with_baselines as (

    select
        *,

        -- TTD baselines
        avg(days_to_first_deal) over ()                              as pop_avg_ttd,
        avg(days_to_first_deal) over (
            partition by engagement_segment
        )                                                            as segment_avg_ttd,

        -- Days saved vs low-segment baseline (populated after agg, used in mart)
        avg(case when engagement_segment = 'Low'
                then days_to_first_deal end
        ) over ()                                                    as low_segment_avg_ttd,

        -- Revenue baselines
        avg(revenue_post_period) over ()                             as pop_avg_post_revenue,
        avg(revenue_post_period) over (
            partition by engagement_segment
        )                                                            as segment_avg_post_revenue,

        avg(case when engagement_segment = 'Low'
                then revenue_post_period end
        ) over ()                                                    as low_segment_avg_post_revenue,

        -- Rep count by segment (for incrementality denominator)
        count(*) over (
            partition by engagement_segment
        )                                                            as segment_rep_count,

        count(*) over ()                                             as total_new_hire_count

    from segmented

)

select
    rep_id,
    engagement_segment,
    gong_engagement_score,

    -- Onboarding speed
    days_to_first_deal,
    segment_avg_ttd,
    low_segment_avg_ttd,
    pop_avg_ttd,
    low_segment_avg_ttd - segment_avg_ttd                            as ttd_days_saved_vs_low,

    -- Revenue
    revenue_pre_period,
    revenue_post_period,
    revenue_post_period - revenue_pre_period                         as revenue_delta,
    revenue_post_period
        / nullif(revenue_pre_period, 0) - 1                         as revenue_growth_pct,

    -- Deal metrics
    deal_count_pre_period,
    deal_count_post_period,
    avg_deal_size_pre_period,
    avg_deal_size_post_period,

    -- Incrementality inputs (row-level, aggregated in mart)
    low_segment_avg_post_revenue,
    segment_avg_post_revenue,
    revenue_post_period - low_segment_avg_post_revenue               as incremental_revenue_vs_low,

    -- Cohort sizing
    segment_rep_count,
    total_new_hire_count

from with_baselines