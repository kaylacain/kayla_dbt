{% macro lift_segment(signal_label, segment_column) %}

    select
        '{{ signal_label }}'                                             as engagement_signal,
        {{ segment_column }}                                             as segment,
        avg(avg_deal_size_post_period)                                   as avg_deal_size,
        avg(revenue_post_period)                                         as avg_revenue,
        avg(deal_count_post_period)                                      as avg_deal_count,
        avg(days_to_first_deal)                                          as avg_days_to_first_deal,
        sum(avg_deal_size_post_period*deal_count_post_period)            as total_deal_size,
        sum(revenue_post_period)                                         as total_revenue,
        sum(deal_count_post_period)                                      as total_deal_count,
        count(distinct rep_id)                                           as rep_count
    from segmented
    group by {{ segment_column }}

{% endmacro %}