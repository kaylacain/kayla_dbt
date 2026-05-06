with base as (

    select * from {{ ref('int_gong_pilot__rep_performance') }}

),

segmented as (

    select
        rep_id,
        -- high/low flag for each signal based on median split
        case when manager_calls_listened >= percentile_cont(0.5) 
            within group (order by manager_calls_listened) over ()
            then 'High' else 'Low' 
        end as coaching_segment,

        case when peer_calls_listened >= percentile_cont(0.5) 
            within group (order by peer_calls_listened) over ()
            then 'High' else 'Low' 
        end as peer_learning_segment,

        case when deal_board_views >= percentile_cont(0.5) 
            within group (order by deal_board_views) over ()
            then 'High' else 'Low' 
        end as deal_board_segment,

        case when interactivity_score >= percentile_cont(0.5) 
            within group (order by interactivity_score) over ()
            then 'High' else 'Low' 
        end as interactivity_segment,

        case when longest_monologue_min <= percentile_cont(0.5) 
            within group (order by longest_monologue_min) over ()
            then 'High' else 'Low' 
        end as monologue_segment,
        -- note: flipped for monologue — shorter is better

       

    from base

)

select * from segmented