-- RevRoll is an auto parts dealer and installer. 
-- They offer a full range of automotive parts replacement services.

/* Question #1: 
- Installers receive performance based year end bonuses. 
- Bonuses are calculated by taking 10% of the total value of parts installed by the installer.
- Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in increasing order.
- Expected column names: name, bonus */

-- Q1 Solution:
WITH new_orders AS (
SELECT o.order_id, iers.name, o.part_id, o.quantity, p.price
FROM orders o
  INNER JOIN installs i ON o.order_id = i.order_id
  INNER JOIN installers iers ON i.installer_id = iers.installer_id
  INNER JOIN parts p ON o.part_id = p.part_id
)
SELECT name, ROUND(SUM(price*quantity)*0.1,0) AS bonus
FROM new_orders
GROUP BY name
ORDER BY bonus;

/* Question #2: 
RevRoll encourages healthy competition. The company holds a “Install Derby” 
where installers face off to see who can change a part the fastest in a tournament style contest.
Derby points are awarded as follows:

An installer receives three points if they win a match (i.e., Took less time to install the part).
An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. 
Return the result table ordered by num_points in decreasing order. 
In case of a tie, order the records by installer_id in increasing order.

Expected column names: installer_id, name, num_points */

-- Q2 Solution:
WITH point1 AS (
SELECT installer_one_id AS installer_id,
	CASE WHEN installer_one_time < installer_two_time THEN 3
  WHEN installer_one_time = installer_two_time THEN 1
  ELSE 0 END AS point
FROM install_derby
), point2 AS (
SELECT installer_two_id AS installer_id,
	CASE WHEN installer_one_time > installer_two_time THEN 3
  WHEN installer_one_time = installer_two_time THEN 1
  ELSE 0 END AS point
FROM install_derby
)
SELECT i.installer_id, name, COALESCE(SUM(point),0) AS num_points
FROM installers i
	LEFT JOIN (
SELECT installer_id, point FROM point1
UNION ALL
SELECT * FROM point2) p ON i.installer_id = p.installer_id
GROUP BY i.installer_id, name
ORDER BY num_points DESC, installer_id;

/* Question #3: 
Write a query to find the fastest install time with its corresponding derby_id for each installer. 
In case of a tie, you should find the install with the smallest derby_id.

Return the result table ordered by installer_id in ascending order.

Expected column names: derby_id, installer_id, install_time */

-- Q3 Solution:
WITH fastest AS (
SELECT i.derby_id, i.installer_one_id installer_id, i.installer_one_time install_time
FROM install_derby i
	INNER JOIN (
  SELECT DISTINCT(installer_one_id) install_id, MIN(installer_one_time) install_time
    FROM install_derby
    GROUP BY install_id
  ) id ON i.installer_one_id = id.install_id AND i.installer_one_time = id.install_time
UNION ALL
SELECT i.derby_id, i.installer_two_id installer_id, i.installer_two_time install_time
FROM install_derby i
	INNER JOIN (
  SELECT DISTINCT(installer_two_id) install_id, MIN(installer_two_time) install_time
    FROM install_derby
    GROUP BY install_id
  ) id ON i.installer_two_id = id.install_id AND i.installer_two_time = id.install_time
 )
SELECT MIN(f1.derby_id) derby_id, f1.installer_id, MIN(f1.install_time) install_time
FROM fastest f1
INNER JOIN (
	SELECT DISTINCT(installer_id), MIN(install_time) install_time
  FROM fastest
  GROUP BY installer_id
) f2 ON f1.installer_id = f2.installer_id AND f1.install_time = f2.install_time
GROUP BY f1.installer_id;

/* Question #4: 
Write a solution to calculate the total parts spending by customers paying for installs on each Friday of 
every week in November 2023. If there are no purchases on the Friday of a particular week, the parts total should be set to 0.

Return the result table ordered by week of month in ascending order.

Expected column names: november_fridays, parts_total
NOTE: NOVEMBER 2023 Friday will be ('2023-11-03', '2023-11-10', '2023-11-17', '2023-11-24')
*/

-- Q4 Solution:
WITH date_list AS (
SELECT CAST(date as date) install_date
FROM Generate_series(date '2023-11-03', date '2023-11-24', '7 day') date
), total_amount AS(
SELECT o.order_id, o.part_id, o.quantity, p.price, o.quantity * p.price AS amount,
			i.install_date
FROM orders o
	INNER JOIN parts p ON o.part_id = p.part_id
  INNER JOIN installs i ON o.order_id = i.order_id
WHERE i.install_date IN (SELECT * FROM date_list)
)
SELECT d.install_date AS november_fridays, COALESCE(SUM(t.amount),0) AS parts_total
FROM date_list d
	LEFT JOIN total_amount t USING (install_date)
GROUP BY d.install_date
ORDER BY d.install_date;