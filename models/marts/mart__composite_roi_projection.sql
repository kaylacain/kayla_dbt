with

lift as (

    select * from {{ ref('int__composite_segments_lift') }}
    where engagement_signal = 'Composite Engagement Score'

),

assumptions as (

    select * from {{ ref('roi_assumptions') }}

),

projections as (

    select
        a.scenario,
        a.global_rep_count,
        a.high_engagement_adoption_rate,
        a.annualization_factor,

        l.high_rep_count                                                    as pilot_high_rep_count,
        l.high_incremental_revenue_growth_pct,
        l.high_incremental_revenue                                          as pilot_incremental_revenue,

        -- scale pilot baseline to global engaged population
        l.high_total_revenue_pre_period
            * (
                (a.global_rep_count * a.high_engagement_adoption_rate)
                / nullif(l.high_rep_count, 0)
            )                                                               as global_baseline_revenue,

        -- apply the incremental (Gong-attributable) growth rate to global baseline
        -- and annualize — this isolates Gong's effect vs what reps would have
        -- grown anyway, using the low-engagement cohort as the counterfactual
        l.high_total_revenue_pre_period
            * (
                (a.global_rep_count * a.high_engagement_adoption_rate)
                / nullif(l.high_rep_count, 0)
            )
            * l.high_incremental_revenue_growth_pct
            * a.annualization_factor                                        as annual_revenue_lift

    from lift l
    cross join assumptions a

)

select
    scenario,
    global_rep_count,
    high_engagement_adoption_rate,
    pilot_high_rep_count,
    high_incremental_revenue_growth_pct,
    pilot_incremental_revenue,
    global_baseline_revenue,
    annual_revenue_lift
from projections
order by
    case scenario
        when 'conservative' then 1
        when 'base'         then 2
        when 'optimistic'   then 3
    end