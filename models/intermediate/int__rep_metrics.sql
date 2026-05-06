with

base as (
    select * from {{ ref('int__rep_base') }}
),

outliers as (
    select * from {{ ref('int__rep_outliers') }}
),

joined as (
    select
        b.*,
        o.is_outlier_deal_size,
        o.is_outlier_revenue,
        o.is_outlier_deal_count,
        o.is_outlier_days_to_first_deal,
        o.is_outlier
    from base b
    left join outliers o
        on b.rep_id = o.rep_id
),

metrics as (
    select
        *,
        avg_deal_size_post_period - avg_deal_size_pre_period            as avg_deal_size_delta,
        deal_count_post_period - deal_count_pre_period                  as deal_count_delta,
        revenue_post_period - revenue_pre_period                        as revenue_delta,
        (avg_deal_size_post_period - avg_deal_size_pre_period)
            / nullif(avg_deal_size_pre_period, 0)                       as avg_deal_size_pct_change,
        (revenue_post_period - revenue_pre_period)
            / nullif(revenue_pre_period, 0)                             as revenue_pct_change,
        (deal_count_post_period - deal_count_pre_period)
            / nullif(deal_count_pre_period, 0)                          as deal_count_pct_change,
        new_pitch_count
            / nullif(new_pitch_count + old_pitch_count, 0)              as pitch_adoption_rate
    from joined
)

select * from metrics