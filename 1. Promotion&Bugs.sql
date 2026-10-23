------------------- In March 2023, the marketing team ran a promotion: the more frequently a player logged into the game, the more free crystals they received. The promotion ran for the first three weeks of March. Can we see a positive impact from this promotion in the metrics?

------------------- We are also planning a new promotion: players who spend the most time in the game will receive bonuses. Our primary focus, however, is on players who registered in 2022.

------------------- We’ve noticed that the `end_session` field is left blank for some sessions. We need to determine the scale of this issue. 


---counting the number of users
select    count(*) as cnt_row  
        , count(id_user) as cnt_reg  
        , count(distinct id_user) as cnt_user   
from skygame.users  


-------------------- finding out the min and max registration dates 
select   max(reg_date) as max_date
, min(reg_date) as min_date
, sum(case when reg_date is null then 1.0 else 0.0 end) as cnt_null
from skygame.users

-------------------- cohorts 
select    date_trunc('month',reg_date) as mm
, count(id_user) as cnt
from skygame.users
group by mm
order by mm


-- MAU, WAU, DAU

select
date_trunc ('day', start_session) as day
	, count (distinct id_user) as "DAU"
from skygame.game_sessions

group by day

---

select date_trunc ('week', start_session) as week
	, count (distinct id_user) as "WAU"
from skygame.game_sessions

group by  week 

---

select date_trunc ('month', start_session) as month
	, count (distinct id_user) as MAU
from skygame.game_sessions

group by month


-- identifying the 25 most active users within the cohorts of interest
select s.id_user
	, sum (extract(epoch from (end_session - start_session))/60) as session_minutes
	from skygame.game_sessions s
	left join skygame.users u
	on s.id_user = u.id_user
where end_session is not null
	and date_trunc ('year', reg_date) = '2022-01-01'

group by s.id_user
order by session_minutes desc
limit 25

-- identifying empty end_session entries for different device types

select dev_type
	, sum (case when end_session is null then 1 else 0 end) as cnt_null_end
	, sum (case when end_session is null then 1.0 else 0.0 end)/count (*) as share_null_end
from skygame.game_sessions s
	left join skygame.users u
	on s.id_user = u.id_user

group by dev_type

--Basic Metrics for PowepPoint are below
--amount of game sessions
select count(*)
from skygame.game_sessions

-- average game session length
select avg(long)
from
(select *
, end_session - start_session as long
from skygame.game_sessions) t 
