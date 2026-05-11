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

        -- ntile(2) split: guarantees balanced High/Low segments
        -- High = top half by composite score, Low = bottom half
        -- rep_id as tiebreaker ensures deterministic assignment across runs
        -- ⚠️ Segment labels are relative to this deployment's population;
        --    cross-customer comparisons require re-baselining
        case
            when ntile(2) over (order by gong_engagement_score, rep_id) = 2
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

),

base as (

    select * from {{ ref('int__rep_metrics') }}

),


joined as (

    select
        b.*,
        f.engagement_segment,
        f.gong_engagement_score

    from base b
    inner join final f on b.rep_id = f.rep_id

)

select * from joined