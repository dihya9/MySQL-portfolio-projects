

-- The dataset contains informations about different types of vehicles crashes for multiple years. 
-- I'm going to select the year 2022 crashes data for this project 

-- ---------------------------------------------------------------------------------------------------
# 1- Temporary table to only select the columns needed into a table crash_2022
-- ---------------------------------------------------------------------------------------------------

CREATE TEMPORARY TABLE crash_2022 
AS 
(SELECT `Report Number`,`Local Case Number`,`Agency Name`,`ACRS Report Type`,
`Crash Date/Time`, `Route Type`, `Road Name`, `Collision Type`, `Driver Substance Abuse`, 
`Driver At Fault`, `Vehicle Make`, `Vehicle Model`, `Equipment Problems`, `Crash Date`,
`Crash time` FROM data_crash
WHERE YEAR(`Crash Date/Time`) = 2022);


-- ---------------------------------------------------------------------------------------------------
# 2- Breaking down the column `Crash Date/Time` into two additional columns `Crash Date` and `Crash time` 
-- ---------------------------------------------------------------------------------------------------

ALTER TABLE crash_2022
ADD COLUMN `Crash Date` DATE;

ALTER TABLE crash_2022
ADD COLUMN `Crash time` TIME;


 -- Inserting the values into the new columns 


UPDATE crash_2022
SET `Crash Date`=DATE(`Crash Date/Time`), `Crash time`=TIME(`Crash Date/Time`);


-- ---------------------------------------------------------------------------------------------------
# 3- Total number of crashes reported in 2022 
-- ---------------------------------------------------------------------------------------------------

SELECT COUNT(`Report Number`) AS total_reported_crashes FROM crash_2022;


-- ---------------------------------------------------------------------------------------------------
# Number of recorded crashes per month 
-- ---------------------------------------------------------------------------------------------------

CREATE VIEW monthly_crashes 
AS
SELECT COUNT(`Report Number`) AS reported_crashes 
FROM crash_2022
GROUP BY MONTH(`Crash Date/Time`);

SELECT * FROM monthly_crashes;


-- ---------------------------------------------------------------------------------------------------
# Average number of crashes per month 
-- ---------------------------------------------------------------------------------------------------

SELECT CAST(AVG(reported_crashes) AS DECIMAL(9,2)) AS avg_monthly_crashes
FROM monthly_crashes;


-- ---------------------------------------------------------------------------------------------------
# Average number of daily recoreded carshes per month
-- ---------------------------------------------------------------------------------------------------

SELECT months, CAST(AVG(reported_crashes) AS DECIMAL(9,2)) AS avg_month
FROM 
(SELECT MONTH(`Crash Date/Time`) AS months, DAY(`Crash Date/Time`) AS days, 
COUNT(`Report Number`) AS reported_crashes 
FROM crash_2022
GROUP BY months, days
ORDER BY months, days) AS tab1
GROUP BY 1;


-- ---------------------------------------------------------------------------------------------------
# Number of crashes recorded per each Agency in 2022 from the highest to the lowest with percentages 
-- ---------------------------------------------------------------------------------------------------

CREATE VIEW agency_numbers 
AS 

WITH cte1
AS 
(SELECT COUNT(`Report Number`) AS total_crashes FROM crash_2022),
cte2 
AS
(SELECT `Agency Name` AS Agency, COUNT(`Report Number`) AS reported_crashes
FROM crash_2022
JOIN cte1
GROUP BY `Agency Name`)

SELECT  Agency, reported_crashes, 
CAST(reported_crashes*100/total_crashes AS DECIMAL(9,2)) AS percentage_crashes
FROM cte1 JOIN cte2;

SELECT * FROM agency_numbers;


-- ---------------------------------------------------------------------------------------------------
# Monthly recorded crashes per agency and which agency recorded the highest and lowest crashes numbers per month 
-- ---------------------------------------------------------------------------------------------------

WITH monthly_agency_report
AS 
(SELECT MONTH(`Crash Date/Time`) AS months, `Agency Name` AS agency, 
COUNT(`Report Number`) AS reported_crashes
FROM crash_2022
GROUP BY months, agency
ORDER BY 1)

SELECT *, 
FIRST_VALUE(agency) OVER (PARTITION BY months ORDER BY reported_crashes DESC) AS highest_reported_crashes,
LAST_VALUE(agency) OVER (PARTITION BY months ORDER BY reported_crashes DESC RANGE BETWEEN UNBOUNDED
PRECEDING AND UNBOUNDED FOLLOWING) AS lowest_reported_crashes
FROM
monthly_agency_report; 


-- ---------------------------------------------------------------------------------------------------
# Monthly recorded crashes for agency 'Rockville Police Departme'
-- ---------------------------------------------------------------------------------------------------

SELECT `Agency Name`, MONTH(`Crash Date/Time`) AS months, COUNT(`Report Number`) AS number_
FROM crash_2022
WHERE `Agency Name`= 'Rockville Police Departme'
GROUP BY months
ORDER BY 2;


-- ---------------------------------------------------------------------------------------------------
# Distribution of report types and percentages 
-- ---------------------------------------------------------------------------------------------------

CREATE VIEW report_types
AS
SELECT `ACRS Report Type` AS outcome, COUNT(`ACRS Report Type`) AS reported_number,
COUNT(`ACRS Report Type`)*100/(SELECT COUNT(`ACRS Report Type`) FROM crash_2022) AS percentages 
FROM crash_2022
GROUP BY 1
ORDER BY 2 DESC; 

SELECT * FROM report_types;


-- ---------------------------------------------------------------------------------------------------
# Adding an `ACRS Report Type` derived column to tell if a crash was fatal or not
-- ---------------------------------------------------------------------------------------------------

ALTER TABLE crash_2022
ADD COLUMN fatality text NOT NULL;

SELECT fatality FROM crash_2022;


-- ---------------------------------------------------------------------------------------------------
# Inserting values into the new added column 
-- ---------------------------------------------------------------------------------------------------

UPDATE crash_2022 
SET fatality=
CASE 
WHEN `ACRS Report Type` = 'Fatal Crash' THEN 'Fatal'
ELSE 'Non Fatal'
END; 

SELECT fatality, count(fatality) from crash_2022 group by 1;


-- ---------------------------------------------------------------------------------------------------
# Number of fatal and non fatal reported crashes with percentages 
-- ---------------------------------------------------------------------------------------------------

 -- Defining '@total_reported' user variable as the total number of reported crashes 

SET @total_reported := (SELECT COUNT(`Report Number`) AS total_reported_crashes FROM crash_2022);

SELECT fatality, COUNT(fatality) AS reported_count, 
COUNT(fatality)*100/@total_reported AS percentages
FROM crash_2022
GROUP BY 1;


-- ---------------------------------------------------------------------------------------------------
# Agencies that recorded fatal crashes with the numbers
-- ---------------------------------------------------------------------------------------------------

SELECT `Agency Name` AS agency, COUNT(fatality) AS fatal_crashes
FROM crash_2022
WHERE fatality='Fatal'
GROUP BY 1;

-- Not all agencies registered fatal crashes


-- ---------------------------------------------------------------------------------------------------
# Number of fatal and non fatal crashes reported per each agency 
-- ---------------------------------------------------------------------------------------------------

WITH cte_fatal
AS
(SELECT `Agency Name` AS agency, COUNT(fatality) AS number_fatal_carshes 
FROM crash_2022
WHERE fatality='Fatal'
GROUP BY 1),
cte_non_fatal
AS
(SELECT `Agency Name` AS agency, COUNT(fatality) AS number_fatal_carshes 
FROM crash_2022
WHERE fatality='Non Fatal'
GROUP BY 1)
 
SELECT * from cte_fatal RIGHT JOIN cte_non_fatal USING(agency);


-- ---------------------------------------------------------------------------------------------------
# How many carshes were recorded by the agency 'Montgomery County Police' between the dates of '2022-02-15' AND '2022-07-10'
-- ---------------------------------------------------------------------------------------------------

SELECT `Agency Name` AS agency, fatality, COUNT(`Report Number`) AS number_crashes 
FROM crash_2022
WHERE `Agency Name`='Montgomery County Police'
AND (DATE(`Crash Date/Time`) BETWEEN '2022-02-15' AND '2022-07-10')
GROUP BY fatality;


-- ---------------------------------------------------------------------------------------------------
# 5 dates on which the highest numbers of crashes were recorded 
-- ---------------------------------------------------------------------------------------------------

SELECT `Crash Date`, COUNT(`Report Number`) AS number_crashes 
FROM crash_2022
GROUP BY `Crash Date`
ORDER BY 2 DESC LIMIT 5;


-- ---------------------------------------------------------------------------------------------------
# Day on which the most number of crashes were recorded 
-- ---------------------------------------------------------------------------------------------------

SELECT `Crash Date`, COUNT(`Report Number`) AS number_crashes
FROM crash_2022
GROUP BY `Crash Date`
ORDER BY 2 DESC
LIMIT 1;


-- ---------------------------------------------------------------------------------------------------
# Day on which the most number of crashes were recorded by fatality value
-- ---------------------------------------------------------------------------------------------------

(SELECT `Crash Date`, fatality, COUNT(`Report Number`) AS number_crashes
FROM crash_2022
WHERE fatality = 'Non Fatal'
GROUP BY `Crash Date`
ORDER BY 3 DESC
LIMIT 1)
UNION
(SELECT `Crash Date`, fatality, COUNT(`Report Number`) AS number_crashes
FROM crash_2022
WHERE fatality = 'Fatal' 
GROUP BY `Crash Date`
ORDER BY 3 DESC
LIMIT 1);


-- ---------------------------------------------------------------------------------------------------
# Time frame where the most accidents happened 
-- ---------------------------------------------------------------------------------------------------

-- Number of total accidents recorded at the same hour

CREATE VIEW hours_crashes
AS
SELECT HOUR(`Crash Date/Time`) AS hours, COUNT(HOUR(`Crash Date/Time`)) AS crashes_hour
FROM crash_2022
GROUP BY hours
ORDER BY 2;

SELECT * FROM hours_crashes ;

-- Average number of crashes per hour

SET @avg_hourly_crashes := CAST((SELECT AVG(crashes_hour) FROM hours_crashes) AS DECIMAL(9,2));

SELECT @avg_hourly_crashes;

-- Labeling frames of time (in hours) according to the number of crashes recorded per each hour

SELECT *, 
CASE 
WHEN crashes_hour >= 1000 THEN 'Highest_risk_hour'
ELSE  
CASE
WHEN crashes_hour > @avg_hourly_crashes THEN 'Above_avg_risk'
ELSE 'Under_avg_risk'
END 
END
 AS risk_level
FROM hours_crashes 
ORDER BY 2 DESC;

-- Four time frames can be drawn:

# 7h - 13h = Number of crashes are above the average crashes number
# 14h - 17h = Risk level is at its highest 
# 18h - 19h = The number of crashes decreases under the 1000 but is above the average crashes number
# 20h - 6h =  The number of crashes is below the average number of crashes, the risk is at its lowest


-- ---------------------------------------------------------------------------------------------------
# Ranking of hours according to the number of 'Fatal' type crashes recorded 
-- ---------------------------------------------------------------------------------------------------

WITH cte 
AS
(SELECT HOUR(`Crash Date/Time`) AS hours, fatality, COUNT(HOUR(`Crash Date/Time`)) AS crashes_hour
FROM crash_2022
WHERE fatality='Fatal'
GROUP BY hours, fatality
ORDER BY 3 DESC)

SELECT *, CAST(PERCENT_RANK() OVER (ORDER BY crashes_hour DESC)*100 AS DECIMAL(9,2)),
CAST(CUME_DIST() OVER (ORDER BY crashes_hour DESC) *100 AS DECIMAL(9,2))
FROM cte;


-- ---------------------------------------------------------------------------------------------------
# Route type with the highest number of crashes
-- ---------------------------------------------------------------------------------------------------

SELECT `Route Type`, COUNT(`Route Type`) 
FROM crash_2022
GROUP BY `Route Type`
LIMIT 1;


-- ---------------------------------------------------------------------------------------------------
# Collision type ranking according to fatality risk 
-- ---------------------------------------------------------------------------------------------------

-- Fatal

SELECT `Collision Type`, fatality, COUNT(`Collision Type`) AS collisions_count
FROM crash_2022
WHERE fatality='Fatal'
GROUP BY `Collision Type`
ORDER BY 3 DESC;

-- Non Fatal

SELECT `Collision Type`, fatality, COUNT(`Report Number`) AS collisions_count
FROM crash_2022
WHERE fatality='Non Fatal'
GROUP BY `Collision Type`
ORDER BY 3 DESC;


-- ---------------------------------------------------------------------------------------------------
# Percentage of crashes according to the driver's responsibilty in a crash 
-- ---------------------------------------------------------------------------------------------------

SELECT `Driver At Fault`, fatality, COUNT(`Report Number`),  
COUNT(`Report Number`)*100/@total_reported
FROM crash_2022
GROUP BY `Driver At Fault`, fatality;


-- ---------------------------------------------------------------------------------------------------
# Number of cashes due to some type of illegal substance intake or presence with percetages
-- ---------------------------------------------------------------------------------------------------

SELECT DISTINCT `Driver Substance Abuse` FROM crash_2022;

CREATE VIEW subsatance_abuse
AS
WITH cte1
AS
(SELECT `Driver Substance Abuse`, COUNT(`Report Number`) AS number_crashes
FROM crash_2022
WHERE `Driver Substance Abuse` NOT IN ('UNKNOWN', '', 'NONE DETECTED') 
GROUP BY `Driver Substance Abuse`),

cte2 AS 
(SELECT COUNT(`Report Number`) AS count_crashes
FROM crash_2022
WHERE `Driver Substance Abuse` NOT IN ('UNKNOWN', '', 'NONE DETECTED'))

SELECT *, number_crashes*100/count_crashes AS percentage_crashes
FROM cte1 JOIN cte2;

SELECT * FROM subsatance_abuse;


-- ---------------------------------------------------------------------------------------------------
# Cumulative distribution of the number of crashes where some kind of illegal substance was involved
-- ---------------------------------------------------------------------------------------------------

SELECT * , CAST( CUME_DIST() OVER (ORDER BY number_crashes DESC) *100 AS DECIMAL(9,2)) AS cume_distr 
FROM subsatance_abuse;


-- ---------------------------------------------------------------------------------------------------
# Number and percentage of crashes registered per vehicle body type 
-- ---------------------------------------------------------------------------------------------------

CREATE VIEW body_type_crashes
AS
WITH cte 
AS
(SELECT `Vehicle Body Type` , COUNT(`Report Number`) AS crashes_number
FROM crash_2022
GROUP BY `Vehicle Body Type`)

SELECT *, 
CAST(crashes_number*100/(SELECT COUNT(`Report Number`) FROM crash_2022) AS DECIMAL(9,2)) AS percentages
FROM cte
WHERE `Vehicle Body Type` <> '' 
ORDER BY 2 DESC;

SELECT * FROM body_type_crashes;


