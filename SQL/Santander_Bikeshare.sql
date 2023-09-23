-- SQL codes for Santander Bikeshare datasets
-- In this project, I analyzed the bikes and station usage. 

-- What is the total number of rentals by year? 

SELECT 2016 AS Year
  , count(*) AS Num_rental
FROM santander_2016
UNION
SELECT 2017
  , count(*)
FROM santander_2017
UNION
SELECT 2018
  , count(*)
FROM santander_2018
UNION
SELECT 2019
  , count(*)
FROM santander_2019
ORDER BY 1;


-- What is the number of stations, number of docks, and average number of docks by district? 

SELECT a.district
  , count(*) AS num_station
  , sum(a.docks) AS sum_dock
  , ROUND(AVG(a.docks),0) AS avg_bikes
FROM(
	SELECT *
	, TRIM(SUBSTRING(name, STRPOS(name, ',')+1)) AS district -- extract district from station name
	FROM santander_stations) AS a
GROUP BY 1
ORDER BY 2 DESC;


