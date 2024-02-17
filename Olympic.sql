SELECT * FROM olympics.athlete_events;
SELECT * FROM olympics.noc_regions;
Use OLYMPICS;

-- 1. How many Olympic games have been held?
SELECT COUNT(DISTINCT(Games)) AS 'Total_Number_Of_Games' 
FROM athlete_events;

-- 2. List down all Olympic games held so far.
SELECT DISTINCT(Games),Year,City 
FROM athlete_events
ORDER BY Year ;

-- 3. Mention the total number of nations that participated in each Olympic game.
SELECT Games,COUNT(DISTINCT region) AS 'Total_Participated_Regions'
FROM athlete_events t1
JOIN noc_regions t2 
ON t1.NOC=t2.NOC 
GROUP BY Games
ORDER BY Games;

-- 4. Which year saw the highest and lowest number of countries participating in the Olympics?

-- Using Set Operation Function
(SELECT Games,COUNT(DISTINCT region) AS 'Total_Participated_Regions'
FROM athlete_events t1
JOIN noc_regions t2 ON t1.NOC=t2.NOC 
GROUP BY Games ORDER BY Games ASC LIMIT 1)
UNION 
(SELECT Games,COUNT(DISTINCT region) AS 'Total_Participated_Regions'
FROM athlete_events t1
JOIN noc_regions t2 ON t1.NOC=t2.NOC 
GROUP BY Games ORDER BY Games DESC LIMIT 1);

-- Using Window Function
WITH ParticipationCounts AS (
SELECT Games,COUNT(DISTINCT region) AS Total_Participated_Regions,
RANK() OVER (ORDER BY COUNT(DISTINCT region) DESC) AS Participation_Rank_Desc,
RANK() OVER (ORDER BY COUNT(DISTINCT region) ASC) AS Participation_Rank_Asc
FROM athlete_events t1
JOIN noc_regions t2 ON t1.NOC = t2.NOC
GROUP BY Games)
SELECT Games,Total_Participated_Regions
FROM ParticipationCounts
WHERE Participation_Rank_Desc = 1 OR Participation_Rank_Asc = 1;

-- 5. Which nation has participated in all of the Olympic games?
WITH CTE AS (SELECT region,COUNT(DISTINCT Games) AS 'Total_Games_Participation' FROM noc_regions t1
JOIN athlete_events t2 
ON t1.NOC=t2.NOC 
GROUP BY region
ORDER BY region)
SELECT * FROM CTE 
WHERE Total_Games_Participation=(SELECT MAX(Total_Games_Participation) FROM CTE);

-- 6. Identify the sport played in all Summer Olympics.
SELECT Games,Sport FROM athlete_events
WHERE Season='Summer'
ORDER BY Games;

-- 7. Which sports were played only once in the Olympics?
SELECT Sport,COUNT(Sport) AS 'Game_Played' FROM athlete_events
GROUP BY Sport 
HAVING COUNT(Sport)<2;

-- 8. Fetch the total number of sports played in each Olympic game.
SELECT Games,Sport,COUNT(Sport) AS 'Total_Sports_Played' FROM athlete_events
GROUP BY Games,Sport
ORDER BY Games,Sport;

-- 9. Fetch details of the oldest athletes to win a gold medal.

-- Using WHERE Clause
SELECT * FROM athlete_events
WHERE Medal='Gold'
ORDER BY AGE DESC ;

-- Using Subquery 
SELECT * FROM athlete_events
WHERE AGE = (SELECT MAX(AGE) FROM athlete_events WHERE Medal="Gold") AND Medal="Gold";

-- 10. Find the ratio of male and female athletes participating in all Olympic games.
SELECT CONCAT("1:",
(SELECT COUNT(Sex) FROM athlete_events WHERE Sex='M')/
(SELECT COUNT(Sex) FROM athlete_events WHERE Sex='F') )
AS 'male_to_female_ratio';

-- 11. Fetch the top 5 athletes who have won the most gold medals.

-- Using CASE
WITH CTE AS (SELECT Name,Team,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medal_Count,
DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) DESC) AS rnk
FROM athlete_events
WHERE Medal = 'Gold'
GROUP BY Name, Team)
SELECT * FROM CTE 
WHERE rnk < 6;

-- Using CTE 
WITH CTE AS (SELECT Name,Team,COUNT(Medal),
DENSE_RANK() OVER(ORDER BY COUNT(Medal) DESC) AS 'rnk'
FROM athlete_events
WHERE Medal='Gold'
GROUP BY Name,Team 
)
SELECT*FROM CTE 
WHERE rnk < 6 ;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)?
WITH CTE AS (SELECT name,Team,COUNT(Medal) AS 'Wons_Medal',
DENSE_RANK() OVER(ORDER BY COUNT(Medal) DESC) AS 'Ranking'
FROM athlete_events 
WHERE Medal ='Gold' OR 'Silver' OR 'Bronze'
GROUP BY name,Team)
SELECT * FROM CTE 
WHERE Ranking<6;

-- 13. Fetch the top 5 most successful countries in the Olympics based on the number of medals won.
WITH CTE AS (SELECT Region,COUNT(Medal) AS 'Total_Medals',
DENSE_RANK() OVER(ORDER BY COUNT(Medal) DESC) AS 'Top_5_Ranking'
FROM athlete_events t1
JOIN noc_regions t2
ON t1.NOC=t2.NOC
WHERE Medal IN (SELECT Medal FROM athlete_events WHERE Medal NOT LIKE 'NA' )
GROUP BY Region)
SELECT * FROM CTE
WHERE Top_5_Ranking<6;

-- 14. List down total gold, silver, and bronze medals won by each country.
SELECT Region,
COUNT(CASE WHEN Medal='Gold' THEN 1 END ) AS 'Gold_Medals',
COUNT(CASE WHEN Medal='Silver' THEN 1 END ) AS 'Silver_Medals',
COUNT(CASE WHEN Medal='Bronze' THEN 1 END) AS 'Bronze_Medals',
COUNT(CASE WHEN Medal='NA' THEN 1 END) AS 'No_Medals',
COUNT(*) AS 'Total_Medal'
FROM athlete_events t1
JOIN noc_regions t2
ON t1.NOC=t2.NOC 
GROUP BY Region 
ORDER BY Gold_Medals DESC, Silver_Medals DESC, Bronze_Medals DESC;

-- 15. List down total gold, silver, and bronze medals won by each country corresponding to each Olympic game.
WITH CTE AS (SELECT t2.Region,t1.Games,t1.Medal,COUNT(*) AS 'Total_Medals',
DENSE_RANK() OVER(PARTITION BY t1.Medal,t1.Games ORDER BY COUNT(*) DESC) AS 'Ranking'
FROM athlete_events t1
JOIN noc_regions t2
ON t1.NOC=t2.NOC 
WHERE t1.Medal IN ('Gold','Silver','Bronze')
GROUP BY t2.Region,t1.Games,t1.Medal)
SELECT Games,
MAX(CASE WHEN Medal='Gold' AND Ranking=1 THEN CONCAT(Region,' ',CAST(Total_Medals AS CHAR)) END ) AS Max_Gold,
MAX(CASE WHEN Medal='Silver' AND Ranking=1 THEN CONCAT(Region, ' ',CAST( Total_Medals AS CHAR)) END ) AS Max_Silver,
MAX(CASE WHEN Medal='Bronze' AND Ranking = 1 THEN CONCAT(Region, ' ', CAST(Total_Medals AS CHAR)) END ) AS Max_Bronze
FROM CTE 
GROUP BY Games
ORDER BY Games;

-- 16. Identify which country won the most gold, silver, and bronze medals in each Olympic game.
WITH CTE AS (SELECT 
t2.Region,t1.Games,
SUM(CASE WHEN t1.Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
SUM(CASE WHEN t1.Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
SUM(CASE WHEN t1.Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events t1
JOIN noc_regions t2 ON t1.NOC = t2.NOC 
WHERE t1.Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY t2.Region, t1.Games)
SELECT Games,Region AS Gold_Medal_Winner,
Gold_Medals AS Gold_Medal_Count,
Region AS Silver_Medal_Winner,
Silver_Medals AS Silver_Medal_Count,
Region AS Bronze_Medal_Winner,
Bronze_Medals AS Bronze_Medal_Count
FROM CTE
WHERE (Gold_Medals, Silver_Medals, Bronze_Medals) IN (
SELECT MAX(Gold_Medals),MAX(Silver_Medals),MAX(Bronze_Medals)
FROM CTE AS innerCTE
WHERE innerCTE.Games = CTE.Games)
ORDER BY Games;

-- 17. Identify which country won the most gold, silver, bronze medals, and the most medals in each Olympic game.
WITH cte AS (SELECT 
oh.Games,onc.Region,oh.Medal,COUNT(*) AS medal_count,
DENSE_RANK() OVER (PARTITION BY oh.Games, oh.Medal ORDER BY COUNT(*) DESC) AS Ranking
FROM athlete_events oh
JOIN noc_regions onc ON oh.NOC = onc.NOC
WHERE oh.Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY oh.Games, onc.Region, oh.Medal)
SELECT Games,
MAX(CASE WHEN Medal = 'Gold' AND Ranking = 1 THEN CONCAT(Region, ' ', CAST(medal_count AS CHAR)) END) AS max_gold,
MAX(CASE WHEN Medal = 'Silver' AND Ranking = 1 THEN CONCAT(Region, ' ', CAST(medal_count AS CHAR)) END) AS max_silver,
MAX(CASE WHEN Medal = 'Bronze' AND Ranking = 1 THEN CONCAT(Region, ' ', CAST(medal_count AS CHAR)) END) AS max_bronze,
(SELECT CONCAT(Region, ' ', CAST(SUM(medal_count) AS CHAR))
FROM cte c 
WHERE c.Games = cte.Games
GROUP BY Games, Region
ORDER BY SUM(medal_count) DESC
LIMIT 1) AS region_max_medal
FROM cte
GROUP BY Games
ORDER BY Games;

-- 18. Which countries have never won a gold medal but have won silver/bronze medals?
SELECT DISTINCT(Region) FROM athlete_events t1
JOIN noc_regions t2
ON t1.NOC=t2.NOC 
WHERE Medal IN ('Silver','Bronze') AND 	Medal <> 'Gold' OR 'NA';

-- 19. In which Sport/event did India win the highest number of medals?
WITH CTE AS (SELECT Sport,Event,COUNT(Medal) AS 'Total_Medal' ,
DENSE_RANK() OVER(ORDER BY COUNT(Medal) DESC) AS 'Ranking'
FROM athlete_events t1
JOIN noc_regions t2
ON t1.NOC=t2.NOC 
WHERE Team="India" AND Medal <> 'NA'
GROUP BY Sport,Event)
SELECT * FROM CTE 
WHERE Ranking=1;

-- 20. Break down all Olympic games where India won a medal for Hockey and the number of medals in each Olympic game.
WITH CTE AS (SELECT Sport,Games,COUNT(Medal) AS 'Total_Medal' ,
DENSE_RANK() OVER(PARTITION BY Games ORDER BY COUNT(Medal) DESC) AS 'Ranking'
FROM athlete_events t1
JOIN noc_regions t2
ON t1.NOC=t2.NOC 
WHERE Team="India" AND Medal <> 'NA' AND Sport='Hockey'
GROUP BY Sport,Games)
SELECT * FROM CTE 
WHERE Ranking=1;



















































