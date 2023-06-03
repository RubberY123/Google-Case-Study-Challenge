-- Combine all tables in year 2022
Drop Table if exists Tripdata_2022
Create Table Tripdata_2022(
ride_id nvarchar(255),
rideable_type nvarchar(255),
started_at datetime,
ended_at datetime,
start_station_name nvarchar(255),
start_station_id nvarchar(255),
end_station_name nvarchar(255),
end_station_id nvarchar(255),
start_lat float,
start_lng float,
end_lat float,
end_lng float,
member_casual nvarchar(255))

Insert Into Tripdata_2022
Select * FROM (Select * FROM dbo.Tripdata_202201 
UNION ALL
Select * FROM dbo.Tripdata_202202
UNION ALL
Select * FROM dbo.Tripdata_202203
UNION ALL
Select * FROM dbo.Tripdata_202204
UNION ALL
Select * FROM dbo.Tripdata_202205
UNION ALL
Select * FROM dbo.Tripdata_202206
UNION ALL
Select * FROM dbo.Tripdata_202207
UNION ALL
Select * FROM dbo.Tripdata_202208
UNION ALL
Select * FROM dbo.Tripdata_202209
UNION ALL
Select * FROM dbo.Tripdata_202210
UNION ALL
Select * FROM dbo.Tripdata_202211
UNION ALL
Select * FROM dbo.Tripdata_202212)a




--Find the total type of bike used for Dec2022
Select rideable_type, Count(rideable_type) As Total_Type
FROM dbo.Tripdata_2022
Group by rideable_type
Order by 1
--This shows that electric bike and classic bike has the highest usage.

-- Data Cleansing

--Check duplicates for ride_id
With A (ride_id, Number_of_rides)
as (Select ride_id, count(ride_id) as Number_of_rides 
from dbo.Tripdata_2022
Group by ride_id)
Select ride_id, Number_of_rides
from A
where number_of_rides > 1;
--This shows that each id represents unique rides

--Usage time for all bikes
With B (rideable_type, started_at, ended_at, Total_Travel_Time) AS 
(Select rideable_type, started_at, ended_at, datediff(MINUTE, started_at, ended_at) as Total_Travel_Time
FROM dbo.Tripdata_2022)
Select rideable_type, AVG(Total_Travel_Time) as Average_Travel_Time
FROM B
Group By rideable_type
Order by 2 DESC;
--We could observe that docked bike is used for the longest travel time.

--Check for number of member and casual
WITH C (member_casual, rideable_type, Total_Travel_Time) AS (Select member_casual, rideable_type, datediff(MINUTE, started_at, ended_at) as Total_Travel_Time
FROM dbo.Tripdata_2022)
SELECT member_casual, rideable_type, AVG(Total_Travel_Time) AS Average_Time
FROM C
Group By member_casual, rideable_type
--Tthe data observed stated then annual member are more likely to use electric and classic bike in a shorter average time compared to casual member.
--There are no annual member which uses docked bike. This could state that annual member are likely to purchase membership due to higher usage for shorter distance towards
--their destination such as to their workplace. While, casual members only use the bikes for 1 time usage for longer distance towards their destination, such as for travel.

--Complicated formula to find the percentage of casual and member starting from a station. 
DROP TABLE IF exists Station_Total_2022
Create Table Station_Total_2022(
start_station_name VARCHAR(255), 
member_casual VARCHAR(6),
Total FLOAT)

INSERT INTO Station_Total_2022
Select start_station_name, member_casual, count(start_station_name) As Total
from dbo.Tripdata_202212
Group by start_station_name, member_casual


Select * 
from Station_Total_2022
Order by 2, 3 DESC;

DROP TABLE IF exists Member_Total_2022
Create Table Member_Total_2022(
member_casual VARCHAR(6), 
Total_Member FLOAT)

INSERT INTO Member_Total_2022
Select member_casual, Count(member_casual) As Total_Member
from dbo.Tripdata_2022
Group by member_casual

Select * 
from Member_Total_2022

Select Station_Total_2022.start_station_name, Station_Total_2022.member_casual, 
(Station_Total_2022.Total/Member_Total_2022.Total_Member) * 100 AS Percentage_of_Member
from Station_Total_2022
Join Member_Total_2022
ON Station_Total_2022.member_casual = Member_Total_2022.member_casual
Order by 3 DESC;
--Based on the observation, we could see that most of annual members started their destination from Clark St, Canal St, University Ave and Ellis Ave. 
--While most of the casual bikers started their destination from Streeter Dr. However, we could also observe that most of our bikers started their
--destination from Clark St. We shall look into the top 5 starting destination from our bikers.

Select member_casual, start_station_name, count(member_casual) As Total
from dbo.Tripdata_2022
Group by member_casual, start_station_name order by Total desc
-- It is absurd that there are almost 100,000 data missing
--

--from the start_lat and start_lng we will find out the start_station_name and id
Select start_station_name from dbo.tripdata_2022
where start_lat like 41.93 and start_lng like -87.76 and start_station_name is not null
--We can observe that start_lat and start_lng is not a good indicator for us to fill up the null data as start_station_name has 
--different name such as Public Rack and Lockwood Ave for the same start_lat and start_lng figures.
--Therefore, we could consider removing the null datas

--Added new column Duration
ALTER TABLE Tripdata_2022 ADD Duration FLOAT
UPDATE Tripdata_2022 
Set Duration = datediff(hh, started_at, ended_at)

Select * from dbo.Tripdata_2022
order by Duration DESC

--We have to check why there are no end station recorded, might it be bike lost during cycle? As most riders are casual members