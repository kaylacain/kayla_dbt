with

base as (
    select * from {{ ref('int__rep_outliers') }}
    where not is_outlier
),


metrics as (
    select
        *,
        new_pitch_count
            / nullif(new_pitch_count + old_pitch_count, 0)              as pitch_adoption_rate
    from base
)

select * from metrics