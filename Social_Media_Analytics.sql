-- Table creation
CREATE TABLE users (
    user_id BIGINT PRIMARY KEY,
    username VARCHAR(50),
    signup_date DATE
);

CREATE TABLE posts (
    post_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    content TEXT,
    post_date TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE likes (
    like_id BIGINT PRIMARY KEY,
    post_id BIGINT,
    user_id BIGINT,
    like_date TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Query: Most active users (by posts)
SELECT u.username, COUNT(p.post_id) AS post_count
FROM users u
JOIN posts p ON u.user_id = p.user_id
GROUP BY u.username
ORDER BY post_count DESC
LIMIT 10;

-- Query: Trending posts (most likes in last 7 days)
SELECT p.post_id, p.content, COUNT(l.like_id) AS recent_likes
FROM posts p
JOIN likes l ON p.post_id = l.post_id
WHERE l.like_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY p.post_id, p.content
ORDER BY recent_likes DESC
LIMIT 5;