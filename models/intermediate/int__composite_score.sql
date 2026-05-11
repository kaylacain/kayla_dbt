with

source as (

    select * from {{ ref('int__rep_metrics') }}
    where not is_outlier

),

standardized as (

    select
        rep_id,
        is_new_hire,

        -- Engagement signals (higher = better)
        (manager_calls_listened - avg(manager_calls_listened) over ())
            / nullif(stddev(manager_calls_listened) over (), 0)         as z_manager_calls,

        (peer_calls_listened - avg(peer_calls_listened) over ())
            / nullif(stddev(peer_calls_listened) over (), 0)            as z_peer_calls,

        (deal_board_views - avg(deal_board_views) over ())
            / nullif(stddev(deal_board_views) over (), 0)               as z_deal_board,

        -- Call quality signals
        (interactivity_score - avg(interactivity_score) over ())
            / nullif(stddev(interactivity_score) over (), 0)            as z_interactivity,

        -- Inverted: lower monologue = more dialogue = better
        -1.0 * (longest_monologue_min - avg(longest_monologue_min) over ())
            / nullif(stddev(longest_monologue_min) over (), 0)          as z_monologue_inv,

        (pitch_adoption_rate - avg(pitch_adoption_rate) over ())
            / nullif(stddev(pitch_adoption_rate) over (), 0)            as z_pitch_adoption

    from source

),

scored as (

    select
        rep_id,
        is_new_hire,

        -- Equal-weighted composite (6 signals, 1/6 each)
        -- No prior assumptions about signal importance
        (
            z_manager_calls
          + z_peer_calls
          + z_deal_board
          + z_interactivity
          + z_monologue_inv
          + z_pitch_adoption
        ) / 6.0                                                         as composite_score_raw,

        -- Retained for explainability and downstream debugging
        z_manager_calls,
        z_peer_calls,
        z_deal_board,
        z_interactivity,
        z_monologue_inv,
        z_pitch_adoption

    from standardized

)

select
    rep_id,
    is_new_hire,
    composite_score_raw,

    -- Min-max rescale to 0–1 for readability
    -- Note: scores are population-relative; will shift if rep population changes
    (composite_score_raw - min(composite_score_raw) over ())
        / nullif(
            max(composite_score_raw) over () - min(composite_score_raw) over (),
            0
        )                                                               as gong_engagement_score,

    z_manager_calls,
    z_peer_calls,
    z_deal_board,
    z_interactivity,
    z_monologue_inv,
    z_pitch_adoption

from scored