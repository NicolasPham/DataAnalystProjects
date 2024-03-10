/*
Question #1: 
Vibestream is designed for users to share brief updates about how they are feeling, 
as such the platform enforces a character limit of 25. How many posts are exactly 25 characters long?

Expected column names: char_limit_posts
*/
-- Q1 Solution
SELECT COUNT(DISTINCT post_id) AS chart_limit_posts
FROM posts
WHERE LENGTH(content) = 25;

/*
Question #2: 
Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.

Find the difference in the number of posts these two users made on each day that at least one of them made a post. 
Return dates where the absolute value of the difference between posts made is greater than 2 
(i.e dates where JamesTiger8285 made at least 3 more posts than RobertMermaid7605 or vice versa).

Expected column names: post_date
*/
-- Q2 Solution
WITH two_users AS (
SELECT DISTINCT post_date,
	CASE WHEN user_name = 'JamesTiger8285' THEN COUNT(user_name) ELSE 0 END AS james,
  CASE WHEN user_name = 'RobertMermaid7605' THEN COUNT(user_name) ELSE 0 END AS robert
FROM posts
	INNER JOIN users USING (user_id)
WHERE user_name IN ('JamesTiger8285', 'RobertMermaid7605')
GROUP BY post_date, user_name
)
SELECT DISTINCT post_date
FROM two_users
GROUP BY post_date
HAVING ABS(MAX(james) - MAX(robert)) > 2;

/*
Question #3: 
Most users have relatively low engagement and few connections. User WilliamEagle6815, for example, has only 2 followers. 

Network Analysts would say this user has two 1-step path relationships. 
Having 2 followers doesn’t mean WilliamEagle6815 is isolated, however. 
Through his followers, he is indirectly connected to the larger Vibestream network.  

Consider all users up to 3 steps away from this user:


1-step path (X → WilliamEagle6815)
2-step path (Y → X → WilliamEagle6815)
3-step path (Z → Y → X → WilliamEagle6815)

Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. 
Order by follower_id and return the top 10 records.

Expected column names: follower_id
*/
-- Q3 Solution
WITH within4Step AS (
SELECT user_name, f1.follower_id step1, f2.follower_id as step2, f3.follower_id as step3, f4.follower_id as step4
FROM follows f1
	INNER JOIN users u ON u.user_id = f1.followee_id
  INNER JOIN follows f2 ON f1.follower_id = f2.followee_id
  INNER JOIN follows f3 ON f2.follower_id = f3.followee_id
  INNER JOIN follows f4 ON f3.follower_id = f4.followee_id
WHERE f1.followee_id = 97
)
SELECT DISTINCT step4
FROM within4Step
ORDER BY step4 LIMIT 10;

/*
Question #4: 
Return top posters for 2023-11-30 and 2023-12-01. A top poster is a user who has the most 
OR second most number of posts in a given day. Include the number of posts 
in the result and order the result by post_date and user_id.

Expected column names: post_date, user_id, posts
*/
-- Q4 Solution
WITH number_posts AS (
SELECT post_date, user_id, COUNT(post_id) AS number_posts
FROM posts
WHERE post_date IN ('2023-11-30', '2023-12-01')
GROUP BY post_date, user_id
)
SELECT post_date, user_id, number_posts as posts
FROM number_posts
WHERE number_posts >= (SELECT MAX(number_posts) FROM number_posts) - 1
ORDER BY post_date, user_id;