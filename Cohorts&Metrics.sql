-- Calculate the monthly trends in total customer payments, broken down by product type.
-- Create a chart and answer the following question: are there any significant changes in recurring revenue over a given period of time?
-- Please note that when calculating revenue, you must use the prices that were in effect at the time of purchase.

select    date_trunc('month',dtime_pay) as mm
        , type
	      , sum(cnt_buy * price) as revenue
from skygame.monetary m
   join skygame.item_list i
      on m.id_item_buy = i.id_item
   join skygame.log_prices p
		  on m.id_item_buy = p.id_item
      and m.dtime_pay >= p.valid_from
      and m.dtime_pay <= coalesce(valid_to, to_date('01/01/3000', 'DD/MM/YYYY'))
group by   mm
         , type
order by mm

--

select * from skygame.log_prices a
join skygame.item_list b
on a.id_item=b.id_item

-- As of January 1, 2023, we increased the price of an individual crystal.
-- Plot the trend for the average number of crystals purchased per transaction.
-- Did the price change affect this metric? Did it also impact the total revenue generated from crystal sales?

select    date_trunc('month',dtime_pay) as mm
				, avg(cnt_buy) as cnt
	      , sum(cnt_buy * price) as revenue
from skygame.monetary m
	   join skygame.item_list i
      on m.id_item_buy = i.id_item
   join skygame.log_prices p
		  on m.id_item_buy = p.id_item
      and m.dtime_pay >= p.valid_from
      and m.dtime_pay <= coalesce(valid_to, to_date('01/01/3000', 'DD/MM/YYYY'))
where name_item = 'Crystal'
group by mm
order by mm

-- We need to determine whether we should distribute our marketing efforts equally across all cohorts. It’s possible that some cohorts are more “generous” when it comes to purchasing in-game items.
-- Calculate the average revenue per person per month for each cohort.

select  *
      ,extract ('day' from ((select max (dtime_pay) from skygame.monetary) - mm )/30) as interv
      ,avg_rev/( extract ('day' from ((select max (dtime_pay) from skygame.monetary) - mm )/30)) avg_rev_per_month
from (select    date_trunc('month', reg_date) as mm
		        , sum(cnt_buy * price) as revenue
		        , count(distinct m.id_user) as cnt
		        , sum(cnt_buy * price) / count(distinct m.id_user) as avg_rev
		from skygame.monetary m
		   join skygame.log_prices p
			  on m.id_item_buy = p.id_item
		      and m.dtime_pay >= p.valid_from
		      and m.dtime_pay <= coalesce(valid_to, to_date('01/01/3000', 'DD/MM/YYYY'))
		   join skygame.users u
		      on m.id_user = u.id_user
		where reg_date < (select max(dtime_pay) - interval '1 month' from skygame.monetary)
		
		group by mm
		order by mm
		) t

--Test the following hypothesis: in November and December 2022, due to more expensive and targeted advertising, we acquired more “loyal” players who spend more time playing our game.

select case when date_trunc ('month', reg_date) between '2022-11-01' and '2022-12-01' then 1 else 0 end as cohort
		, avg (end_session-start_session)
	from skygame.users u
		left join skygame.game_sessions s
		on u.id_user=s.id_user
		where (end_session-start_session) > interval '5 minute'
	group by cohort

-- The november–december 2022 cohort spends 40 minutes longer in the game. The hypothesis is confirmed.

-- Calculate the K-factor for our game.
--Based on this, calculate how many users a single future, average cohort will bring us.

select count (distinct id_user) / count (distinct (date_trunc ('month', reg_date)))
*
	(select sum (ref_reg) as sum_ref_reg
	from skygame.users u
		join skygame.referral r
	 on u.id_user = r.id_user
	)
	/
	(select count (distinct id_user)
	from skygame.users
	) as future_cohort
from skygame.users 
		

-- k-factor
select
    (select sum(ref_reg)::float
     from skygame.users u
     join skygame.referral r
         on u.id_user = r.id_user)
    /
    (select count(distinct id_user)
     FROM skygame.users)

-- Cohort dynamisc
select date_trunc ('month', reg_date) as cohort
		, count (*)
	from skygame.users 
	group by cohort

