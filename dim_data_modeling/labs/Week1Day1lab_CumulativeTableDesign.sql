select *
from
    player_seasons ps

    create type season_stats as (
        season integer, gp integer, pts real, reb real, ast real
    )
;

drop type season_stats

 CREATE TYPE scoring_class AS
     ENUM ('bad', 'average', 'good', 'star');


 CREATE TABLE players (
     player_name TEXT,
     height TEXT,
     college TEXT,
     country TEXT,
     draft_year TEXT,
     draft_round TEXT,
     draft_number TEXT,
     seasons_stats season_stats[],
     scoring_class scoring_class,
     years_since_last_active INTEGER,
     is_active BOOLEAN,
     current_season INTEGER,
     PRIMARY KEY (player_name, current_season)
 );

 drop table players

insert into players
 with yesterday as (

 	select * from players
 	where current_season = 2021
 ),

 today as (

 	select * from player_seasons ps 
 	where ps.season = 2022
 )

 select 

 	coalesce(t.player_name, y.player_name) as player_name,
 	coalesce(t.height, y.height) as height,
 	coalesce(t.college, y.college) as college,
 	coalesce(t.country, y.country) as country,
 	coalesce(t.draft_year, y.draft_year) as draft_year,
 	coalesce(t.draft_round, y.draft_round) as draft_round,
 	coalesce(t.draft_number, y.draft_number) as draft_number,

 	case when y.seasons_stats is null then ARRAY[
 			ROW(
				t.season,
				t.gp,
				t.pts,
				t.reb,
				t.ast
 			)::season_stats]
 	when t.season is not null then y.seasons_stats || ARRAY[
 			ROW(
				t.season,
				t.gp,
				t.pts,
				t.reb,
				t.ast
 			)::season_stats]
 	else y.seasons_stats
 	end as season_stats,
 	case when t.season is not null then 
 		case when t.pts > 20 then 'star'
 		when t.pts > 15 then 'good'
 		when t.pts > 10 then 'average'
 		else 'bad'
 		end::scoring_class
 	else y.scoring_class
 	end as scoring_class,

 	case when t.season is not null then 0
 		else y.years_since_last_active + 1
 		end as years_since_last_active,
	
 	t.season is not null as is_active,
 	coalesce(t.season, y.current_season + 1) as current_season

 from today t full outer join yesterday y 
 on t.player_name = y.player_name


 select 

 player_name,
 (UNNEST(seasons_stats)::season_stats).* as season_stats 
 from players where current_season = 2001 and player_name = 'Michael Jordan'



 select  player_name,
 (seasons_stats[cardinality(seasons_stats)]::season_stats).pts/
 case when (seasons_stats[1]::season_stats).pts = 0 then 1 else (seasons_stats[1]::season_stats).pts end as improvement_metric

 from players order by 2 desc 



 select *  from players where current_season = 1999 and player_name = 'Michael Jordan'
