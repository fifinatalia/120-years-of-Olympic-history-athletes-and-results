create database olympics;
use olympics;

drop table if exists olympic_history;
create table if not exists olympic_history
(
	id 		int,
	name 	varchar(25),
	sex 	varchar (5),
	age 	varchar (5),
	height 	varchar (5),
	weight 	varchar (5),
	team 	varchar (20),
	noc 	varchar (3),
	games 	varchar (50),
	year 	int,
	season 	varchar (10),
	city 	varchar (50),
	sport 	varchar (50),
	event 	varchar (50),
	medal 	varchar (10)
);

drop table if exists olympics_history_noc_region;
create table if not exists olympics_history_noc_region
(
	noc 	varchar (3),
	region 	varchar (25),
	note 	varchar (25)
);

select * from athlete_events;

-- 1. How many olympics games have been held?
	select count(distinct games) as total_olympic_games
    from olympic_history;

--  2. List down all Olympics games held so far. (Data issue at 1956-"Summer"-"Stockholm")
    select distinct oh.year,oh.season,oh.city
    from olympic_history oh
    order by year;

--  3. Mention the total no of nations who participated in each olympics game?
    with all_countries as
        (select games, nr.region
        from olympic_history oh
        join olympics_history_noc_region nr ON nr.noc = oh.noc
        group by games, nr.region)
    select games, count(1) as total_countries
    from all_countries
    group by games
    order by games;
    
-- 4. Which year saw the highest and lowest no of countries participating in olympics

      with all_countries as
              (select games, nr.region
              from olympic_history oh
              join olympics_history_noc_region nr ON nr.noc=oh.noc
              group by games, nr.region),
          tot_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)
      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;

-- 5. Which nation has participated in all of the olympic games
	select count(distinct games) as no_of_years, team from olympics_history
	group by team
	order by no_of_years desc
	limit 4;

-- 6. Identify the sport which was played in all summer olympics.
      with t1 as
          	(select count(distinct games) as total_games
          	from olympic_history where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from olympic_history where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select *
      from t3
      join t1 on t1.total_games = t3.no_of_games;

-- 7. Which Sports were just played only once in the olympics.
      with t1 as
          	(select distinct games, sport
          	from olympic_history),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;

-- 8. Fetch the total no of sports played in each olympic games.
	select distinct games, count(distinct sport) as no_of_sport
	from olympic_history
	group by games
	order by no_of_sport desc;

-- 9. Fetch oldest athletes to win a gold medal
	select 
		name,
		team,
		noc,
        games,
        sport,
		(case when age = 'NA' then '0' else age end) as age
	from olympic_history
	where medal ='Gold'
	order by age desc
	limit 2;

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
    with t1 as
        	(select sex, count(1) as cnt
        	from olympic_history
        	group by sex),
            
        t2 as
        	(select *, row_number() over(order by cnt) as rn
        	 from t1),
       
       min_cnt as
        	(select cnt from t2	where rn = 1),
            
        max_cnt as
        	(select cnt from t2	where rn = 2)
            
    select concat('1 : ', round(max_cnt.cnt/min_cnt.cnt, 2)) as ratio
    from min_cnt, max_cnt;

-- 11. Top 5 athletes who have won the most gold medals.
    with t1 as
            (select name, team, count(1) as total_gold_medals
            from olympics_history
            where medal = 'Gold'
            group by name, team
            order by total_gold_medals desc),
            
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)
            
    select name, team, total_gold_medals
    from t2
    where rnk <= 5;

-- 12. Top 5 athletes who have won the most medals (gold/silver/bronze).
    with t1 as
            (select name, team, count(1) as total_medals
            from olympic_history
            where medal in ('Gold', 'Silver', 'Bronze')
            group by name, team
            order by total_medals desc),
            
        t2 as
            (select *, dense_rank() over (order by total_medals desc) as rnk
            from t1)
            
    select name, team, total_medals
    from t2
    where rnk <= 5;

-- 13. Top 5 most successful countries in olympics. Success is defined by no of medals won.
    with t1 as
            (select nr.region, count(1) as total_medals
            from olympic_history oh
            join olympics_history_noc_region nr on nr.noc = oh.noc
            where medal <> 'NA'
            group by nr.region
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over(order by total_medals desc) as rnk
            from t1)
    select *
    from t2
    where rnk <= 5;

-- 14. List down total gold, silver and broze medals won by each country.
	select noc,
		sum(case when medal='Gold' then 1 else 0 end) as gold_count,
		sum(case when medal='Silver' then 1 else 0 end) as silver_count,
		sum(case when medal='Bronze' then 1 else 0 end) as bronze_count
	from olympic_history
	group by noc
	order by gold_count desc;

-- 15. List down total gold, silver and broze medals won by each country corresponding to each olympic games.
    select noc,games,
		sum(case when medal='Gold' then 1 else 0 end) as gold_count,
		sum(case when medal='Silver' then 1 else 0 end) as silver_count,
		sum(case when medal='Bronze' then 1 else 0 end) as bronze_count
	from olympic_history
	group by noc,games
	order by gold_count desc;
    
-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
	with final_t as (select noc,games,
		sum(case when medal='Gold' then 1 else 0 end) as gold_count,
		sum(case when medal='Silver' then 1 else 0 end) as silver_count,
		sum(case when medal='Bronze' then 1 else 0 end) as bronze_count
	from olympic_history
	group by noc,games
	order by games desc),

		t1 as(select games,max(gold_count) g, max(silver_count) s,max(bronze_count ) b
			from final_t
			group by games
			order by games),

		gold as(
			select t.games, concat(t.g, '-',f.noc) as Gold_Max
			from final_t f , t1 t
			where f.gold_count= t.g and f.games=t.games ),

		silver as (select t.games,concat(t.s,'-',f.noc) as Silver_Max
			from final_t f , t1 t
			where f.silver_count= t.s and f.games=t.games ),

		bronze as (select t.games, concat(t.b,'-',f.noc) as Bronze_Max
			from final_t f , t1 t
			where f.bronze_count= t.b and f.games=t.games )

	select gl.games,Gold_Max, Silver_max,Bronze_max
	from gold gl, silver sl,bronze bl
	where gl.games=sl.games and sl.games=bl.games and bl.games= gl.games
	order by gl.games;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

   with final_t as (select noc,games,
		sum(case when medal='Gold' then 1 else 0 end) as gold_count,
		sum(case when medal='Silver' then 1 else 0 end) as silver_count,
		sum(case when medal='Bronze' then 1 else 0 end) as bronze_count
	from olympic_history
	group by noc,games
	order by games desc),

		t1 as(select games,max(gold_count) g, max(silver_count) s,max(bronze_count ) b
			from final_t
			group by games
			order by games),

		gold as(
			select t.games, concat(t.g, '-',f.noc) as Gold_Max
			from final_t f , t1 t
			where f.gold_count= t.g and f.games=t.games ),

		silver as (select t.games,concat(t.s,'-',f.noc) as Silver_Max
			from final_t f , t1 t
			where f.silver_count= t.s and f.games=t.games ),

		bronze as (select t.games, concat(t.b,'-',f.noc) as Bronze_Max
			from final_t f , t1 t
			where f.bronze_count= t.b and f.games=t.games ),

	final_16 as(select gl.games,Gold_Max, Silver_max,Bronze_max
				from gold gl, silver sl,bronze bl
				where gl.games=sl.games and sl.games=bl.games and bl.games= gl.games
				order by gl.games),

	total as(select games,noc, sum(gold_count + silver_count + bronze_count) as total_metal
	from final_t
	group by games, noc
	order by games),

	max_m as(select games,max(total_metal) as max_m
	from total
	group by games),

	max_medals as (select t.games, concat(t.noc,'-',m.max_m) as max_medals
	from total t,max_m m
	where t.total_metal=m.max_m and t.games=m.games)

	select f16.games,Gold_Max, Silver_max,Bronze_max,max_medals
	from final_16 f16 join max_medals mm
	on f16.games=mm.games;
    
-- 18. Which countries have never won gold medal but have won silver/bronze medals?

	with t1 as
			(select Distinct Region,
			sum(Case when Medal='Gold' then 1 else 0 end) as Gold,
			sum(Case when Medal='Silver' then 1 else 0 end) as Silver,
			sum(Case when Medal='Bronze' then 1 else 0 end) as Bronze
			from olympic_history oh
			join olympic_history_noc_region nr on oh.noc=nr.noc
			group by region),

	t2 as
		(select * from t1
		where Gold=0 and (Silver > 0 or Bronze > 0))

	select * from t2 order by 2,3 desc;

-- 19. In which Sport/event, India has won highest medals.
    with t1 as
        	(select sport, count(1) as total_medals
        	from olympic_history
        	where medal <> 'NA'
        	and team = 'India'
        	group by sport
        	order by total_medals desc),
        t2 as
        	(select *, rank() over(order by total_medals desc) as rnk
        	from t1)
    select sport, total_medals
    from t2
    where rnk = 1;

-- 20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games
    select team, sport, games, count(1) as total_medals
    from olympic_history
    where medal <> 'NA'
    and team = 'India' and sport = 'Hockey'
    group by team, sport, games
    order by total_medals desc;
