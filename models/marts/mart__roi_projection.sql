with

lift as (

    select * from {{ ref('int__composite_segments_lift') }}
    where engagement_signal = 'Manager Coaching'

),

assumptions as (

    select * from {{ ref('roi_assumptions') }}

),

base_metrics as (

    select
        high_avg_revenue                 as avg_revenue_per_rep,
        high_avg_deal_count              as avg_deal_count_per_rep,
        high_avg_revenue / 250.0         as avg_daily_revenue_per_rep
    from {{ ref('int__composite_segments_lift') }}
    where engagement_signal = 'Manager Coaching'

),

projections as (

    select
        a.scenario,
        a.global_rep_count,
        a.high_engagement_adoption_rate,
        a.new_hires_per_year,

        -- inputs from pilot data
        l.deal_size_lift,
        l.deal_size_lift_pct,
        l.onboarding_days_saved,
        l.onboarding_lift_pct,
        m.avg_revenue_per_rep,
        m.avg_deal_count_per_rep,
        m.avg_daily_revenue_per_rep,

        -- annualized deal count
        m.avg_deal_count_per_rep 
            * a.annualization_factor            as annual_deal_count_per_rep,

        -- reps reached at each adoption rate
        a.global_rep_count 
            * a.high_engagement_adoption_rate   as reps_at_high_engagement,

        -- deal size ROI
        l.deal_size_lift
            * (m.avg_deal_count_per_rep * a.annualization_factor)
            * (a.global_rep_count * a.high_engagement_adoption_rate)
                                                as deal_size_roi,

        -- onboarding ROI
        l.onboarding_days_saved
            * m.avg_daily_revenue_per_rep
            * a.new_hires_per_year              as onboarding_roi,

        -- total ROI
        (
            l.deal_size_lift
                * (m.avg_deal_count_per_rep * a.annualization_factor)
                * (a.global_rep_count * a.high_engagement_adoption_rate)
        ) + (
            l.onboarding_days_saved
                * m.avg_daily_revenue_per_rep
                * a.new_hires_per_year
        )                                       as total_roi

    from lift l
    cross join assumptions a
    cross join base_metrics m

)

select * from projections
order by
    case scenario
        when 'conservative' then 1
        when 'base' then 2
        when 'optimistic' then 3
    end