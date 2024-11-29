CREATE TYPE actors_scd_type as (
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER
)


with last_year_scd_data as (
    select * from actors_history_scd
             where start_date = 2020
             and end_date = 2020
),
    with_historical_scd as (
        select actor_id,
               actor_name,
               quality_class,
               is_active,
               start_date,
               end_date
        from actors_history_scd
                 where start_date = 2020
                 and end_date < 2020
    ),
    this_year_scd_date as (
        select * from actors
                 where current_year = 2021
    ),
    unchanged_records as (
        select t.actor_id,
               t.actor_name,
               t.quality_class,
               t.is_active,
               l.end_date as start_date,
               t.current_year as end_date
               from this_year_scd_date t
                 join
            last_year_scd_data l
                 on l.actor_id = t.actor_id
                 where l.is_active = t.is_active
                 and l.quality_class = t.quality_class
    ),
    changed_records as (
        select t.actor_id,
               t.actor_name,
                unnest(ARRAY[ROW(
                    l.quality_class,
                    l.is_active,
                    l.start_date,
                    l.end_date
                    )::actors_scd_type,
                    ROW(
                    t.quality_class,
                    t.is_active,
                    t.current_year,
                    t.current_year
                    )::actors_scd_type]) as records
            from this_year_scd_date t
                 left join last_year_scd_data l
                 on t.actor_id = l.actor_id
                 where (t.is_active <> l.is_active or
                        t.quality_class <> t.quality_class)
    ),
   unnested_changed_records as (
       select
           actor_id,
           actor_name,
           (records::actors_scd_type).quality_class,
           (records::actors_scd_type).is_active,
           (records::actors_scd_type).start_date,
           (records::actors_scd_type).end_date
           from changed_records
   ),
    new_records as (
        select
            t.actor_id,
            t.actor_name,
            t.quality_class,
            t.is_active,
            t.current_year as start_date,
            t.current_year as end_date
            from this_year_scd_date t
                 left join last_year_scd_data l
                 on t.actor_id = l.actor_id
                 where l.actor_id is null
    )

INSERT INTO actors_history_scd
SELECT *,2021 as current_season
                  FROM (select * from with_historical_scd

                  UNION ALL

                  SELECT *
                  FROM unchanged_records

                  UNION ALL

                  SELECT *
                  FROM unnested_changed_records

                  UNION ALL

                  SELECT *
                  FROM new_records) a
