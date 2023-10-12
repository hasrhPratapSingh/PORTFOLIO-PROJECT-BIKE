/*PROBLEM STATEMENT - How do annual members and casual riders use Cyclistic bikes differently
*/
-----------------------------------------------------------------------------------------------------------------------------------------------
--** CLEANING THE DATA IN SQL QUERIES **

SELECT *
FROM [dbo].[Divvy_Trips_2019_Q1]


-----------------------------------------------------------------------------------------------------------------------------------------------
-- REMOVING DUPLICATES

-- Step 1: Identifying the duplicates using a CTE and ROW_NUMBER()
WITH CTE AS (
    SELECT
        trip_id,
        ROW_NUMBER() OVER (PARTITION BY trip_id ORDER BY trip_id) AS row_num
    FROM
        [dbo].[Divvy_Trips_2019_Q1]
)
-- Step 2: Deleting the duplicates
DELETE FROM CTE 
WHERE row_num > 1;

-----------------------------------------------------------------------------------------------------------------------------------------------
-- DELETING UNSUED COLUMNS

ALTER TABLE [dbo].[Divvy_Trips_2019_Q1]
DROP COLUMN BIKEID

-----------------------------------------------------------------------------------------------------------------------------------------------
-- REMOVING NULLS

DELETE
FROM [dbo].[Divvy_Trips_2019_Q1]
WHERE  USERTYPE IS NULL OR TRIP_ID IS NULL OR _START_TIME IS NULL OR _End_Time IS NULL 
		OR GENDER IS NULL OR FROM_STATION_ID IS NULL OR FROM_STATION_NAME IS NULL
		OR TO_STATION_NAME IS NULL OR TO_STATION_ID IS NULL OR TRIPDURATION IS NULL
 
-----------------------------------------------------------------------------------------------------------------------------------------------
-- STANDARDIZING DATE FORMAT 

ALTER TABLE [dbo].[Divvy_Trips_2019_Q1]
ADD _Start_Date DATE, _Start_Time TIME, _END_Date DATE,_END_Time TIME

UPDATE [dbo].[Divvy_Trips_2019_Q1]
SET		_Start_Date = CONVERT(DATE, start_time), 
		_Start_Time = CONVERT(TIME, start_time),
		_End_Date = CONVERT(DATE, END_time),
		_End_Time = CONVERT(TIME, END_time)

-----------------------------------------------------------------------------------------------------------------------------------------------
-- ** ANALYZING DATA AND FINDING USEFUL INSIGHTS **
-----------------------------------------------------------------------------------------------------------------------------------------------
/* dividing day into early morning	i.e 4 am - 8am
					 morning		i.e 8am to 12 noon
					 afternoon		i.e 12 noon - 4 pm
					 evening		i.e 4pm to 8 pm
					 night			i.e 8pm to 12 midnight
					 late night		i.e 12am to 4am 
*/.

-- FINDING BUSIEST TIME OF THE DAY FOR CUSTOMER/ CASUAL RIDERS 

select usertype, part_of_day, count(part_of_day) as count_part_of_day 
from
	(	select *, case 
				when datepart(HOUR, _Start_Time) between 0 and 3 then 'late night'
				when datepart(HOUR, _Start_Time) between 4 and 7 then 'early morning'
				when datepart(HOUR, _Start_Time) between 8 and 11 then 'morning'
				when datepart(HOUR, _Start_Time) between 12 and 15 then 'afternoon'
				when datepart(HOUR, _Start_Time) between 16 and 19 then 'evening'
				when datepart(HOUR, _Start_Time) between 20 and 23 then 'night'
			end as part_of_day
		from [dbo].[Divvy_Trips_2019_Q1]
	) as sub
where usertype = 'Customer'
group by part_of_day, usertype
order by count_part_of_day desc

-- BUSIEST TIME OF THE DAY FOR CUSTOMER/ CASUAL RIDERS IS AFTERNOON 12 PM TO 3PM

-- FINDING BUSIEST TIME OF THE DAY FOR SUBSCRIBERS
select usertype, part_of_day, count(part_of_day) as count_part_of_day 
from
	(select *, CASE
				when datepart(HOUR, _Start_Time) between 0 and 3 then 'late night'
				when datepart(HOUR, _Start_Time) between 4 and 7 then 'early morning'
				when datepart(HOUR, _Start_Time) between 8 and 11 then 'morning'
				when datepart(HOUR, _Start_Time) between 12 and 15 then 'afternoon'
				when datepart(HOUR, _Start_Time) between 16 and 19 then 'evening'
				when datepart(HOUR, _Start_Time) between 20 and 23 then 'night'
				end as part_of_day
	from [dbo].[Divvy_Trips_2019_Q1]
	) as sub
where usertype = 'SUBSCRIBER'
group by part_of_day, usertype
order by count_part_of_day desc

-- BUSIEST TIME OF THE DAY FOR SUBSCRIBERS IS EVENING 


-----------------------------------------------------------------------------------------------------------------------------------------------
-- BUSIEST STATION 

select distinct(from_station_name), COUNT(from_station_name) AS COUNT_from_station_name	
FROM [dbo].[Divvy_Trips_2019_Q1]
GROUP BY from_station_name
ORDER BY COUNT(from_station_name) DESC

select TO_station_name, COUNT(to_station_name) AS COUNT_TO_station_name
FROM [dbo].[Divvy_Trips_2019_Q1]
GROUP BY TO_station_name
ORDER BY COUNT(to_station_name) desc

-- Busiest station is Clinton St & Washington Blvd with 7699 rides
-----------------------------------------------------------------------------------------------------------------------------------------------
-- BUSIEST DAY OF THE WEEK 

-- adding new column 
ALTER TABLE [dbo].[Divvy_Trips_2019_Q1]
ADD day_of_week INT

-- adding values to the table 
UPDATE [dbo].[Divvy_Trips_2019_Q1]
SET day_of_week = datepart(WEEKDAY, _Start_Date)

-- maximum occuring day 
select day_of_week, count(day_of_week) as count_of_day
from [dbo].[Divvy_Trips_2019_Q1]
group by day_of_week
order by count(day_of_week) desc

-- therefore, busiest day is day 5 i.e friday

select day_of_week, count(day_of_week) as count_of_day
from [dbo].[Divvy_Trips_2019_Q1]
where usertype = 'Customer'
group by day_of_week
order by count(day_of_week) desc

--busiest day for non member is day 7 i.e sunday

select day_of_week, count(day_of_week) as count_of_day
from [dbo].[Divvy_Trips_2019_Q1]
where usertype = 'Subscriber'
group by day_of_week
order by count(day_of_week) desc

--busiest day for non member is day 5 i.e friday
-----------------------------------------------------------------------------------------------------------------------------------------------

-- AVERAGE RIDE DURATION OF MEMBERS AND CASUAL RIDERS (FOR MALE AND FEMALE)

WITH CTE
AS
(
	  SELECT *
			,CONVERT(varchar(5), DATEPART(HOUR, _Start_Time))  + 
			 RIGHT('0' + CONVERT(varchar(2), DATEPART(MINUTE, _Start_Time)), 2) AS start_HourAndMinute 
			,CONVERT(varchar(5), DATEPART(HOUR, _End_Time)) 
			+ RIGHT('0' + CONVERT(varchar(2), DATEPART(MINUTE, _End_Time)), 2) AS end_HourAndMinute
	  FROM [dbo].[Divvy_Trips_2019_Q1]
)

select usertype, gender, avg((cast(END_HourAndMinute as int)- cast(START_HourAndMinute as int))) as avg_time_USAGE
from CTE
group by usertype, gender
order by usertype, gender


-----------------------------------------------------------------------------------------------------------------------------------------------
-- JOINING LATITUDE LONGITUDE AND FINDING COUNT OF TRIPS


SELECT FROM_STATION_NAME, L.START_LAT, L.START_LNG, COUNT(TRIP_ID) AS COUNT_OF_TRIPS
FROM [dbo].[Divvy_Trips_2019_Q1] Q
JOIN [dbo].[LAT^J LONG] L
ON Q.FROM_STATION_NAME = L.START_STATION_NAME
GROUP BY Q.FROM_STATION_NAME, L.START_LAT, L.START_LNG
ORDER BY COUNT_OF_TRIPS DESC

-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------