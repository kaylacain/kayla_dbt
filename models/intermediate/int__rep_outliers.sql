with

base as (
    select * from {{ ref('int__rep_base') }}
),

quartiles as (
    select
        *,
        percentile_cont(0.25) within group (order by avg_deal_size_post_period) over ()  as q1_deal_size,
        percentile_cont(0.75) within group (order by avg_deal_size_post_period) over ()  as q3_deal_size,
        percentile_cont(0.25) within group (order by revenue_post_period) over ()        as q1_revenue,
        percentile_cont(0.75) within group (order by revenue_post_period) over ()        as q3_revenue,
        percentile_cont(0.25) within group (order by deal_count_post_period) over ()     as q1_deal_count,
        percentile_cont(0.75) within group (order by deal_count_post_period) over ()     as q3_deal_count,
        percentile_cont(0.25) within group (order by days_to_first_deal) over ()         as q1_days,
        percentile_cont(0.75) within group (order by days_to_first_deal) over ()         as q3_days
    from base
),

flagged as (
    select
        *,

        case
            when avg_deal_size_post_period > q3_deal_size + (1.5 * (q3_deal_size - q1_deal_size))
            or avg_deal_size_post_period < q1_deal_size - (1.5 * (q3_deal_size - q1_deal_size))
            then true else false
        end as is_outlier_deal_size,

        case
            when revenue_post_period > q3_revenue + (1.5 * (q3_revenue - q1_revenue))
            or revenue_post_period < q1_revenue - (1.5 * (q3_revenue - q1_revenue))
            then true else false
        end as is_outlier_revenue,

        case
            when deal_count_post_period > q3_deal_count + (1.5 * (q3_deal_count - q1_deal_count))
            or deal_count_post_period < q1_deal_count - (1.5 * (q3_deal_count - q1_deal_count))
            then true else false
        end as is_outlier_deal_count,

        case
            when is_new_hire = false then null
            when days_to_first_deal > q3_days + (1.5 * (q3_days - q1_days)) then true
            when days_to_first_deal < q1_days - (1.5 * (q3_days - q1_days)) then true
            else false
        end as is_outlier_days_to_first_deal

    from quartiles
),

final as (
    select
        *,
        case
            when is_outlier_deal_size
            or is_outlier_revenue
            or is_outlier_deal_count
            or is_outlier_days_to_first_deal
            then true else false
        end as is_outlier
    from flagged
)

select * from final