CREATE TYPE vertex_type as ENUM ('player', 'team', 'game');
CREATE TYPE edge_type as ENUM ('plays_against', 'shares_team', 'plays_in', 'plays_on');

CREATE TABLE vertices (
    identifier TEXT,
    type vertex_type,
    properties JSON,
    PRIMARY KEY (identifier, type)
);

CREATE TABLE edges (
    subject_identifier TEXT,
    subject_type vertex_type,
    object_identifier TEXT,
    object_type vertex_type,
    edge_type edge_type,
    properties JSON,
    PRIMARY KEY (subject_identifier,
                subject_type,
                object_identifier,
                object_type,
                edge_type)
);

INSERT INTO vertices --games_data
select game_id as identifier,
       'game'::vertex_type as type,
       json_build_object(
       'pts_home',pts_home,
       'pts_away',pts_away,
       'winning_team', CASE WHEN home_team_wins = 1 THEN home_team_id ELSE visitor_team_id END
       ) as properties

from games;

with players_agg as (select player_id                   as identifier,
                            max(player_name)             as player_name,
                            count(1)                    as number_of_games,
                            sum(pts)                    as total_points,
                            array_agg(DISTINCT team_id) as teams
                     from game_details
                     group by player_id)

INSERT INTO vertices --players data
select identifier,
       'player'::vertex_type,
       json_build_object(
        'player_name', player_name,
       'number_of_games', number_of_games,
        'total_points',total_points,
       'teams', teams
       )
from players_agg;


INSERT INTO vertices -- teams data
WITH teams_deduped as (
    select *, row_number() over (partition by team_id) as row_number
    from teams
)
select team_id as identifier,
       'team'::vertex_type,
       json_build_object(
       'abbreviation', abbreviation,
       'nickname', nickname,
       'city',city,
       'arena', arena,
       'year_founded', yearfounded
       )
    from teams_deduped where row_number = 1;




INSERT INTO edges -- plays_in data

with deduped_game_details as (
    select *, row_number() over (partition by player_id, game_id) as row_number from game_details
)

select
    player_id as subject_identifier,
    'player'::vertex_type as subject_type,
    game_id as object_identifier,
    'game'::vertex_type as object_type,
    'plays_in'::edge_type as edge_type,
    json_build_object(
        'start_position', start_position,
        'pts',pts,
        'team_id',team_id,
        'team_abbreviation',team_abbreviation
    ) as properties

    from deduped_game_details where row_number = 1;



select v.properties->>'player_name' as player_name,
       max(CAST(e.properties->>'pts' as INTEGER))
       from vertices v join public.edges e
    on e.subject_identifier = v.identifier
and e.subject_type = v.type group by 1 order by 2 desc




with deduped_game_details as (
    select *, row_number() over (partition by player_id, game_id) as row_number from game_details
),
    filtered as (
        select * from deduped_game_details where row_number = 1
    ),
aggregated as ( select
       f1.player_id as subject_player_id,
       f2.player_id as object_player_id,
       CASE
           WHEN f1.team_abbreviation =  f2.team_abbreviation
            THEN 'shares_team'::edge_type
           ELSE 'plays_against'::edge_type
            END as edge_type,
    count(1) as num_games,
    sum(f1.pts) as subject_points,
    sum(f2.pts) as object_points,
     max(f1.player_name) as subject_player_name,
     max(f2.player_name) as object_player_name

from filtered f1 join filtered f2
on f1.game_id = f2.game_id and f1.player_name <> f2.player_name
where f1.player_id > f2.player_id
group by f1.player_id, f2.player_id, CASE
           WHEN f1.team_abbreviation =  f2.team_abbreviation
            THEN 'shares_team'::edge_type
           ELSE 'plays_against'::edge_type
            END
)
insert into edges
select subject_player_id as subject_identifier,
       'player'::vertex_type as subject_type,
       object_player_id as object_identifier,
       'player'::vertex_type as object_type,
       edge_type as edge_type,
       json_build_object(
        'num_games',num_games,
        'subject_pts', subject_points,
       'object_pts',object_points
       )
from aggregated

select v.properties->>'player_name' as player_name,
       e.object_identifier,
      CAST(v.properties->>'number_of_games' as real)/
      CASE WHEN CAST(v.properties->>'total_points' as real) = 0 THEN 1 ELSE CAST(v.properties->>'total_points' as real) END as average,
    e.properties->>'subject_pts' as subject_points,
    e.properties->>'num_games' as num_of_games
from vertices v join edges e
on v.identifier = e.subject_identifier
and v.type = e.subject_type

where e.object_type = 'player'::vertex_type

































