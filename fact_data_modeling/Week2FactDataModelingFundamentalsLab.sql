

INSERT INTO fct_game_details
with deduped as (
    select g.game_date_est,
           g.season,
           g.home_team_id,
           gd.*,
           row_number() over (partition by gd.game_id, team_id, player_id order by g.game_date_est) as row_number
    from game_details gd join games g on gd.game_id = g.game_id
)

select
    game_date_est as game_date,
    season as dim_season,
    team_id as dim_team_id,
    player_id as dim_player_id,
    player_name as dim_player_name,
    team_id = home_team_id as dim_playing_at_home,
    start_position as dim_start_position,
    COALESCE(position('DNP' in comment),0) > 0 as dim_did_not_play,
    COALESCE(position('DND' in comment),0) > 0 as dim_did_not_dress,
    COALESCE(position('NWT' in comment),0) > 0 as dim_not_with_team,
    CAST(split_part(min,':',1) as REAL) +
    CAST(split_part(min,':',2) as REAL)/60 as m_minutes,
    fgm as m_fgm,
    fga as m_fga,
    fg3a as m_fg3a,
    fg3m as m_fg3m,
    ftm as m_ftm,
    fta as m_fta,
    oreb as m_oreb,
    dreb as m_dreb,
    reb as m_reb,
    ast as m_ast,
    stl as m_stl,
    blk as m_blk,
    "TO" as m_turnovers,
    pf as m_pf,
    pts as m_pts,
    plus_minus as m_plus_minus
    from deduped
where row_number = 1


select * from fct_game_details



CREATE TABLE fct_game_details (
    game_date date,
    dim_season INTEGER,
    dim_team_id INTEGER,
    dim_player_id INTEGER,
    dim_player_name TEXT,
    dim_playing_at_home BOOLEAN,
    dim_start_position TEXT,
    dim_did_not_play BOOLEAN,
    dim_did_not_dress BOOLEAN,
    dim_not_with_team BOOLEAN,
    m_minutes REAL,
    m_fgm INTEGER,
    m_fga INTEGER,
    m_fg3a INTEGER,
    m_fg3m INTEGER,
    m_ftm INTEGER,
    m_fta INTEGER,
    m_oreb INTEGER,
    m_dreb INTEGER,
    m_reb INTEGER,
    m_ast INTEGER,
    m_stl INTEGER,
    m_blk INTEGER,
    m_turnovers INTEGER,
    m_pf INTEGER,
    m_pts INTEGER,
    m_plus_minus INTEGER,
    PRIMARY KEY (game_date, dim_team_id, dim_player_id)
);