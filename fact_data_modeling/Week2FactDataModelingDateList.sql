select * from events e 


select  * from users_cumulated uc 


with yesterday as (
	select * from users_cumulated uc 
	where date = DATE('2022-12-31')

),

today as (
	select cast(user_id as text) as user_id, 
	DATE(cast(event_time as timestamp)) as date_active 
	from events e 
	where DATE(cast(event_time as timestamp)) = DATE ('2023-01-01') 
	and user_id is not null 
	group by user_id,date_active
)

select 
	coalesce (t.user_id, y.user_id) as user_id,
	case when y.dates_active is null
	then ARRAY[t.date_active] END
	as dates_active,
	coalesce (date_active, y.date + interval '1 day') as date

from today t
full outer join yesterday y
on t.user_id = y.user_id
















--drop table users_cumulated 


create table users_cumulated
(
	user_id TEXT,
	dates_active date[],
	date date,
	primary key (user_id,date)
)