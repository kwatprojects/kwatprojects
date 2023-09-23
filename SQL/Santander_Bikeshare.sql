-- SQL codes for Santander Bikeshare datasets
-- In this project, I analyzed the bikes and station usage. 


-- What is the total number of rentals by year? 

with a AS (
	SELECT * FROM santander_2016
	UNION 
	SELECT * FROM santander_2017
	UNION 
	SELECT * FROM santander_2018
	UNION
	SELECT * FROM santander_2019
)

SELECT EXTRACT(YEAR FROM a.start_date) AS year
	,COUNT(*) AS Num_rental
FROM a
GROUP BY year;



-- What is the number of stations, number of docks, and average number of docks by district? 

SELECT a.district
  ,count(*) AS num_station
  ,sum(a.docks) AS sum_dock
  ,ROUND(AVG(a.docks),0) AS avg_bikes
FROM(
	SELECT *
	,TRIM(SUBSTRING(name, STRPOS(name, ',')+1)) AS district -- extract district from station name
	FROM santander_stations) AS a
GROUP BY 1
ORDER BY 2 DESC;



-- Which are the top 20 most popular stations for bike pickup (start stations), and which districts are they in (2016-2019)? 

SELECT *
FROM (
SELECT a.startstationid
	,c.name
	,TRIM(SUBSTRING(c.name, STRPOS(c.name, ',')+1)) AS district
	,count(a.startstationid) AS num_rental,
	,RANK() OVER( ORDER BY count(a.startstationid) DESC) AS ranking
	,EXTRACT(YEAR FROM a.start_date) AS year
FROM santander_2016 AS a
LEFT JOIN santander_stations AS c ON a.startstationid = c.id
GROUP BY 1,2,3,6
UNION
SELECT a.startstationid
	,c.name
	,TRIM(SUBSTRING(c.name, STRPOS(c.name, ',')+1))
	,count(a.startstationid)
	,RANK() OVER( ORDER BY count(a.startstationid) DESC) AS ranking
	,EXTRACT(YEAR FROM a.start_date) AS YEAR
FROM santander_2017 AS a
LEFT JOIN santander_stations AS c ON a.startstationid = c.id
GROUP BY 1,2,3,6
UNION
SELECT a.startstationid
	,c.name
	,TRIM(SUBSTRING(c.name, STRPOS(c.name, ',')+1))
	,count(a.startstationid)
	,RANK() OVER( ORDER BY count(a.startstationid) DESC) AS ranking
	,EXTRACT(YEAR FROM a.start_date) AS YEAR
FROM santander_2018 AS a
LEFT JOIN santander_stations AS c ON a.startstationid = c.id
GROUP BY 1,2,3,6
UNION
SELECT a.startstationid
	,c.name, 
	,TRIM(SUBSTRING(c.name, STRPOS(c.name, ',')+1))
	,count(a.startstationid)
	,RANK() OVER( ORDER BY count(a.startstationid) DESC) AS ranking
	,EXTRACT(YEAR FROM a.start_date) AS YEAR
FROM santander_2019 AS a
LEFT JOIN santander_stations AS c ON a.startstationid = c.id
GROUP BY 1,2,3,6) AS tempdf
WHERE tempdf.ranking <=20
ORDER BY tempdf.ranking, tempdf.year;



-- What is the number of bike pickups and average trip duration (mins) by year, month, day of week (dow), and hour?

SELECT EXTRACT(YEAR FROM start_date) AS year
	,EXTRACT(MONTH FROM start_date) AS month
	,EXTRACT(DOW FROM start_date) AS dow
	,EXTRACT(HOUR FROM start_date) AS hour
	,COUNT(startstationid) AS num_pickup
	,ROUND(CAST(AVG(extract(EPOCH from end_date - start_date)/60) AS numeric),0) AS avg_dur_mins -- extract duration in minutes
FROM santander_2016
GROUP BY 1,2,3,4
UNION
SELECT EXTRACT(YEAR FROM start_date) AS year
	,EXTRACT(MONTH FROM start_date) AS month
	,EXTRACT(DOW FROM start_date) AS dow
	,EXTRACT(HOUR FROM start_date) AS hour
	,COUNT(startstationid) AS num_pickup
	,ROUND(CAST(AVG(extract(EPOCH from end_date - start_date)/60) AS numeric),0) AS avg_dur_mins -- extract duration in minutes
FROM santander_2017
GROUP BY 1,2,3,4
UNION
SELECT EXTRACT(YEAR FROM start_date) AS year
	,EXTRACT(MONTH FROM start_date) AS month
	,EXTRACT(DOW FROM start_date) AS dow
	,EXTRACT(HOUR FROM start_date) AS hour
	,COUNT(startstationid) AS num_pickup
	,ROUND(CAST(AVG(extract(EPOCH from end_date - start_date)/60) AS numeric),0) AS avg_dur_mins -- extract duration in minutes
FROM santander_2018
GROUP BY 1,2,3,4
UNION
SELECT EXTRACT(YEAR FROM start_date) AS year
	,EXTRACT(MONTH FROM start_date) AS month
	,EXTRACT(DOW FROM start_date) AS dow
	,EXTRACT(HOUR FROM start_date) AS hour
	,COUNT(startstationid) AS num_pickup
	,ROUND(CAST(AVG(extract(EPOCH from end_date - start_date)/60) AS numeric),0) AS avg_dur_mins -- extract duration in minutes
FROM santander_2019
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4;


-- During business hours on weekdays, which were the top 10 busiest stations? What was the number of pickups and returns by day, hour for each of these station? 
-- filter: 7-10am, 4-7pm, Mon-Fri, top 10 highest traffic stations

SELECT e.*, f.avg_return, (f.avg_return - e.avg_pickup) AS diff, g.docks, g.docks+(f.avg_return - e.avg_pickup) AS net_docks
FROM -- Avg pickups by day, hour, station over the year -> e
(SELECT 
	b.hour
	,b.startstationid
	,ROUND(AVG(b.num_pickup),0) AS avg_pickup
FROM  -- # Pickups by day, hour, station -> b
(SELECT 
	EXTRACT(DOY FROM a.start_date) AS doy
	,EXTRACT(HOUR FROM a.start_date) AS hour
	,a.startstationid
	,COUNT(a.startstationid) AS num_pickup
FROM santander_2019 AS a  -- rental info -> a
WHERE ((EXTRACT(HOUR FROM a.start_date) BETWEEN 7 AND 10)  -- filter for 7-10am
 		OR (EXTRACT(HOUR FROM a.start_date) BETWEEN 16 AND 19)) -- filter for 4-7pm
		AND EXTRACT(DOW FROM a.start_date) BETWEEN 1 AND 5  -- filter for Mon-Fri
 		AND a.startstationid IN (SELECT x.startstationid
			 FROM(SELECT startstationid, COUNT(startstationid)
					 FROM santander_2019
					 GROUP BY 1
					 ORDER BY 2 DESC LIMIT 10) AS x) -- filter for top 10 high traffic start stations
GROUP BY 1,2,3) AS b
GROUP BY 1,2) AS e

LEFT JOIN -- join e&f

(SELECT -- Avg returns by day, hour, station over the year -> f
	d.hour
	,d.endstationid
	,ROUND(AVG(d.num_return),0) AS avg_return
FROM  -- # returns by day, hour, station -> d
(SELECT 
	EXTRACT(DOY FROM c.end_date) AS doy
	,EXTRACT(HOUR FROM c.end_date) AS hour
	,c.endstationid
	,COUNT(c.endstationid) AS num_return
FROM santander_2019 AS c
WHERE ((EXTRACT(HOUR FROM c.end_date) BETWEEN 7 AND 10)  -- filter for 7-10am
 		OR (EXTRACT(HOUR FROM c.end_date) BETWEEN 16 AND 19))  -- filter for 4-7pm
		AND EXTRACT(DOW FROM c.end_date) BETWEEN 1 AND 5  -- filter for Mon-Fri
 		AND c.endstationid IN (SELECT x.startstationid
			 FROM(SELECT startstationid, COUNT(startstationid)
					 FROM santander_2019
					 GROUP BY 1
					 ORDER BY 2 DESC LIMIT 10) AS x) -- filter for top 10 high traffic start stations
GROUP BY 1,2,3) AS d
GROUP BY 1,2) AS f

ON e.startstationid = f.endstationid AND e.hour = f.hour -- join based on station id & hour

JOIN santander_stations AS g -- join e&f &g
on e.startstationid = g.id
ORDER BY 2,1;
 
