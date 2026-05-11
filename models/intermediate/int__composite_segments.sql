with

source as (

    select * from {{ ref('int__composite_score') }}

),

final as (

    select
        rep_id,
        is_new_hire,
        composite_score_raw,
        gong_engagement_score,

        -- Median split: population-relative, distribution-agnostic
        -- High = above median, Low = at or below
        -- ⚠️ Segment labels are relative to this deployment's population;
        --    cross-customer comparisons require re-baselining
        case
            when gong_engagement_score > percentile_cont(0.5)
                    within group (order by gong_engagement_score) over ()
            then 'High'
            else 'Low'
        end                                                             as engagement_segment,

        z_manager_calls,
        z_peer_calls,
        z_deal_board,
        z_interactivity,
        z_monologue_inv,
        z_pitch_adoption

    from source

)

select * from final