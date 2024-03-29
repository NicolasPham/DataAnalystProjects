{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang4105{\fonttbl{\f0\fnil\fcharset0 Calibri;}}
{\*\generator Riched20 10.0.22621}\viewkind4\uc1 
\pard\sa200\sl276\slmult1\f0\fs22\lang9 /*\par
Question #1: \par
Write a query to find the customer(s) with the most orders. Return only the preferred name.\par
Expected column names: preferred_name\par
*/\par
WITH cte AS (\par
SELECT customer_id, preferred_name, COUNT(DISTINCT order_id) as total_order\par
FROM orders\par
\tab INNER JOIN customers USING(customer_id)\par
GROUP BY customer_id, preferred_name\par
ORDER BY total_order DESC\par
)\par
SELECT preferred_name FROM cte LIMIT 1;\par
\par
/*\par
Question #2: \par
RevRoll does not install every part that is purchased. Some customers prefer to install parts themselves. \par
This is a valuable line of business RevRoll wants to encourage by finding valuable self-install customers \par
and sending them offers.\par
\par
Return the customer_id and preferred name of customers who have made at least $2000 of purchases in parts \par
that RevRoll did not install. \par
\par
Expected column names: customer_id, preferred_name\par
*/\par
WITH self_install AS (\par
SELECT o.customer_id, SUM(quantity*price) AS total\par
FROM orders o\par
\tab LEFT JOIN installs i ON o.order_id = i.order_id\par
  INNER JOIN parts p ON o.part_id = p.part_id\par
WHERE installer_id IS NULL\par
GROUP BY o.customer_id\par
  )\par
SELECT c.customer_id, c.preferred_name\par
FROM customers c\par
\tab INNER JOIN self_install USING(customer_id)\par
WHERE total >=2000\par
GROUP BY c.customer_id, c.preferred_name;\par
\par
/*\par
Question #3: \par
Report the id and preferred name of customers who bought an Oil Filter and Engine Oil \par
but did not buy an Air Filter since we want to recommend these customers buy an Air Filter. \par
Return the result table ordered by customer_id.\par
\par
Expected column names: customer_id, preferred_name\par
*/\par
WITH order_table AS (\par
SELECT customer_id, STRING_AGG(name, ', ') AS order_total\par
FROM orders o\par
\tab INNER JOIN parts p USING(part_id)\par
WHERE name in ('Oil Filter', 'Engine Oil', 'Air Filter')\par
GROUP BY customer_id\par
)\par
SELECT c.customer_id, c.preferred_name\par
FROM order_table o\par
\tab INNER JOIN customers c USING(customer_id)\par
WHERE order_total LIKE '%Engine Oil%' AND order_total LIKE '%Oil Filter%'\par
\tab AND order_total NOT LIKE '%Air%';\par
\par
/*\par
Question #4: \par
Write a solution to calculate the cumulative part summary for every part that the RevRoll team has installed.\par
\par
The cumulative part summary for an part can be calculated as follows:\par
\par
For each month that the part was installed, sum up the price*quantity in that month and the previous \par
two months. This is the 3-month sum for that month. If a part was not installed in previous months, \par
the effective price*quantity for those months is 0.\par
Do not include the 3-month sum for the most recent month that the part was installed.\par
Do not include the 3-month sum for any month the part was not installed.\par
Return the result table ordered by part_id in ascending order. In case of a tie, order it by month \par
in descending order. Limit the output to the first 10 rows.\par
\par
Expected column names: part_id, month, part_summary\par
*/\par
WITH part_orders AS (\par
SELECT o.part_id, EXTRACT(month from install_date) AS month, SUM(price*quantity) AS total\par
FROM orders o\par
\tab INNER JOIN installs i USING(order_id)\par
  INNER JOIN parts p ON o.part_id = p.part_id\par
GROUP BY o.part_id, month\par
ORDER BY part_id, month\par
  ), gen_month AS (\par
SELECT DISTINCT part_id, gen_month AS month\par
FROM parts \par
\tab CROSS JOIN (SELECT generate_series(1,12,1) AS gen_month) gen\par
ORDER BY part_id, gen_month\par
  ), new_data AS (\par
SELECT g.part_id, g.month,\par
\tab CASE WHEN total IS NULL THEN 0\par
  ELSE total END AS total\par
FROM gen_month g\par
\tab LEFT OUTER JOIN part_orders p USING(part_id, month)\par
\tab ), final_data AS (\par
SELECT part_id, month, total, \par
    SUM(total) OVER(PARTITION BY part_id ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS accum\par
FROM new_data\par
GROUP BY part_id, month, total\par
ORDER BY part_id, month DESC\par
  )\par
SELECT part_id, month, accum as part_summary\par
FROM final_data\par
WHERE total <> 0 AND month <> 12\par
LIMIT 10;\par
}
 