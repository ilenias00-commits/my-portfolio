-- Set up
CREATE DATABASE gms_project;

-- Combine tables
CREATE TABLE gms_project.data_combined AS (
	SELECT * FROM gms_project.data_10
    UNION ALL
    SELECT * FROM gms_project.data_11
    UNION ALL 
    SELECT * FROM gms_project.data_12

);

-- Data Exploration
SELECT *
FROM gms_project.data_combined
LIMIT 5;


SELECT 
	COUNT(*) AS total_rows,
	COUNT(visitid) AS total_rows_not_null
FROM gms_project.data_combined;


SELECT
	visitid,
    COUNT(*) AS total_rows
FROM gms_project.data_combined
GROUP BY 1
HAVING COUNT(*) > 1;


SELECT 
	CONCAT(fullvisitorid, '-', visitid) AS unique_session_id,
    COUNT(*) AS total_rows
FROM gms_project.data_combined
GROUP BY 1
HAVING COUNT(*) > 1;


SELECT 
	CONCAT(fullvisitorid, '-', visitid) AS unique_session_id,
    FROM_UNIXTIME(date) + INTERVAL -9 HOUR AS date,
    COUNT(*) AS total_rows
FROM gms_project.data_combined
GROUP BY 1,2
HAVING unique_session_id = '4961200072408009421-1480578925';


-- Website Engagement by date

SELECT
	date,
    COUNT(DISTINCT unique_session_id) AS sessions
FROM (	
	SELECT
		DATE(FROM_UNIXTIME(date)) AS date,
		CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2
    ) AS t1
GROUP BY 1
ORDER BY 1
;


-- Website Engagement by day

SELECT
	DAYNAME(date) AS weekday,
    COUNT(DISTINCT unique_session_id) AS sessions
FROM (	
	SELECT
		DATE(FROM_UNIXTIME(date)) AS date,
		CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2
    ) AS t1
GROUP BY 1
ORDER BY 2 DESC
;


-- Website Engagement & Monetization by day
SELECT
	DAYNAME(date) AS weekday,
    COUNT(DISTINCT unique_session_id) AS sessions,
    SUM(converted) AS conversions,
    ((SUM(converted)/COUNT(DISTINCT unique_session_id)) * 100) AS conversion_percentage
FROM (
	SELECT
		DATE(FROM_UNIXTIME(date)) AS date,
        CASE
			WHEN transactions > 0 THEN 1
            ELSE 0
		END AS converted,
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2,3
) AS t1
GROUP BY 1
ORDER BY 2 DESC;


-- Website Engagement & Monetization by device
SELECT
	device,
    COUNT(DISTINCT unique_session_id) AS sessions,
    ((COUNT(DISTINCT unique_session_id)/SUM(COUNT(DISTINCT unique_session_id)) OVER()) *100) AS session_percentage,
    SUM(transactionrevenue)/1e6 AS revenue,
    ((SUM(transactionrevenue)/SUM(SUM(transactionrevenue)) OVER()) *100) AS revenue_percentage
FROM (
	SELECT
		deviceCategory AS device,
        transactionrevenue,
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id	
	FROM gms_project.data_combined
	GROUP BY 1,2,3
) AS t1
GROUP BY 1;
   
   
-- Website Engagement & Monetization by region
SELECT 
	device,
    region,
    COUNT(DISTINCT unique_session_id) AS sessions,
	((COUNT(DISTINCT unique_session_id)/SUM(COUNT(DISTINCT unique_session_id)) OVER()) *100) AS session_percentage,
    SUM(transactionrevenue)/1e6 AS revenue,
    ((SUM(transactionrevenue)/SUM(SUM(transactionrevenue)) OVER()) *100) AS revenue_precentage
FROM (
		SELECT
			deviceCategory AS device,
			CASE
				WHEN region = '' OR region IS NULL THEN 'N/A'
				ELSE region
			END AS region,
			transactionrevenue,
			CONCAT(fullvisitorid,'-',visitid) AS unique_session_id
		FROM gms_project.data_combined
        WHERE deviceCategory = 'mobile'
		GROUP BY 1,2,3,4
) AS t1
GROUP BY 1,2
ORDER BY 3 DESC;


-- Web Retention
SELECT 
	CASE
		WHEN newvisits > 0 THEN 'New Visitor'
        ELSE 'Returning Visitor'
        END AS visitor_type,
	COUNT(DISTINCT(fullvisitorid)) AS visitors,
    ((COUNT(DISTINCT(fullvisitorid))/SUM(COUNT(DISTINCT(fullvisitorid))) OVER()) *100) AS visitor_percentage
FROM gms_project.data_combined
GROUP BY 1;


-- Website Acquisition
SELECT
	COUNT(DISTINCT unique_session_id) AS sessions,
    SUM(bounces) AS bounces,
    (SUM(bounces)/COUNT(DISTINCT unique_session_id) *100) AS bounce_rate
FROM (
	SELECT 
		bounces,
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2
) AS t1
ORDER BY 1 DESC;


-- Website Acquisition by Channel
SELECT
	channelGrouping,
    COUNT(DISTINCT unique_session_id) AS sessions,
    SUM(bounces) AS bounces,
    (SUM(bounces)/COUNT(DISTINCT unique_session_id) *100) AS bounce_rate
FROM (
	SELECT 
		channelGrouping,
        bounces,
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2,3
) AS t1
GROUP BY 1
ORDER BY 1 DESC;


-- Website Acquisition & Monetization by Channel
SELECT
	channelGrouping,
    COUNT(DISTINCT unique_session_id) AS sessions,
    SUM(bounces) AS bounces,
    ((SUM(bounces)/COUNT(DISTINCT unique_session_id)) *100) AS bounce_rate,
    AVG(pageviews) AS avg_pageviews,
    AVG(timeonsite) AS avg_timeonsite,
    SUM(CASE WHEN transactions > 0 THEN 1 ELSE 0 END) AS conversions,
    ((SUM(CASE WHEN transactions > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT unique_session_id)) *100) AS conversion_rate,
    SUM(transactionrevenue)/1e6 AS revenue,
    ((SUM(transactionrevenue)/SUM(SUM(transactionrevenue)) OVER()) *100) AS revenue_percentage
FROM (
		SELECT
			channelGrouping,
			bounces,
			transactionrevenue,
            pageviews,
			timeonsite,
			transactions,
			CONCAT(fullvisitorid,'-',visitid) AS unique_session_id
		FROM gms_project.data_combined
		GROUP BY 1,2,3,4,5,6,7
) AS t1
GROUP BY 1
ORDER BY 2 DESC;


-- Website visits and conversions by hour
SELECT
	HOUR(date) AS hour,
    COUNT(DISTINCT unique_session_id) AS sessions,
    SUM(CASE WHEN transactions > 0 THEN 1 ELSE 0 END) AS conversions,
    ((SUM(CASE WHEN transactions > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT unique_session_id)) *100) AS conversion_rate
FROM (
	SELECT
		TIMESTAMP(FROM_UNIXTIME(date)) AS date,
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id,
		transactions
	FROM gms_project.data_combined
	GROUP BY 1,2,3
) AS t1
GROUP BY 1
ORDER BY 4 DESC;


-- Website visits and conversions by region
SELECT
	region,
    COUNT(DISTINCT unique_session_id) AS sessions,
    SUM(CASE WHEN transactions > 0 THEN 1 ELSE 0 END) AS conversions,
    ((SUM(CASE WHEN transactions > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT unique_session_id)) *100) AS conversion_rate
FROM (
	SELECT
		CASE 
			WHEN region = '' OR region IS NULL THEN 'N/A'
            ELSE region
		END AS region,
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id,
		transactions
	FROM gms_project.data_combined
	GROUP BY 1,2,3
) AS t1
GROUP BY 1
ORDER BY 2 DESC, 4 ASC;


-- Customer segmentation

SELECT
	buyer_type,
    COUNT(DISTINCT unique_session_id) AS sessions,
    AVG(pageviews) AS avg_pageviews,
    AVG(timeonscreen) AS avg_timeonscreen,
    SUM(transactionrevenue)/1e6 AS revenue
FROM (
	SELECT	
		CASE
			WHEN transactions > 1 THEN 'Bulk Buyer'
			WHEN transactions = 1 THEN 'Individual Buyer'
			ELSE 'No purchase'
		END AS buyer_type,
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id,
        pageviews,
        timeonscreen,
        transactionrevenue
	FROM gms_project.data_combined
    WHERE transactions <> 0
    GROUP BY 1,2,3,4,5
) AS t1
GROUP BY 1;


-- Transaction Value Assessment
SELECT
	COUNT(DISTINCT unique_session_id) AS sessions,
    AVG(transactionrevenue)/1e6 AS avg_transaction_value
FROM (
	SELECT
		CONCAT(fullvisitorid,'-',visitid) AS unique_session_id,
		transactions,
		transactionrevenue
	FROM gms_project.data_combined
	WHERE transactions <> 0
	GROUP BY 1,2,3
) AS t1;
	