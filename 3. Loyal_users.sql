-- Calculation of LMAU, LDAU, LWAU
-- Let’s assume that a “loyal” user is defined as one who has invited at least three friends, with at least one of them subsequently registering for our game.

with crit_invite as 
(
select    id_user
from skygame.referral
group by id_user
having count(*) >= 3
  and sum(ref_reg) >= 1
)
select    count(distinct id_user) as cnt_user
, date_trunc('day', start_session) as mm
from skygame.game_sessions
where id_user in (select * from crit_invite)
group by mm

--- Let’s assume that a “loyal” user is defined as one who has paid a cumulative total of more than 1,000 currency units over the entire period (non-strictly).

with crit_1000 as 
(
select   id_user
from skygame.monetary m
  join skygame.item_list i
     on m.id_item_buy = i.id_item
  join skygame.log_prices p
		 on m.id_item_buy = p.id_item
     and m.dtime_pay >= p.valid_from
     and m.dtime_pay <= coalesce(p.valid_to, '3000-01-01')
group by id_user
having sum(cnt_buy * price) >= 1000
)

select   count(distinct id_user) as cnt_user
,date_trunc('month', start_session) as mm
from skygame.game_sessions
where id_user in (select * from crit_1000)
group by mm


-- Combibng both conditions

with loyals1 as 
(
select    id_user
from skygame.monetary m
   join skygame.item_list i
      on m.id_item_buy = i.id_item
   join skygame.log_prices p
		  on m.id_item_buy = p.id_item
      and m.dtime_pay >= p.valid_from
      and m.dtime_pay <= coalesce(valid_to, '3000-01-01')
group by id_user
having sum(cnt_buy * price) >= 1000
),
loyals2 as 
(
select    id_user
from skygame.referral
group by id_user
having count(*) >= 3
  and sum(ref_reg) >= 1
)

select    count(distinct id_user) as cnt_user
, date_trunc('month', start_session) as mm
from skygame.game_sessions
where id_user in (select * from loyals1)
and id_user in (select * from loyals2)
group by mm


-- Now any of the conditions is suitable

with loyals1 as 
(
select    id_user
from skygame.monetary m
   join skygame.item_list i
      on m.id_item_buy = i.id_item
   join skygame.log_prices p
		  on m.id_item_buy = p.id_item
      and m.dtime_pay >= p.valid_from
      and m.dtime_pay <= coalesce(valid_to, '3000-01-01')
group by id_user
having sum(cnt_buy * price) >= 1000
),
loyals2 as 
(
select    id_user
from skygame.referral
group by id_user
having count(*) >= 3
  and sum(ref_reg) >= 1
)

select    count(distinct id_user) as cnt_user
, date_trunc('month', start_session) as mm
from skygame.game_sessions
where id_user in (select * from loyals1)
or id_user in (select * from loyals2)
group by mm
