-- 1. What range of years for baseball games played does the provided database cover? 
-- ANSWER: 1871 to 2016 - 145 years

SELECT MIN(yearid), MAX(yearid), MAX(yearid)-MIN(yearid)
FROM appearances;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
-- ANSWER: Eddie Gaedel, played in 1 game for the St. Louis Browns (Eddie was 43 inches tall, 3 ft, 7 in)

SELECT namefirst, namelast, MIN(height) AS height, g_all, t.name
FROM people AS p
LEFT JOIN appearances AS a
USING (playerid) 
LEFT JOIN teams AS t
USING (teamid)
GROUP BY namefirst, namelast, g_all, teamid, height, t.name
ORDER BY height;

 -- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
-- ANSWER: David Price, $81,851,296

SELECT namefirst, namelast, SUM(salary)
FROM
    (SELECT playerid, namefirst, namelast, schoolname
    FROM people AS p
    LEFT JOIN collegeplaying 
    USING (playerid)
    LEFT JOIN schools
    USING (schoolid)
    WHERE schoolname = 'Vanderbilt University'
    GROUP BY playerid, namefirst, namelast, schoolname) AS vandy
LEFT JOIN salaries 
USING (playerid)
GROUP BY namefirst, namelast
ORDER BY SUM(salary) DESC;

 -- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
-- ANSWER: 
-- Outfield putouts: 29,560
-- Infield putouts: 58,934
-- Battery putouts: 41,424

SELECT
    (SELECT SUM(po)
    FROM fielding 
    WHERE pos = 'OF' AND yearid = 2016) AS outfield_putouts,
    (SELECT SUM(po) 
     FROM fielding
     WHERE pos IN ('SS','1B','2B','3B') AND yearid = 2016) AS infield_putouts,
     (SELECT SUM(po)
     FROM fielding 
     WHERE pos IN ('C','P') AND yearid = 2016) AS battery_putouts
 FROM fielding
 GROUP BY outfield_putouts, infield_putouts, battery_putouts;
   
 -- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
 -- ANSWER: 
   
WITH games AS
(SELECT yearid/10*10 AS decade, SUM(g)/2 AS total_games
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade),

so AS
(SELECT yearid/10*10 AS decade, SUM(so) AS total_strikeouts, SUM(HR) AS total_home_runs
FROM pitching
WHERE yearid >= 1920 
GROUP BY decade
ORDER BY decade)

SELECT g.decade, total_games, total_strikeouts, CAST(total_strikeouts AS float)/CAST(total_games AS float) AS strikeouts_per_game, CAST(total_home_runs AS float)/CAST(total_games AS float) AS home_runs_per_game
FROM games AS g
INNER JOIN so AS so
ON g.decade = so.decade
GROUP BY g.decade, total_games, total_strikeouts, total_home_runs
ORDER BY g.decade;

SELECT yearid/10*10 AS decade, SUM(g)/2 AS total_games, SUM(so) AS total_strikeouts, SUM(HR) AS total_home_runs, CAST(SUM(so) AS float)/CAST(SUM(g)/2 AS float) AS strikeouts_per_game, CAST(SUM(HR) AS float)/CAST(SUM(g)/2 AS float) AS home_runs_per_game
FROM teams 
WHERE yearid >= 1920 
GROUP BY decade
ORDER BY decade

 -- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
-- ANSWER: Chris Owings
	
SELECT playerid, namefirst, namelast, sb, cs, CAST(sb AS float)/CAST(sb+cs AS float) AS perc_sb_success
FROM batting
JOIN people
USING (playerid)
WHERE yearid = 2016 AND sb+cs >= 20
GROUP BY playerid, namefirst, namelast, sb, cs
ORDER BY perc_sb_success DESC;

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- ANSWER: 
-- Largest number of wins - 116
-- Smallest number of wins - 63 | Why so low? Only 110 games played in season
-- How often did team with most wins win World Series? 10 times | % of time? 25.5% 

SELECT yearid, MAX(w), wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'N'
GROUP BY yearid, wswin
ORDER BY MAX(w) DESC;

SELECT yearid, MIN(w), wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
GROUP BY yearid, wswin
ORDER BY MIN(w);

SELECT yearid, MIN(w), wswin, AVG(g)
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y' 
GROUP BY yearid, wswin
HAVING AVG(g) > 110
ORDER BY MIN(w);

WITH no_winning AS
(SELECT yearid, MAX(w) AS most_wins_no, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'N'
GROUP BY yearid, wswin
ORDER BY yearid, MAX(w) DESC),

yes_winning AS
(SELECT yearid, MAX(w) AS most_wins_yes, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
GROUP BY yearid, wswin
ORDER BY yearid, MAX(w))

SELECT yearid, most_wins_yes, yes_winning.wswin, CAST(12 AS float)/CAST(2016-1970+1 AS float) AS perc_ws_winner_had_most_wins
FROM no_winning
JOIN yes_winning
USING (yearid)
WHERE most_wins_yes >= most_wins_no
GROUP BY yearid, most_wins_yes, yes_winning.wswin
ORDER BY yearid

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
-- ANSWER: 

WITH parks AS
(SELECT team, park, attendance/games AS attendance_per_game, park_name
FROM homegames
JOIN parks
USING (park)
WHERE year = 2016 AND games >= 10
GROUP BY team, park, attendance, games, park_name
ORDER BY attendance_per_game DESC),

team AS
(SELECT teamid, franchid, franchname
FROM teams
JOIN teamsfranchises 
USING (franchid)
GROUP BY teamid, franchid, franchname)

SELECT parks.park_name, team.franchname, attendance_per_game
FROM parks
JOIN team
ON parks.team = team.teamid
GROUP BY parks.park_name, team.franchname, attendance_per_game
ORDER BY attendance_per_game DESC
LIMIT 5

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
-- ANSWER: 

WITH t1 AS
(SELECT playerid, awardid, yearid, lgid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' AND lgid = 'AL' 
GROUP BY playerid, awardid, yearid, lgid),

t2 AS
(SELECT playerid, awardid, yearid, lgid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' AND lgid = 'NL' 
GROUP BY playerid, awardid, yearid, lgid),

plus AS
(SELECT namefirst, namelast, teamid, playerid
FROM awardsmanagers AS a
JOIN managers 
USING (playerid)
JOIN people
USING (playerid)
GROUP BY namefirst, namelast, teamid, playerid)

SELECT namefirst, namelast, teamid
FROM t1
INNER JOIN t2
USING (playerid)
JOIN plus
USING (playerid)
GROUP BY namefirst, namelast, teamid

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
-- ANSWER: 

WITH players AS
(SELECT DISTINCT playerid, MAX(HR) AS hr_count, namefirst, namelast
FROM batting
 JOIN people
 USING (playerid)
GROUP BY playerid, namefirst, namelast
ORDER BY MAX(HR) DESC, playerid),

plus AS
(SELECT yearid, playerid, HR
FROM people
JOIN batting 
USING (playerid)
 WHERE yearid = 2016
GROUP BY yearid, playerid, HR), 

years AS
(SELECT playerid, COUNT(DISTINCT yearid) AS years_played
FROM batting 
JOIN people
USING (playerid)
GROUP BY playerid)

SELECT players.playerid, namefirst, namelast, hr_count
FROM players
JOIN plus
USING (playerid)
JOIN years
USING (playerid)
WHERE yearid = 2016 AND hr_count > 0 AND years_played >= 10 AND plus.HR = players.hr_count
GROUP BY players.playerid, namefirst, namelast, hr_count, hr
ORDER BY hr_count DESC


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
-- ANSWER: 

WITH salaries AS
(SELECT s.yearid, s.teamid, SUM(salary) AS total_team_salary
FROM salaries AS s
WHERE yearid >= 2000
GROUP BY s.yearid, s.teamid
ORDER BY s.yearid, total_team_salary DESC),

wins AS
(SELECT t.yearid, t.teamid, w
FROM teams AS t
WHERE yearid >= 2000
GROUP BY t.yearid, t.teamid, w
ORDER BY t.yearid)

SELECT salaries.yearid, salaries.teamid, total_team_salary, w, RANK() OVER(ORDER BY total_team_salary DESC) AS salary_rank, RANK() OVER(ORDER BY w DESC) AS w_rank
FROM salaries
JOIN wins
USING (yearid, teamid)
WHERE salaries.yearid = 2000
GROUP BY salaries.yearid, salaries.teamid, total_team_salary, w
ORDER BY salaries.yearid, total_team_salary DESC, w DESC

WITH team_total AS
(SELECT yearid, teamid, SUM(salary) AS team_salary
FROM salaries
WHERE yearid >= 2000
GROUP BY yearid, teamid),

wins AS 
(SELECT yearid, teamid, w
FROM teams
WHERE yearid >= 2000
GROUP BY yearid, teamid, w),

averages AS
(SELECT DISTINCT teamid, AVG(team_salary) OVER (PARTITION BY teamid) AS team_avg_salary, AVG(w) OVER (PARTITION BY teamid) AS team_avg_wins
FROM team_total 
JOIN wins
USING (yearid, teamid)
WHERE team_total.yearid >= 2000
GROUP BY teamid, team_salary, w
ORDER BY team_avg_salary DESC)

SELECT DISTINCT teamid, team_avg_salary, team_avg_wins, RANK() OVER(ORDER BY team_avg_salary DESC) AS salary_rank, RANK() OVER(ORDER BY team_avg_wins DESC) AS wins_rank
FROM team_total
JOIN wins 
USING (yearid, teamid)
JOIN averages
USING (teamid)
GROUP BY teamid, team_avg_salary, team_avg_wins
ORDER BY wins_rank 

-- 12. In this question, you will explore the connection between number of wins and attendance. Does there appear to be any correlation between attendance at home games and number of wins? Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- ANSWER:

SELECT yearid, teamid, ROUND(AVG(attendance)/ghome) AS avg_attendance, ROUND(w) AS wins, ROUND((AVG(attendance)/ghome)/w) AS fans_per_win
-- wswin, divwin, wcwin
FROM teams
GROUP BY yearid, teamid, ghome, w
ORDER BY yearid DESC, fans_per_win DESC, avg_attendance DESC, wins DESC

SELECT yearid, teamid, wswin, ROUND(AVG(attendance)/ghome) AS avg_attendance, LEAD(ROUND(AVG(attendance)/ghome),1) OVER (PARTITION BY teamid ORDER BY attendance) AS attendance_after_wswin
FROM teams
WHERE wswin = 'Y'
GROUP BY yearid, teamid, wswin, attendance, ghome
ORDER BY yearid DESC, attendance_after_wswin

WITH fans AS
(
    SELECT yearid, teamid, attendance, wswin, LEAD(attendance, 1) OVER (PARTITION BY teamid) AS attendance_year2
FROM teams
 -- WHERE wswin = 'Y'
GROUP BY yearid, teamid, attendance, wswin
ORDER BY yearid DESC
)

SELECT fans.yearid, fans.teamid, avg_attendance, LEAD(avg_attendance,1) OVER (ORDER BY fans.yearid) AS attendance_after_wswin
FROM fans
-- JOIN fans
-- USING (yearid)
GROUP BY fans.yearid, avg_attendance, fans.teamid
ORDER BY fans.yearid DESC

SELECT
playerid, hr, hr - lag(hr) over(order by yearid ASC) difference_from_previous_year
FROM batting
WHERE playerid LIKE 'bondsba01'
group by playerid, yearid, hr

WITH fans AS
(SELECT yearid, teamid, attendance/ghome AS avg_attendance, LEAD(attendance/ghome, 1) OVER (ORDER BY yearid) AS attendance_year2, wswin
FROM teams 
WHERE teamid = 'KCA' 
GROUP BY teamid, attendance, yearid, wswin, ghome
ORDER BY yearid DESC)

SELECT yearid, teamid, fans.avg_attendance, fans.attendance_year2, attendance_year2 - avg_attendance AS diff, wswin
FROM fans
GROUP BY yearid, teamid, fans.avg_attendance, fans.attendance_year2, wswin
ORDER BY yearid DESC


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
-- ANSWER: 

WITH hand AS 
(SELECT COUNT(DISTINCT playerid) AS pitchers_by_hand, throws, 
    (SELECT COUNT(DISTINCT playerid) 
    FROM pitching) AS total_pitchers
FROM people
JOIN pitching
USING (playerid)
GROUP BY throws)

SELECT pitchers_by_hand, throws, CAST(pitchers_by_hand AS float)/CAST(total_pitchers AS float) AS perc_of_pitchers
FROM hand
GROUP BY throws, pitchers_by_hand, total_pitchers

SELECT *
FROM awardsplayers
WHERE awardid = 'Cy Young Award'

SELECT COUNT(DISTINCT playerid), throws, awardid
FROM people 
JOIN pitching 
USING (playerid)
JOIN awardsplayers 
USING (playerid)
WHERE awardid = 'Cy Young Award'
GROUP BY throws, awardid


