create type film as (
    film TEXT,
    votes INTEGER,
    rating float4,
    filmId TEXT,
    year INTEGER
                 );


create type quality_class as ENUM ('star', 'good', 'average', 'bad');

create table actors(
    actor_id TEXT,
    actor_name TEXT,
    films film[],
    quality_class quality_class,
    is_active boolean,
    current_year integer,
    primary key (actor_id,current_year)
);


with
    with_last_year as (select * from actors where current_year = 1969),
    with_this_year as (
        select
            actorid,
            actor,
            year,
            max(year) as max_year,
            avg(rating) as avg_rating,
            array_agg(array[row(film, votes, rating, filmid, year)::film]) as films
        from actor_films
        where year = 1970
        group by actorid, actor, year
    )
    insert into actors
select
    coalesce(l.actor_id, t.actorid) as actor_id,
    coalesce(l.actor_name, t.actor) as actor_name,
    coalesce(l.films, array[]::film[])
    || case when t.year is not null then t.films else array[]::film[] end as films,
    case
        when t.avg_rating > 8
        then 'star'
        when t.avg_rating > 7 and t.avg_rating <= 8
        then 'good'
        when t.avg_rating > 6 and t.avg_rating <= 7
        then 'average'
        when t.avg_rating >= 6
        then 'bad'
    end::quality_class as quality_class,
    max_year is not null as is_active,
    1970 as current_year

from with_last_year l
full outer join with_this_year t on l.actor_id = t.actorid
;
