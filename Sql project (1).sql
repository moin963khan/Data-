
-- Are there any tables with duplicate or missing null values? If so, how would you handle them?

-- -- checking duplicates

SELECT id,comment_text, user_id, photo_id, created_at
FROM comments
group by id,comment_text,user_id,photo_id,created_at
having count(*)>1;

SELECT follower_id,followee_id
FROM follows
group by follower_id,followee_id
having count(*)>1;

SELECT user_id,photo_id,created_at
FROM likes
group by user_id,photo_id,created_at
having count(*)>1;

SELECT photo_id,tag_id
FROM photo_tags
group by photo_id,tag_id
having count(*)>1;

SELECT photo_id,tag_id
FROM photo_tags
group by photo_id,tag_id
having count(*)>1;

SELECT id, image_url, user_id, created_dat
FROM photos
group by id, image_url, user_id, created_dat
having count(*)>1;

SELECT id, tag_name,created_at
FROM tags
group by id, tag_name,created_at
having count(*)>1;

SELECT id,username
FROM users
group by id,username
having count(*)>1;

-- No Duplicate Values

-- checking null values

select * from comments 
where  1 is null or 2 is null or 3 is null or 4 is null or 5 is null;

select * from follows
where  1 is null or 2 is null;

select * from likes
where  1 is null or 2 is null;

select * from photo_tags
where  1 is null or 2 is null;

select * from photos
where  1 is null or 2 is null or 3 is null;

select * from tags
where  1 is null or 2 is null;

select * from users
where  1 is null or 2 is null;

-- No Null Values.

-- What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

SELECT 
	u.id AS user_id,
    	username,
    	COUNT(DISTINCT p.id) AS photos_posted,
    	COUNT(DISTINCT c.photo_id) AS comments,
    	COUNT(DISTINCT l.photo_id) AS likes,
    	COUNT(DISTINCT pt.tag_id) AS tags
FROM users u 
LEFT JOIN photos p ON p.user_id=u.id
LEFT JOIN comments c ON c.user_id=u.id
LEFT JOIN likes l ON l.user_id=u.id
LEFT JOIN photo_tags pt ON pt.photo_id=p.id
GROUP BY user_id, username;

-- Calculate the average number of tags per post (photo_tags and photos tables).
select 
round((select count(*) from photo_tags) / (select count(*) from photos),2) as avg_tag_per_photo ;

-- Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

with engagements as (select 
u.username, 
u.id as user_id , 
count(distinct p.id) as total_post,  
count( distinct l.user_id) as total_likes , 
count(distinct c.id) as total_comments
from users u
join photos p on u.id = p.user_id
left join comments c on c.photo_id = p.id
left join likes l on l.photo_id = p.id
group by u.id)

select username,
 total_post, 
 (total_likes + total_comments) as total_interactions,
 (total_likes+total_comments)/total_post as engagement_rate,
 rank()over(order by  (total_likes + total_comments)/total_post desc)  as engagement_rank 
 from engagements
 order by engagement_rank asc;
 
 -- Which users have the highest number of followers and followings?
 -- highest number of followers 
 
SELECT 
    username,
    (SELECT COUNT(*) FROM follows WHERE followee_id = users.id) AS followers
    
FROM users
ORDER BY followers DESC,username asc
limit 20;


-- highest number of following

SELECT 
    username,
    (SELECT COUNT(*) FROM follows WHERE follower_id = users.id) AS following
FROM users
ORDER BY following DESC,username asc
limit 20;

-- Calculate the average engagement rate (likes, comments) per post for each user

WITH engagements AS(
SELECT 
    u.id,
    username,
    COUNT(DISTINCT l.user_id) AS likes,
    COUNT(DISTINCT c.user_id) AS comments    
FROM users u 
LEFT JOIN photos p ON u.id = p.user_id
JOIN likes l ON l.photo_id = p.id
JOIN comments c ON c.photo_id=p.id
GROUP BY u.id,username
),

total_post as (
select user_id , COUNT(id) as number_of_posts
from photos
group by user_id )

Select
Id,
username, 
likes+comments as total_engagements, 
(likes+comments)/number_of_posts as engagement_rate_per_post,
dense_rank () over (order by (likes+comments)/number_of_posts desc) as `rank`
from engagements e
join total_post t on e.id = t.user_id;

-- Get the list of users who have never liked any post (users and likes tables)
SELECT u.id, u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

-- How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?-
SELECT t.id,t.tag_name, COUNT(*) AS usage_count
FROM photo_tags pt
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name
ORDER BY usage_count DESC
LIMIT 10;

WITH user_tags AS ( 

  SELECT p.user_id, t.tag_name, COUNT(*) AS tag_count 

  FROM photos p 

  JOIN photo_tags pt ON p.id = pt.photo_id 

  JOIN tags t ON pt.tag_id = t.id 

  GROUP BY p.user_id, t.tag_name 

), 

ranked_tags AS ( 

  SELECT *, 

         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY tag_count DESC) AS rn 

  FROM user_tags 

) 

SELECT user_id, tag_name, tag_count 

FROM ranked_tags 

WHERE rn = 1; 

-- Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?
WITH user_activity AS (
  SELECT u.id AS user_id,
         COUNT(DISTINCT p.id) AS posts,
         COUNT(DISTINCT l.photo_id) AS likes,
         COUNT(DISTINCT c.id) AS comments
  FROM users u
  LEFT JOIN photos p ON u.id = p.user_id
  LEFT JOIN likes l ON u.id = l.user_id
  LEFT JOIN comments c ON u.id = c.user_id
  GROUP BY u.id
),
user_tag_counts AS (
  SELECT p.user_id, t.tag_name, COUNT(*) AS tag_usage
  FROM photos p
  JOIN photo_tags pt ON p.id = pt.photo_id
  JOIN tags t ON pt.tag_id = t.id
  GROUP BY p.user_id, t.tag_name
),
ranked_user_tags AS (
  SELECT user_id, tag_name, tag_usage,
         RANK() OVER (PARTITION BY user_id ORDER BY tag_usage DESC) AS tag_rank
  FROM user_tag_counts
),
top_tag_per_user AS (
  SELECT user_id, tag_name
  FROM ranked_user_tags
  WHERE tag_rank = 1
),
final_engagement AS (
  SELECT ua.user_id,
         ua.posts,
         ua.likes,
         ua.comments,
         (ua.posts + ua.likes + ua.comments) AS total_activity,
         tt.tag_name AS most_used_tag
  FROM user_activity ua
  LEFT JOIN top_tag_per_user tt ON ua.user_id = tt.user_id
)
SELECT *
FROM final_engagement
ORDER BY total_activity DESC;

-- Calculate the total number of likes, comments, and photo tags for each user.

WITH user_photos AS (
  SELECT u.id AS user_id, u.username, p.id AS photo_id
  FROM users u
  JOIN photos p ON u.id = p.user_id
),
photo_stats AS (
  SELECT up.user_id, up.username, up.photo_id,
         COUNT(DISTINCT l.user_id) AS likes,
         COUNT(DISTINCT c.id) AS comments,
         COUNT(DISTINCT pt.tag_id) AS tags
  FROM user_photos up
  LEFT JOIN likes l ON up.photo_id = l.photo_id
  LEFT JOIN comments c ON up.photo_id = c.photo_id
  LEFT JOIN photo_tags pt ON up.photo_id = pt.photo_id
  GROUP BY up.user_id, up.username, up.photo_id
),
user_engagement AS (
  SELECT user_id, username,
         SUM(likes) AS likes,
         SUM(comments) AS comments,
         SUM(tags) AS tags
  FROM photo_stats
  GROUP BY user_id, username
)
SELECT * 
FROM user_engagement
ORDER BY likes desc,comments desc,tags DESC;

-- Rank users based on their total engagement (likes, comments, shares) over a month.

WITH engagement AS (
  SELECT 
    u.id AS user_id,
    u.username,
    YEAR(p.created_dat) AS year,
    MONTH(p.created_dat) AS month,
    COUNT(DISTINCT c.id) + COUNT(DISTINCT l.user_id) AS total_engagement
  FROM users u
  LEFT JOIN photos p ON u.id = p.user_id
  LEFT JOIN comments c ON c.photo_id = p.id
  LEFT JOIN likes l ON l.photo_id = p.id
  GROUP BY u.id, u.username, YEAR(p.created_dat), MONTH(p.created_dat)
)
SELECT 
  user_id,  username,  year,  month,   total_engagement,
 DENSE_RANK() OVER (PARTITION BY year, month ORDER BY total_engagement DESC) AS engagement_rank
FROM engagement
where year is not null and month is not null
ORDER BY year, month, engagement_rank;

-- Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.

WITH photo_like_counts AS ( 

  SELECT  

    p.id AS photo_id, 

    COUNT(DISTINCT l.user_id) AS likes_count 

  FROM photos p 

  LEFT JOIN likes l ON p.id = l.photo_id 

  GROUP BY p.id 

), 

tag_likes AS ( 

  SELECT  

    t.tag_name, 

    plc.likes_count 

  FROM photo_tags pt 

  JOIN tags t ON pt.tag_id = t.id 

  JOIN photo_like_counts plc ON pt.photo_id = plc.photo_id 

), 

avg_likes_per_tag AS ( 

  SELECT  

    tag_name, 

    AVG(likes_count) AS avg_likes 

  FROM tag_likes 

  GROUP BY tag_name 

), 

max_avg AS ( 

  SELECT MAX(avg_likes) AS max_avg_likes 

  FROM avg_likes_per_tag 

) 

SELECT  

  a.tag_name, 

  a.avg_likes 

FROM avg_likes_per_tag a 

JOIN max_avg m ON a.avg_likes = m.max_avg_likes;

-- Retrieve the users who have started following someone after being followed by that person+

SELECT 
    f1.follower_id AS initial_follower_id,
    u1.username AS initial_follower,
    f1.followee_id AS followed_back_user_id,
    u2.username AS followed_back_user,
    f1.created_at AS first_follow_date,
    f2.created_at AS follow_back_date
FROM follows f1
JOIN follows f2 
    ON f1.follower_id = f2.followee_id 
    AND f1.followee_id = f2.follower_id
JOIN users u1 ON f1.follower_id = u1.id
JOIN users u2 ON f1.followee_id = u2.id
WHERE f2.created_at > f1.created_at;

-- Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
WITH user_posts AS (
  SELECT user_id, COUNT(*) AS total_posts
  FROM photos
  GROUP BY user_id
),
user_likes_received AS (
  SELECT p.user_id, COUNT(l.user_id) AS total_likes
  FROM photos p
  JOIN likes l ON p.id = l.photo_id
  GROUP BY p.user_id
),
user_comments_received AS (
  SELECT p.user_id, COUNT(c.id) AS total_comments
  FROM photos p
  JOIN comments c ON p.id = c.photo_id
  GROUP BY p.user_id
),
total_engagement AS (
  SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(up.total_posts, 0) AS posts,
    COALESCE(ul.total_likes, 0) AS likes_received,
    COALESCE(uc.total_comments, 0) AS comments_received,
    COALESCE(up.total_posts, 0) + COALESCE(ul.total_likes, 0) + COALESCE(uc.total_comments, 0) AS total_engagement
  FROM users u
  LEFT JOIN user_posts up ON u.id = up.user_id
  LEFT JOIN user_likes_received ul ON u.id = ul.user_id
  LEFT JOIN user_comments_received uc ON u.id = uc.user_id
)

SELECT *,
rank()over(order by total_engagement desc) as Rnk
FROM total_engagement
ORDER BY total_engagement DESC
LIMIT 10;

-- For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?

WITH user_likes AS (
  SELECT user_id, COUNT(*) AS like_count
  FROM likes
  GROUP BY user_id
),
user_comments AS (
  SELECT user_id, COUNT(*) AS comment_count
  FROM comments
  GROUP BY user_id
),
user_posts AS (
  SELECT user_id, COUNT(*) AS post_count
  FROM photos
  GROUP BY user_id
),
active_users AS (
  SELECT user_id FROM likes
  UNION
  SELECT user_id FROM comments
  UNION
  SELECT user_id FROM photos
)
SELECT 
  u.id AS user_id, 
  u.username, 
  COALESCE(ul.like_count, 0) AS total_likes,
  COALESCE(uc.comment_count, 0) AS total_comments,
  COALESCE(up.post_count, 0) AS total_posts
FROM users u
LEFT JOIN user_likes ul ON u.id = ul.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN active_users au ON u.id = au.user_id
WHERE au.user_id IS NULL;

-- Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?

WITH photo_engagement AS (
  SELECT 
    p.id AS photo_id,
    COUNT(DISTINCT l.user_id) AS like_count,
    COUNT(DISTINCT c.id) AS comment_count
  FROM photos p
  LEFT JOIN likes l ON p.id = l.photo_id
  LEFT JOIN comments c ON p.id = c.photo_id
  GROUP BY p.id),
tag_engagement AS (
  SELECT 
    t.tag_name,
    AVG(pe.like_count + pe.comment_count) AS avg_engagement
  FROM photo_tags pt
  JOIN tags t ON pt.tag_id = t.id
  JOIN photo_engagement pe ON pt.photo_id = pe.photo_id
  GROUP BY t.tag_name
)
SELECT
  tag_name,
  ROUND(avg_engagement, 2) AS avg_engagement
FROM tag_engagement
ORDER BY avg_engagement DESC
LIMIT 5;

-- Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?
-- ══════════════════════════════════════════════════════════════════════
-- NOTE: This schema has NO demographic columns (age, gender, location).
-- ══════════════════════════════════════════════════════════════════════
--  1. SIGNUP MONTH — which months produce the most engaged users?
-- ─────────────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(u.created_at, '%b')          AS signup_month,
    MONTH(u.created_at)                      AS month_num,
    COUNT(DISTINCT u.id)                     AS users_signed_up,
    ROUND(AVG(p.photo_count),  1)            AS avg_photos_posted,
    ROUND(AVG(l.likes_received), 1)          AS avg_likes_received,
    ROUND(AVG(f.followers),    1)            AS avg_followers
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS photo_count
    FROM   photos GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT ph.user_id, COUNT(*) AS likes_received
    FROM   likes lk JOIN photos ph ON lk.photo_id = ph.id
    GROUP  BY ph.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS followers
    FROM   follows GROUP BY followee_id
) f ON u.id = f.user_id
GROUP  BY DATE_FORMAT(u.created_at, '%b'), MONTH(u.created_at)
ORDER  BY month_num;


-- ─────────────────────────────────────────────────────────────────────
-- 2. SIGNUP HOUR — best time of day to run acquisition campaigns
-- ─────────────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN HOUR(u.created_at) BETWEEN 0  AND 6  THEN '0-6  Early morning'
        WHEN HOUR(u.created_at) BETWEEN 7  AND 11 THEN '7-11  Morning'
        WHEN HOUR(u.created_at) BETWEEN 12 AND 16 THEN '12-16 Afternoon'
        WHEN HOUR(u.created_at) BETWEEN 17 AND 20 THEN '17-20 Evening'
        ELSE                                            '21-23 Night'
    END                                          AS time_bucket,
    COUNT(DISTINCT u.id)                         AS users_count,
    ROUND(AVG(COALESCE(p.photo_count,  0)), 1)   AS avg_photos,
    ROUND(AVG(COALESCE(l.likes_recv,   0)), 1)   AS avg_likes_received,
    ROUND(AVG(COALESCE(f.followers,    0)), 1)   AS avg_followers
FROM users u
LEFT JOIN (SELECT user_id, COUNT(*) AS photo_count FROM photos GROUP BY user_id) p
       ON u.id = p.user_id
LEFT JOIN (
    SELECT ph.user_id, COUNT(*) AS likes_recv
    FROM   likes lk JOIN photos ph ON lk.photo_id = ph.id
    GROUP  BY ph.user_id
) l ON u.id = l.user_id
LEFT JOIN (SELECT followee_id AS user_id, COUNT(*) AS followers FROM follows GROUP BY followee_id) f
       ON u.id = f.user_id
GROUP  BY time_bucket
ORDER  BY avg_likes_received DESC;


-- ─────────────────────────────────────────────────────────────────────
-- 3. SIGNUP YEAR COHORT — early adopters vs. later joiners
-- ─────────────────────────────────────────────────────────────────────
SELECT
    YEAR(u.created_at)                           AS signup_year,
    COUNT(DISTINCT u.id)                         AS user_count,
    ROUND(AVG(COALESCE(p.photo_count,  0)), 1)   AS avg_photos,
    ROUND(AVG(COALESCE(l.likes_recv,   0)), 1)   AS avg_likes_received,
    ROUND(AVG(COALESCE(c.comments_made,0)), 1)   AS avg_comments_made,
    ROUND(AVG(COALESCE(f.followers,    0)), 1)   AS avg_followers
FROM users u
LEFT JOIN (SELECT user_id, COUNT(*) AS photo_count   FROM photos   GROUP BY user_id) p ON u.id = p.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS comments_made FROM comments GROUP BY user_id) c ON u.id = c.user_id
LEFT JOIN (SELECT ph.user_id, COUNT(*) AS likes_recv FROM likes lk JOIN photos ph ON lk.photo_id = ph.id GROUP BY ph.user_id) l ON u.id = l.user_id
LEFT JOIN (SELECT followee_id AS user_id, COUNT(*) AS followers FROM follows GROUP BY followee_id) f ON u.id = f.user_id
GROUP  BY YEAR(u.created_at)
ORDER  BY signup_year;


-- ─────────────────────────────────────────────────────────────────────
-- 4. USER ACTIVITY SEGMENTS — for targeted campaigns
-- ─────────────────────────────────────────────────────────────────────
SELECT
    u.id,
    u.username,
    COALESCE(p.photo_count,  0)  AS photos_posted,
    COALESCE(c.comments_made,0)  AS comments_made,
    COALESCE(lg.likes_given, 0)  AS likes_given,
    COALESCE(lr.likes_recv,  0)  AS likes_received,
    COALESCE(f.followers,    0)  AS followers,
    CASE
        WHEN COALESCE(p.photo_count,0) = 0
         AND COALESCE(c.comments_made,0) = 0
         AND COALESCE(lg.likes_given,0) = 0  THEN 'Lurker'
        WHEN COALESCE(p.photo_count,0) = 0   THEN 'Engager only'
        WHEN COALESCE(p.photo_count,0) <= 3  THEN 'Casual creator'
        WHEN COALESCE(p.photo_count,0) <= 7  THEN 'Active creator'
        ELSE                                      'Power creator'
    END AS segment
FROM users u
LEFT JOIN (SELECT user_id, COUNT(*) AS photo_count   FROM photos   GROUP BY user_id) p  ON u.id = p.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS comments_made FROM comments GROUP BY user_id) c  ON u.id = c.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS likes_given   FROM likes    GROUP BY user_id) lg ON u.id = lg.user_id
LEFT JOIN (SELECT ph.user_id, COUNT(*) AS likes_recv FROM likes lk JOIN photos ph ON lk.photo_id = ph.id GROUP BY ph.user_id) lr ON u.id = lr.user_id
LEFT JOIN (SELECT followee_id AS user_id, COUNT(*) AS followers FROM follows GROUP BY followee_id) f ON u.id = f.user_id
ORDER  BY photos_posted DESC, likes_received DESC;

-- Summary count per segment
SELECT segment, COUNT(*) AS user_count
FROM (
    SELECT
        CASE
            WHEN COALESCE(p.photo_count,0) = 0
             AND COALESCE(c.comments_made,0) = 0
             AND COALESCE(lg.likes_given,0) = 0  THEN 'Lurker'
            WHEN COALESCE(p.photo_count,0) = 0   THEN 'Engager only'
            WHEN COALESCE(p.photo_count,0) <= 3  THEN 'Casual creator'
            WHEN COALESCE(p.photo_count,0) <= 7  THEN 'Active creator'
            ELSE                                      'Power creator'
        END AS segment
    FROM users u
    LEFT JOIN (SELECT user_id, COUNT(*) AS photo_count   FROM photos   GROUP BY user_id) p  ON u.id = p.user_id
    LEFT JOIN (SELECT user_id, COUNT(*) AS comments_made FROM comments GROUP BY user_id) c  ON u.id = c.user_id
    LEFT JOIN (SELECT user_id, COUNT(*) AS likes_given   FROM likes    GROUP BY user_id) lg ON u.id = lg.user_id
) t
GROUP  BY segment
ORDER  BY FIELD(segment, 'Power creator','Active creator','Casual creator','Engager only','Lurker');


-- ─────────────────────────────────────────────────────────────────────
-- 5. TAG POPULARITY — content interest signals for brand targeting
-- ─────────────────────────────────────────────────────────────────────
SELECT
    t.tag_name,
    COUNT(pt.photo_id)                          AS usage_count,
    COUNT(DISTINCT p.user_id)                   AS unique_creators,
    ROUND(COUNT(pt.photo_id) * 100.0
          / (SELECT COUNT(*) FROM photo_tags), 1) AS pct_of_all_tags
FROM   tags t
JOIN   photo_tags pt ON t.id   = pt.tag_id
JOIN   photos     p  ON pt.photo_id = p.id
GROUP  BY t.tag_name
ORDER  BY usage_count DESC;


-- ─────────────────────────────────────────────────────────────────────
-- 6. BRAND TARGETING — users interested in fashion/beauty
-- ─────────────────────────────────────────────────────────────────────
SELECT DISTINCT
    u.id,
    u.username,
    GROUP_CONCAT(DISTINCT t.tag_name ORDER BY t.tag_name)  AS interests,
    COUNT(DISTINCT pt.photo_id)                             AS tagged_photos
FROM   users u
JOIN   photos     p  ON u.id = p.user_id
JOIN   photo_tags pt ON p.id = pt.photo_id
JOIN   tags       t  ON pt.tag_id = t.id
WHERE  t.tag_name IN ('fashion','beauty','hair','style','stunning')
GROUP  BY u.id, u.username
ORDER  BY tagged_photos DESC;

-- ─────────────────────────────────────────────────────────────────────
-- 7. BRAND TARGETING — users interested in food/dining
-- ─────────────────────────────────────────────────────────────────────
SELECT DISTINCT
    u.id,
    u.username,
    GROUP_CONCAT(DISTINCT t.tag_name ORDER BY t.tag_name)  AS interests,
    COUNT(DISTINCT pt.photo_id)                             AS tagged_photos
FROM   users u
JOIN   photos     p  ON u.id = p.user_id
JOIN   photo_tags pt ON p.id = pt.photo_id
JOIN   tags       t  ON pt.tag_id = t.id
WHERE  t.tag_name IN ('food','foodie','delicious')
GROUP  BY u.id, u.username
ORDER  BY tagged_photos DESC;


-- ─────────────────────────────────────────────────────────────────────
-- 8. RE-ENGAGEMENT LIST — lurkers & engagers who never posted
-- ─────────────────────────────────────────────────────────────────────
SELECT
    u.id,
    u.username,
    DATE(u.created_at)                            AS joined,
    COALESCE(lg.likes_given, 0)                   AS likes_given,
    COALESCE(c.comments_made, 0)                  AS comments_made,
    DATEDIFF(NOW(), u.created_at)                 AS days_since_joined,
    CASE
        WHEN COALESCE(lg.likes_given,0) = 0
         AND COALESCE(c.comments_made,0) = 0      THEN 'Full lurker — send win-back email'
        ELSE                                           'Engager — nudge to first post'
    END AS recommended_action
FROM   users u
LEFT   JOIN (SELECT user_id, COUNT(*) AS likes_given   FROM likes    GROUP BY user_id) lg ON u.id = lg.user_id
LEFT   JOIN (SELECT user_id, COUNT(*) AS comments_made FROM comments GROUP BY user_id) c  ON u.id = c.user_id
WHERE  u.id NOT IN (SELECT DISTINCT user_id FROM photos)
ORDER  BY days_since_joined DESC;

-- Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
-- ══════════════════════════════════════════════════════════════════
-- INFLUENCER IDENTIFICATION & RANKING
-- Metrics:
--   engagement_rate  = (likes_received + comments_received)
--                      / followers × 100
--   reach_score      = followers × engagement_rate
--   content_score    = (avg_likes × 2) + (avg_comments × 3)
-- ══════════════════════════════════════════════════════════════════

WITH

photo_counts AS (
    SELECT user_id, COUNT(*) AS photos_posted
    FROM   photos
    GROUP  BY user_id
),

likes_received AS (
    SELECT p.user_id,
           COUNT(*)              AS total_likes,
           COUNT(*) / COUNT(DISTINCT l.photo_id) AS avg_likes_per_post
    FROM   likes l
    JOIN   photos p ON l.photo_id = p.id
    GROUP  BY p.user_id
),

comments_received AS (
    SELECT p.user_id,
           COUNT(*)              AS total_comments,
           COUNT(*) / COUNT(DISTINCT c.photo_id) AS avg_comments_per_post
    FROM   comments c
    JOIN   photos p ON c.photo_id = p.id
    GROUP  BY p.user_id
),

followers AS (
    SELECT followee_id AS user_id,
           COUNT(*)    AS followers_count
    FROM   follows
    GROUP  BY followee_id
),

following AS (
    SELECT follower_id AS user_id,
           COUNT(*)    AS following_count
    FROM   follows
    GROUP  BY follower_id
),

-- ── User niche via their most-used tags ──────────────────────────
user_niche AS (
    SELECT
        p.user_id,
        CASE
            WHEN GROUP_CONCAT(t.tag_name) REGEXP 'fashion|beauty|hair|style|stunning'
                 THEN 'Fashion/Beauty'
            WHEN GROUP_CONCAT(t.tag_name) REGEXP 'food|foodie|delicious'
                 THEN 'Food'
            WHEN GROUP_CONCAT(t.tag_name) REGEXP 'beach|sunset|landscape|sunrise|photography|dreamy'
                 THEN 'Travel/Nature'
            WHEN GROUP_CONCAT(t.tag_name) REGEXP 'party|concert|fun|lol|drunk'
                 THEN 'Lifestyle'
            WHEN GROUP_CONCAT(t.tag_name) REGEXP 'smile|happy'
                 THEN 'Wellness'
            ELSE 'General'
        END AS niche
    FROM   photos p
    JOIN   photo_tags pt ON p.id  = pt.photo_id
    JOIN   tags       t  ON pt.tag_id = t.id
    GROUP  BY p.user_id
),

-- ── Combine all metrics ───────────────────────────────────────────
base AS (
    SELECT
        u.id,
        u.username,
        COALESCE(pc.photos_posted,    0)  AS photos_posted,
        COALESCE(lr.total_likes,      0)  AS likes_received,
        COALESCE(cr.total_comments,   0)  AS comments_received,
        COALESCE(f.followers_count,   0)  AS followers,
        COALESCE(fg.following_count,  0)  AS following,
        ROUND(COALESCE(lr.avg_likes_per_post,   0), 2) AS avg_likes_per_post,
        ROUND(COALESCE(cr.avg_comments_per_post,0), 2) AS avg_comments_per_post,
        COALESCE(un.niche, 'No content')  AS niche
    FROM       users u
    LEFT JOIN  photo_counts       pc ON u.id = pc.user_id
    LEFT JOIN  likes_received     lr ON u.id = lr.user_id
    LEFT JOIN  comments_received  cr ON u.id = cr.user_id
    LEFT JOIN  followers           f ON u.id = f.user_id
    LEFT JOIN  following          fg ON u.id = fg.user_id
    LEFT JOIN  user_niche         un ON u.id = un.user_id
),

-- ── Compute engagement & reach scores ────────────────────────────
scored AS (
    SELECT *,
        -- Engagement rate
        CASE
            WHEN followers > 0 AND photos_posted > 0
            THEN ROUND((likes_received + comments_received) / followers * 100, 2)
            ELSE 0
        END AS engagement_rate,

        -- Content quality score
        ROUND((avg_likes_per_post * 2) + (avg_comments_per_post * 3), 1)
            AS content_score,

        -- Reach score
        CASE
            WHEN followers > 0 AND photos_posted > 0
            THEN ROUND(followers *
                 ((likes_received + comments_received) / followers * 100), 1)
            ELSE 0
        END AS reach_score
    FROM base
),

-- ── Assign influencer tier ────────────────────────────────────────
tiered AS (
    SELECT *,
        CASE
            WHEN photos_posted = 0 OR followers = 0 THEN 'Inactive'
            WHEN following = 0 AND engagement_rate >= 400  THEN 'Macro'
            WHEN followers >= 76   AND engagement_rate >= 80   THEN 'Micro'
            WHEN followers >= 50                               THEN 'Nano'
            ELSE 'Inactive'
        END AS influencer_tier,
        RANK() OVER (ORDER BY reach_score DESC) AS overall_rank
    FROM scored
)

-- ── Final output ──────────────────────────────────────────────────
SELECT
    overall_rank      AS `rank`,
    username,
    influencer_tier,
    followers,
    following,
    photos_posted,
    likes_received,
    comments_received,
    avg_likes_per_post,
    avg_comments_per_post,
    engagement_rate,
    reach_score,
    content_score,
    niche
FROM   tiered
WHERE  influencer_tier != 'Inactive'
ORDER  BY reach_score DESC;


-- ─────────────────────────────────────────────────────────────────
-- 2. TOP 10 MACRO INFLUENCERS (highest reach — brand launch picks)
-- ─────────────────────────────────────────────────────────────────
SELECT
    RANK() OVER (ORDER BY reach_score DESC)  AS `rank`,
    username,
    followers,
    photos_posted,
    likes_received,
    comments_received,
    ROUND((likes_received + comments_received)
          / followers * 100, 2)              AS engagement_rate,
    ROUND(followers *
          ((likes_received + comments_received)
           / followers * 100), 0)            AS reach_score,
    niche
FROM (
    -- inline CTE equivalent
    SELECT u.username,
           COALESCE(f.fc, 0)  AS followers,
           COALESCE(fg.fc,0)  AS following,
           COALESCE(pc.c, 0)  AS photos_posted,
           COALESCE(lr.c, 0)  AS likes_received,
           COALESCE(cr.c, 0)  AS comments_received,
           COALESCE(un.niche,'General') AS niche,
           ROUND(COALESCE(f.fc,0) *
                 ((COALESCE(lr.c,0)+COALESCE(cr.c,0))
                  / NULLIF(COALESCE(f.fc,0),0) * 100),0) AS reach_score
    FROM users u
    LEFT JOIN (SELECT followee_id AS uid, COUNT(*) AS fc FROM follows GROUP BY followee_id) f ON u.id=f.uid
    LEFT JOIN (SELECT follower_id AS uid, COUNT(*) AS fc FROM follows GROUP BY follower_id) fg ON u.id=fg.uid
    LEFT JOIN (SELECT user_id, COUNT(*) AS c FROM photos GROUP BY user_id) pc ON u.id=pc.user_id
    LEFT JOIN (SELECT p.user_id, COUNT(*) AS c FROM likes l JOIN photos p ON l.photo_id=p.id GROUP BY p.user_id) lr ON u.id=lr.user_id
    LEFT JOIN (SELECT p.user_id, COUNT(*) AS c FROM comments c JOIN photos p ON c.photo_id=p.id GROUP BY p.user_id) cr ON u.id=cr.user_id
    LEFT JOIN (
        SELECT p.user_id,
               CASE WHEN GROUP_CONCAT(t.tag_name) REGEXP 'fashion|beauty|hair|style' THEN 'Fashion/Beauty'
                    WHEN GROUP_CONCAT(t.tag_name) REGEXP 'food|foodie|delicious'      THEN 'Food'
                    WHEN GROUP_CONCAT(t.tag_name) REGEXP 'beach|sunset|landscape'     THEN 'Travel/Nature'
                    WHEN GROUP_CONCAT(t.tag_name) REGEXP 'party|concert|fun'          THEN 'Lifestyle'
                    ELSE 'General' END AS niche
        FROM photos p JOIN photo_tags pt ON p.id=pt.photo_id JOIN tags t ON pt.tag_id=t.id
        GROUP BY p.user_id
    ) un ON u.id=un.user_id
    WHERE COALESCE(fg.fc,0) = 0          -- zero following = Macro signal
      AND COALESCE(pc.c,0) > 0
) t
ORDER BY reach_score DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────────────────
-- 3. BEST MICRO INFLUENCERS BY NICHE (top 5 per niche)
-- ─────────────────────────────────────────────────────────────────
SELECT niche, username, followers, photos_posted,
       engagement_rate, reach_score, content_score
FROM (
    SELECT
        COALESCE(un.niche,'General')  AS niche,
        u.username,
        COALESCE(f.fc,0)              AS followers,
        COALESCE(pc.c,0)              AS photos_posted,
        ROUND((COALESCE(lr.c,0)+COALESCE(cr.c,0))
              / NULLIF(COALESCE(f.fc,0),0)*100,2)  AS engagement_rate,
        ROUND(COALESCE(f.fc,0)*
              ((COALESCE(lr.c,0)+COALESCE(cr.c,0))
               /NULLIF(COALESCE(f.fc,0),0)*100),0) AS reach_score,
        ROUND((COALESCE(lr.c,0)/NULLIF(COALESCE(pc.c,0),0))*2
             +(COALESCE(cr.c,0)/NULLIF(COALESCE(pc.c,0),0))*3,1) AS content_score,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(un.niche,'General')
            ORDER BY
              ROUND(COALESCE(f.fc,0)*((COALESCE(lr.c,0)+COALESCE(cr.c,0))
              /NULLIF(COALESCE(f.fc,0),0)*100),0) DESC
        ) AS rn
    FROM users u
    LEFT JOIN (SELECT followee_id AS uid, COUNT(*) AS fc FROM follows GROUP BY followee_id) f  ON u.id=f.uid
    LEFT JOIN (SELECT follower_id AS uid, COUNT(*) AS fc FROM follows GROUP BY follower_id) fg ON u.id=fg.uid
    LEFT JOIN (SELECT user_id, COUNT(*) AS c FROM photos GROUP BY user_id) pc ON u.id=pc.user_id
    LEFT JOIN (SELECT p.user_id, COUNT(*) AS c FROM likes l JOIN photos p ON l.photo_id=p.id GROUP BY p.user_id) lr ON u.id=lr.user_id
    LEFT JOIN (SELECT p.user_id, COUNT(*) AS c FROM comments c JOIN photos p ON c.photo_id=p.id GROUP BY p.user_id) cr ON u.id=cr.user_id
    LEFT JOIN (
        SELECT p.user_id,
               CASE WHEN GROUP_CONCAT(t.tag_name) REGEXP 'fashion|beauty|hair|style' THEN 'Fashion/Beauty'
                    WHEN GROUP_CONCAT(t.tag_name) REGEXP 'food|foodie|delicious'      THEN 'Food'
                    WHEN GROUP_CONCAT(t.tag_name) REGEXP 'beach|sunset|landscape'     THEN 'Travel/Nature'
                    WHEN GROUP_CONCAT(t.tag_name) REGEXP 'party|concert|fun'          THEN 'Lifestyle'
                    ELSE 'General' END AS niche
        FROM photos p JOIN photo_tags pt ON p.id=pt.photo_id JOIN tags t ON pt.tag_id=t.id
        GROUP BY p.user_id
    ) un ON u.id=un.user_id
    WHERE COALESCE(fg.fc,0) > 0     -- micro = follows others too
      AND COALESCE(pc.c,0)  > 0
) ranked
WHERE rn <= 5
ORDER BY niche, reach_score DESC;


-- ─────────────────────────────────────────────────────────────────
-- 4. INFLUENCER OUTREACH PRIORITY LIST
--    (who to contact first, ranked by ROI potential)
-- ─────────────────────────────────────────────────────────────────
SELECT
    RANK() OVER (ORDER BY
        ROUND((likes_recv + comments_recv) / followers * 100, 2) DESC
    )                         AS outreach_priority,
    username,
    CASE
        WHEN following_ct = 0 THEN 'Macro — Direct partnership offer'
        ELSE                       'Micro — Affiliate / gifting program'
    END                       AS outreach_approach,
    followers,
    photos_posted,
    ROUND((likes_recv + comments_recv) / followers * 100, 2) AS engagement_rate,
    CASE
        WHEN following_ct = 0 AND likes_recv > 300 THEN 'Revenue share + ambassador title'
        WHEN following_ct = 0                       THEN 'Sponsored post + event invite'
        WHEN photos_posted >= 4                     THEN 'Product gifting + commission link'
        ELSE                                             'Trial sample + hashtag challenge'
    END                       AS recommended_offer
FROM (
    SELECT u.username,
           COALESCE(f.fc,0)   AS followers,
           COALESCE(fg.fc,0)  AS following_ct,
           COALESCE(pc.c,0)   AS photos_posted,
           COALESCE(lr.c,0)   AS likes_recv,
           COALESCE(cr.c,0)   AS comments_recv
    FROM users u
    LEFT JOIN (SELECT followee_id uid, COUNT(*) fc FROM follows GROUP BY followee_id) f  ON u.id=f.uid
    LEFT JOIN (SELECT follower_id uid, COUNT(*) fc FROM follows GROUP BY follower_id) fg ON u.id=fg.uid
    LEFT JOIN (SELECT user_id, COUNT(*) c FROM photos GROUP BY user_id) pc ON u.id=pc.user_id
    LEFT JOIN (SELECT p.user_id, COUNT(*) c FROM likes l JOIN photos p ON l.photo_id=p.id GROUP BY p.user_id) lr ON u.id=lr.user_id
    LEFT JOIN (SELECT p.user_id, COUNT(*) c FROM comments c2 JOIN photos p ON c2.photo_id=p.id GROUP BY p.user_id) cr ON u.id=cr.user_id
    WHERE COALESCE(pc.c,0) > 0
) t
ORDER BY engagement_rate DESC;

-- Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?

WITH user_activity AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COALESCE(p.post_count, 0) AS posts,
        COALESCE(l.likes_given, 0) AS likes,
        COALESCE(c.comments_given, 0) AS comments
    FROM users u
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS post_count
        FROM photos
        GROUP BY user_id
    ) p ON u.id = p.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS likes_given
        FROM likes
        GROUP BY user_id
    ) l ON u.id = l.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS comments_given
        FROM comments
        GROUP BY user_id
    ) c ON u.id = c.user_id
),
segmented_users AS (
    SELECT *,
        CASE
            WHEN posts >= 5 AND (likes + comments) >= 15 THEN 'Highly Active'
            WHEN posts BETWEEN 2 AND 4 OR (likes + comments) BETWEEN 5 AND 14 THEN      'Moderately Active'
            WHEN posts = 1 OR (likes + comments) BETWEEN 1 AND 4 THEN 'Low Activity'
            ELSE 'Inactive'
        END AS user_category
    FROM user_activity
)
SELECT * FROM segmented_users;