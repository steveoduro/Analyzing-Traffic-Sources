-- **Analyzing top traffic sources**

-- Sessions breakdown before April 12th, 2012 by utm_source, utm_campaign, and http_referer
SELECT utm_source,
		utm_campaign,
        http_referer,
        COUNT(website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 1,2,3
ORDER BY 4 DESC;

-- Conversion rate from top website_session to order before April 14th, 2012
SELECT  COUNT(ws.website_session_id) AS website_sessions,
        COUNT(o.order_id) AS orders_from_session,
        (COUNT(o.order_id)/COUNT(ws.website_session_id))*100 AS gsearch_cvr
FROM website_sessions AS ws
	LEFT JOIN orders as o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-04-14'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND http_referer = 'https://www.gsearch.com'
ORDER BY 3 DESC;

-- Bid Optimization and Trend Analysis

--  Since CVR was below threshold (4%), bid was cut to save money on April 15,2012. Have the bid change caused volume of sessions to drop?
SELECT WEEK(created_at) AS week_num,
		MIN(DATE(created_at)) AS start_of_week,
		COUNT(website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND http_referer = 'https://www.gsearch.com'
GROUP BY 1
ORDER BY 1;

-- conversion rate from session to order by device type to change bid optimization
SELECT  device_type,
		COUNT(ws.website_session_id) AS website_sessions,
        COUNT(o.order_id) AS orders_from_session,
        (COUNT(o.order_id)/COUNT(ws.website_session_id))*100 AS cvr
FROM website_sessions AS ws
	LEFT JOIN orders as o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-05-11'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND http_referer = 'https://www.gsearch.com'
GROUP BY 1
ORDER BY 3 DESC;

-- increased bid for desktop devices. Has session volume changed since bid was taken place on May 19, 2012?
SELECT
		WEEK(created_at) AS week_num,
		MIN(DATE(created_at)) AS start_of_week,
        COUNT(CASE
				WHEN device_type = 'desktop' THEN website_session_id ELSE null END) AS desktop_sessions,
        COUNT(CASE
				WHEN device_type = 'mobile' THEN website_session_id ELSE null END) AS mobile_sessions        
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-09'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND http_referer = 'https://www.gsearch.com'
GROUP BY 1
ORDER BY 1;

-- Analyzing top website content

-- creating a temporary table for entry landing page ONLY
CREATE TEMPORARY TABLE first_pageview
SELECT website_session_id,
		MIN(website_pageview_id) AS min_pv_id		
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY 1;

-- number of sessions landing on url page(s) first
SELECT pageview_url AS landing_page,
		COUNT(DISTINCT first_pageview.website_session_id) AS sessions_landing_on_url_first
FROM first_pageview
	LEFT JOIN website_pageviews wpv
		ON wpv.website_pageview_id = first_pageview.min_pv_id;

-- Most viewed website pages ranked by session volume before 2012-06-09
SELECT pageview_url,
		COUNT(DISTINCT website_pageview_id) AS session_volume
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY 2 DESC;

-- Is the list representative of top landing pages? list of top entry landing pages
WITH first_page_view AS (
	SELECT website_session_id,
		MIN(website_pageview_id) AS min_pv_id		
	FROM website_pageviews
	WHERE created_at < '2012-06-12'
	GROUP BY 1
)

SELECT wpv.pageview_url,
		COUNT(DISTINCT first_page_view.min_pv_id) AS first_landing_sessions
FROM first_page_view
	LEFT JOIN website_pageviews wpv
		ON wpv.website_pageview_id = first_page_view.min_pv_id
WHERE created_at < '2012-06-12'
GROUP BY 1
ORDER BY 2 DESC;

-- **Compare landing page performance**
/*

-- find first pageview for relevant sessions, 
-- find sessions from first pageview that made progress to other pages, 
-- then analyze url bounce rate
CREATE TEMPORARY TABLE first_page_view
	SELECT website_session_id,
		MIN(website_pageview_id) AS min_pv_id		
	FROM website_pageviews
	WHERE created_at BETWEEN '2014-01-01' AND '2014-02-01'
	GROUP BY 1;
    
CREATE TEMPORARY TABLE multiple_pageviews
SELECT website_session_id,
		MIN(website_pageview_id) AS min_pv_id		
	FROM website_pageviews
	WHERE created_at BETWEEN '2014-01-01' AND '2014-02-01'
	GROUP BY 1
    HAVING COUNT(website_session_id) > 1;


SELECT wpv.pageview_url,
		COUNT(DISTINCT first_page_view.min_pv_id) AS first_landing_sessions,
        COUNT(DISTINCT multiple_pageviews.min_pv_id) AS continued_sessions,
		(COUNT(DISTINCT first_page_view.min_pv_id)-COUNT(DISTINCT multiple_pageviews.min_pv_id))/COUNT(DISTINCT first_page_view.min_pv_id)*100 AS bounce_rate
FROM first_page_view
	LEFT JOIN website_pageviews wpv
		ON wpv.website_pageview_id = first_page_view.min_pv_id
	LEFT JOIN multiple_pageviews
		ON multiple_pageviews.min_pv_id = first_page_view.min_pv_id
GROUP BY 1
ORDER BY 4;
DROP TABLE IF EXISTS first_page_view;
DROP TABLE IF EXISTS multiple_pageviews;
*/

-- How is the landing page performing as of June 14, 2012? Sessions, Bounced Sessions and Bounce Session rate
CREATE TEMPORARY TABLE first_pv
SELECT website_session_id,
		MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1;

CREATE TEMPORARY TABLE cont_session
SELECT first_pageview_id AS cont_session_pv_id,
		COUNT(wpv.website_session_id) AS multi_session_count
FROM first_pv
	LEFT JOIN website_pageviews wpv
		ON wpv.website_session_id = first_pv.website_session_id
GROUP BY 1
HAVING COUNT(wpv.website_session_id) > 1;

SELECT wpv.pageview_url,
		COUNT(first_pageview_id) AS sessions,
        (COUNT(first_pageview_id)-COUNT(cont_session.cont_session_pv_id)) AS bounced_sessions,
		(COUNT(first_pageview_id)-COUNT(cont_session.cont_session_pv_id))/COUNT(first_pageview_id)*100 AS bounced_session_rate
FROM first_pv
	LEFT JOIN website_pageviews wpv
		ON wpv.website_pageview_id = first_pv.first_pageview_id
	LEFT JOIN cont_session
		ON cont_session.cont_session_pv_id = wpv.website_pageview_id
GROUP BY 1;

-- A new landing page has been built, and has been in a 50/50 test against the homepage for gsearch traffic. Pull bounce rate for the 2 groups starting from when the test for lander1 against homepage began
/* This is when /lander1 began getting traffic
SELECT MIN(created_at)
FROM website_pageviews
WHERE created_at < '2012-07-28'
		AND pageview_url='/lander-1'
        
*/ 

CREATE TEMPORARY TABLE first_sessions
SELECT wpv.website_session_id,
		MIN(wpv.website_pageview_id) AS first_pv_id
FROM website_sessions ws
	LEFT JOIN website_pageviews wpv
		ON ws.website_session_id = wpv.website_session_id
WHERE wpv.created_at BETWEEN '2012-06-19' AND  '2012-07-28'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1;

CREATE TEMPORARY TABLE cont_sessions
SELECT first_pv_id,
		COUNT(wpv.website_session_id) AS cont_session
FROM first_sessions
	LEFT JOIN website_pageviews wpv
		ON wpv.website_session_id = first_sessions.website_session_id
GROUP BY 1
HAVING COUNT(wpv.website_session_id) > 1;

SELECT pageview_url,
		(COUNT(first_sessions.first_pv_id)-COUNT(cont_sessions.first_pv_id))/COUNT(first_sessions.first_pv_id)*100 AS bounce_rate
FROM first_sessions
	LEFT JOIN website_pageviews wpv
		ON first_sessions.first_pv_id = wpv.website_pageview_id
	LEFT JOIN cont_sessions
		ON wpv.website_pageview_id = cont_sessions.first_pv_id
GROUP BY 1;

-- volume of paid search nonbrand traffic landing on home and lander1 trended weekly since June 1st
WITH volume AS (
	SELECT wpv.website_session_id,
			MIN(wpv.website_pageview_id) AS first_pv_id
	FROM website_sessions ws
		LEFT JOIN website_pageviews wpv
			ON wpv.website_session_id = ws.website_session_id
	WHERE ws.created_at BETWEEN '2012-06-01' AND '2012-08-31'
		AND utm_source IN ('gsearch','bsearch')
		AND utm_campaign = 'nonbrand'
		AND pageview_url IN('/home','/lander-1')
	GROUP BY 1
),
single_session AS (
	SELECT first_pv_id,
			COUNT(wpv.website_session_id) AS single_sessions
	FROM volume
		LEFT JOIN website_pageviews wpv
			ON volume.website_session_id = wpv.website_session_id
	GROUP BY 1
	HAVING COUNT(wpv.website_session_id) = 1
)
SELECT 	WEEK(created_at) AS week_num,
		MIN(DATE(created_at))AS week_start_date,
		COUNT(CASE 
				WHEN pageview_url = '/home' THEN volume.first_pv_id ELSE null END) AS home_traffic_volume,
		COUNT(CASE
				WHEN pageview_url = '/lander-1' THEN volume.first_pv_id ELSE null END) AS lander1_traffic_volume,
		(COUNT(volume.first_pv_id) - COUNT(single_session.first_pv_id)) / COUNT(volume.first_pv_id)*100 AS bounce_rate
FROM volume
	LEFT JOIN website_pageviews wpv
		ON wpv.website_pageview_id = volume.first_pv_id
	LEFT JOIN single_session
		ON volume.first_pv_id = single_session.first_pv_id
GROUP BY 1;

WITH volume AS (
	SELECT wpv.website_session_id,
			MIN(wpv.website_pageview_id) AS first_pv_id
	FROM website_sessions ws
		LEFT JOIN website_pageviews wpv
			ON wpv.website_session_id = ws.website_session_id
	WHERE ws.created_at < '2012-08-31'
		AND utm_source IN ('gsearch','bsearch')
	GROUP BY 1
 ),
single_session AS (
	SELECT first_pv_id,
			COUNT(wpv.website_session_id) AS single_sessions
	FROM volume
		LEFT JOIN website_pageviews wpv
			ON volume.website_session_id = wpv.website_session_id
	GROUP BY 1
	HAVING COUNT(wpv.website_session_id) = 1
)
SELECT WEEK(created_at),
		MIN(DATE(created_at))AS week_start_date,
        (COUNT(volume.first_pv_id) - COUNT(single_session.first_pv_id)) / COUNT(volume.first_pv_id)*100 AS bounce_rate
FROM volume
	LEFT JOIN single_session
		ON volume.first_pv_id = single_session.first_pv_id
	LEFT JOIN website_pageviews wpv
		ON wpv.website_pageview_id = volume.first_pv_id
WHERE created_at BETWEEN '2012-06-01' AND '2012-08-31'
GROUP BY 1;