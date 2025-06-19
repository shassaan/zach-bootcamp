create table players_scd_table
(
	player_name text,
	scoring_class scoring_class,
	is_active boolean,
    start_season integer,
	end_season integer,
    current_season INTEGER,
    primary key (player_name,start_season)
);



insert into players_scd_table
WITH with_previous AS (select player_name,
                         current_season,
                         players.scoring_class,
                         players.is_active,
                         lag(players.scoring_class, 1)
                         over (partition by player_name order by current_season) as previous_scoring_class,
                         lag(players.is_active, 1)
                         over (partition by player_name order by current_season) as previous_is_active
                  from players where  current_season <= 2021),

with_indicators as (select *,
       CASE
           WHEN scoring_class <> previous_scoring_class THEN 1
           WHEN is_active <> previous_is_active THEN 1
           ELSE 0
       END as change_indicator
       from with_previous
),
with_streaks as (
select *,
       sum(change_indicator) over (partition by player_name order by current_season) as streak_identifier
from with_indicators)

select player_name,scoring_class,is_active, min(current_season) as start_season, max(current_season) as end_season, 2021 as current_season from with_streaks
            group by player_name, streak_identifier, is_active,scoring_class order by player_name, streak_identifier






