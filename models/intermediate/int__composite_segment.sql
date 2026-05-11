with

source as (

    select * from {{ ref('int__rep_metrics') }}
    where not is_outlier

),

/*
  Step 1: Z-score each signal across the rep population.
  
  Signals included:
    - manager_calls_listened   ↑ good  (coaching received)
    - peer_calls_listened      ↑ good  (self-directed learning)
    - deal_board_views         ↑ good  (deal hygiene / pipeline awareness)
    - interactivity_score      ↑ good  (conversational quality on calls)
    - longest_monologue_min    ↓ good  (lower = more dialogue) → inverted
    - pitch_adoption_rate      ↑ good  (new pitch / total pitches, already 0–1)

  Signals excluded:
    - competitor_mentions      ← deal characteristic, not rep behavior; 
                                 territory-driven, would introduce noise
*/

standardized as (

    select
        rep_id,
        is_new_hire,

        -- Engagement signals
        (manager_calls_listened - avg(manager_calls_listened) over ())
            / nullif(stddev(manager_calls_listened) over (), 0)             as z_manager_calls,

        (peer_calls_listened - avg(peer_calls_listened) over ())
            / nullif(stddev(peer_calls_listened) over (), 0)                as z_peer_calls,

        (deal_board_views - avg(deal_board_views) over ())
            / nullif(stddev(deal_board_views) over (), 0)                   as z_deal_board,

        -- Call quality signals
        (interactivity_score - avg(interactivity_score) over ())
            / nullif(stddev(interactivity_score) over (), 0)                as z_interactivity,

        -- Invert monologue: lower is better
        -1.0 * (longest_monologue_min - avg(longest_monologue_min) over ())
            / nullif(stddev(longest_monologue_min) over (), 0)              as z_monologue_inv,

        -- Pitch adoption: rescale to mean=0 stddev=1 like the others
        (pitch_adoption_rate - avg(pitch_adoption_rate) over ())
            / nullif(stddev(pitch_adoption_rate) over (), 0)                as z_pitch_adoption

    from source

),

/*
  Step 2: Equal-weighted composite score.
  
  Each of the 6 signals contributes equally (1/6 ≈ 0.1667).
  No prior assumptions about which signals matter most.
*/

weighted as (

    select
        rep_id,
        is_new_hire,
        z_manager_calls,
        z_peer_calls,
        z_deal_board,
        z_interactivity,
        z_monologue_inv,
        z_pitch_adoption,

        (
            z_manager_calls
          + z_peer_calls
          + z_deal_board
          + z_interactivity
          + z_monologue_inv
          + z_pitch_adoption
        ) / 6.0                                                             as composite_score_raw

    from standardized

),

/*
  Step 3: Rescale composite to 0–1 for readability.
  Min-max normalization within the current rep population.
  Note: scores are relative, not absolute — will shift if population changes.
*/

final as (

    select
        rep_id,
        is_new_hire,
        composite_score_raw,

        (composite_score_raw - min(composite_score_raw) over ())
            / nullif(
                max(composite_score_raw) over () - min(composite_score_raw) over (),
                0
            )                                                               as gong_engagement_score,

        -- Median split: High = above median, Low = at or below
        case
            when composite_score_raw > median(composite_score_raw) over () then 'High'
            else 'Low'
        end                                                                 as engagement_segment,

        -- Component z-scores retained for explainability / debugging
        z_manager_calls,
        z_peer_calls,
        z_deal_board,
        z_interactivity,
        z_monologue_inv,
        z_pitch_adoption

    from weighted

)

select * from final