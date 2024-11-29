CREATE TABLE actors_history_scd (
    actor_id TEXT,
    actor_name TEXT,
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER,
    current_year INTEGER,
    primary key (actor_id,start_date)
)

with with_previous as (
    select
    actor_id,
    actor_name,
    quality_class,
    is_active,
    current_year,
    lag(quality_class,1) over (partition by actor_id order by current_year) as previous_quality_class,
    lag(is_active,1) over (partition by actor_id order by current_year) as previous_is_active
    from actors where current_year <= 2020

),
    with_indicators as (
        select *,
               CASE
                   WHEN quality_class <> previous_quality_class THEN 1
                   WHEN is_active <> previous_is_active THEN 1
                   ELSE 0
                END as change_indicator
               from with_previous
    ),
with_streaks as (
    select *,
           sum(change_indicator) over (partition by actor_id order by current_year) as streak_identifier
    from with_indicators
)
INSERT INTO actors_history_scd
    select actor_id,actor_name,quality_class,is_active,min(current_year) as start_date, max(current_year) as end_date, 2021 as current_year
    from with_streaks group by actor_id, actor_name, quality_class, is_active,streak_identifier order by actor_id, streak_identifier
