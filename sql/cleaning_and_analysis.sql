-- 2. Validate Data
-- 2.1 Calculate min, max, average ride lengths
SELECT 
  MIN(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS min_ride_length,
  MAX(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS max_ride_length,
  AVG(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS avg_ride_length
FROM `still-lamp-487710-j6.cyclistic_analytics.trips_raw`;
-- NOTE: This validation check is run on raw data.
-- Cleaned behavioural metrics are calculated using vw_trips_clean below.


-- 2.2 Count negative, zero-minute and >24 hour rides
SELECT
  COUNTIF((TIMESTAMP_DIFF(ended_at, started_at, MINUTE))<0) AS invalid_negative_ride_count,
  COUNTIF((TIMESTAMP_DIFF(ended_at, started_at, MINUTE))=0) AS zero_minute_ride_count,
  COUNTIF((TIMESTAMP_DIFF(ended_at, started_at, MINUTE))>1440) AS invalid_long_ride_count
FROM `still-lamp-487710-j6.cyclistic_analytics.trips_raw`;


-- 2.3 Percentage of negative, zero-minute and >24 hour rides
SELECT
  ROUND(100*COUNTIF((TIMESTAMP_DIFF(ended_at, started_at, MINUTE))<0)/COUNT(*),4) AS invalid_negative_ride_percentage,
  ROUND(100*COUNTIF((TIMESTAMP_DIFF(ended_at, started_at, MINUTE))=0)/COUNT(*),4) AS zero_minute_ride_percentage,
  ROUND(100*COUNTIF((TIMESTAMP_DIFF(ended_at, started_at, MINUTE))>1440)/COUNT(*),4) AS invalid_long_ride_percentage
FROM `still-lamp-487710-j6.cyclistic_analytics.trips_raw`;
-- Invalid ride durations represent a negligible percentage of the total dataset and will be excluded from subsequent analysis to ensure behavioural metrics are not distorted.


-- 3. Transform Data
-- 3.1.1 Create clean view (apply validated duration filters)
CREATE OR REPLACE VIEW `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean` AS
SELECT *
FROM (
  SELECT
    *,
    TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS ride_length_minutes
  FROM `still-lamp-487710-j6.cyclistic_analytics.trips_raw`
)
WHERE ride_length_minutes > 0
  AND ride_length_minutes <= 1440;


-- 3.1.2 Validate clean view
SELECT
  COUNT(*) AS clean_row_count
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`;
-- Confirms clean view row count reflects removal of invalid durations.


-- 4. Analyse Data
-- 4.1 Data Exploration
-- 4.1.1 Members vs Casual riders
SELECT
  member_casual,
  COUNT(*) AS total_rides
FROM still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean
GROUP BY (member_casual);

-- 4.1.2 Average ride length by type
SELECT
  member_casual,
  ROUND(AVG(ride_length_minutes),2) AS avg_ride_length_minutes
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
GROUP BY member_casual;

-- 4.1.3 Rides by Day of Week
-- a) members
SELECT
  FORMAT_DATE('%A', DATE(started_at)) AS day_of_week,
  COUNT(*) AS total_rides
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
WHERE member_casual = 'member'
GROUP BY day_of_week
ORDER BY total_rides DESC;

-- b) casual
SELECT
  FORMAT_DATE('%A', DATE(started_at)) AS day_of_week,
  COUNT(*) AS total_rides
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
WHERE member_casual = 'casual'
GROUP BY day_of_week
ORDER BY total_rides DESC;

-- 4.1.4 Rides by Hour of Day, grouped by type
-- a) member
SELECT
  EXTRACT(HOUR FROM started_at) AS hour_of_day,
  COUNT(*) AS total_rides
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
WHERE member_casual = 'member'
GROUP BY hour_of_day
ORDER BY total_rides DESC;

-- b) casual
SELECT
  EXTRACT(HOUR FROM started_at) AS hour_of_day,
  COUNT(*) AS total_rides
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
WHERE member_casual = 'casual'
GROUP BY hour_of_day
ORDER BY total_rides DESC;

-- 4.1.5 Rides by month (analyzing seasonal trends)
-- a) member
SELECT
  EXTRACT(MONTH FROM started_at) AS month,
  COUNT(*) AS monthly_ride_total
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
WHERE member_casual = 'member'
GROUP BY month
ORDER BY monthly_ride_total DESC;

-- b) casual
SELECT
  EXTRACT(MONTH FROM started_at) AS month,
  COUNT(*) AS monthly_ride_total
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
WHERE member_casual = 'casual'
GROUP BY month
ORDER BY monthly_ride_total DESC;

-- 4.1.6 Rideable Type Preference
SELECT
  member_casual,
  rideable_type,
  COUNT(*) AS total_rides
FROM `still-lamp-487710-j6.cyclistic_analytics.vw_trips_clean`
GROUP BY member_casual, rideable_type
ORDER BY member_casual, total_rides DESC;
