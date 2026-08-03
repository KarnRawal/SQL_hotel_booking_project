-- Data Exploration and Cleaning
-- Check 1: Do we have any duplicate booking IDs in the Hotel Booking table? 
SELECT booking_id ,COUNT(*) as cnt
FROM hotel_bookings
GROUP BY booking_id
HAVING cnt>1;
-- Clear

-- Check 2: orphaned foreign keys (bookings pointing to customer_id/hotel_id that don't exist)
SELECT *
FROM hotel_bookings hb 
LEFT JOIN customer cus ON hb.customer_id = cus.customer_id
WHERE cus.customer_id IS NULL ;


SELECT *
FROM hotel_bookings hb 
LEFT JOIN hotels h ON hb.hotel_id= h.id
WHERE h.id IS NULL ;
-- Clear


-- Check 3: impossible values (zero or negative number of nights, negative per night rates)
SELECT number_of_nights, per_night_rate 
FROM hotel_bookings 
WHERE number_of_nights <= 0 OR per_night_rate < 0;

-- Clear

-- Check 4: date logic (stay_start_date before booking_date, unreasonable date ranges)

SELECT * 
FROM hotel_bookings
WHERE stay_start_date < booking_date;

SELECT 
MIN(booking_date), MAX(booking_date), MIN(stay_start_date), MAX(stay_start_date) 
FROM hotel_bookings;

-- Timeframe for this data
SELECT YEAR(booking_date) as year
FROM hotel_bookings
GROUP BY year;

-- Total number of bookings
SELECT COUNT(*) AS total_bookings
FROM hotel_bookings;





-- Data Analyis 


-- Q: Which customers never did any booking?
SELECT * FROM  customers
WHERE customer_id NOT IN (SELECT customer_id FROM hotel_bookings);


-- Q. What is the number of bookings made per month for each year

SELECT
YEAR(booking_date) AS booking_year,
MONTHNAME(booking_date) AS booking_month,
COUNT(*) AS number_of_bookings
FROM hotel_bookings
GROUP BY booking_year, booking_month, MONTH(booking_date)
ORDER BY booking_year, MONTH(booking_date);

-- Q. What's total revenue per month for each year?
SELECT YEAR(booking_date) AS Year ,MONTHNAME(booking_date) AS Month ,SUM(number_of_nights * per_night_rate) AS revenue 
FROM hotel_bookings
GROUP BY Year, MONTH(booking_date), Month 
ORDER BY Year, MONTH(booking_date);

-- Q: What's total revenue and total bookings per hotel?

SELECT h.name ,SUM(hb.number_of_nights * hb.per_night_rate) AS revenue, COUNT(*) AS number_of_bookings
FROM hotel_bookings hb 
LEFT JOIN hotels h ON h.id=hb.hotel_id 
GROUP BY h.name
ORDER BY revenue DESC, number_of_bookings DESC;


-- Q: Find the average number of days customers book in advance for each hotel.
SELECT hotel_id, 
AVG(TIMESTAMPDIFF(DAY,booking_date,stay_start_date)*1.0) AS avg_advanced_booked_days
FROM hotel_bookings
GROUP BY hotel_id;


-- Q: For each hotel what is the average stay duration
SELECT hotel_id , AVG(number_of_nights*1.0) AS avg_duration
FROM hotel_bookings
GROUP BY hotel_id;


-- Q: What is the revenue and booking count split by gender, and what percent of total revenue does each gender represent?
SELECT cus.gender,
ROUND(SUM(hb.number_of_nights * hb.per_night_rate),2) AS revenue, 
ROUND(100*SUM(hb.number_of_nights * hb.per_night_rate)/(SELECT SUM(number_of_nights * per_night_rate) FROM hotel_bookings_clean),2) AS percent_contribution,
COUNT(*) 
FROM hotel_bookings hb
LEFT JOIN customer cus ON cus.customer_id=hb.customer_id
GROUP BY cus.gender;

-- Q: What is the percent contribution by females in terms of revenue and no of bookings for each hotel														
SELECT hb.hotel_id , COUNT(*) as total_bookings,
SUM(CASE WHEN cus.gender='F' THEN 1 END) AS female_bookings,
SUM(per_night_rate*number_of_nights) AS total_revenue,
SUM(CASE WHEN cus.gender='F' THEN per_night_rate*number_of_nights END) AS female_revenue,
ROUND(SUM(CASE WHEN cus.gender='F' THEN 1 END) *100.0/ COUNT(*),2) AS female_booking_percent,
ROUND(SUM(CASE WHEN cus.gender='F' THEN per_night_rate*number_of_nights END)*100/SUM(per_night_rate*number_of_nights),2) AS female_revenue_percent
FROM hotel_bookings hb
JOIN customers cus ON hb.customer_id=cus.customer_id
GROUP BY hb.hotel_id;



-- Q: Which age group books the most, and spends the most? (18-24, 25-34, 35-42, 42+ are the age buckets)
WITH customer_age AS
(SELECT customer_id,TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS age FROM customer)

SELECT 
(CASE
	WHEN ca.age BETWEEN 18 AND 24 THEN '18-24'
    WHEN ca.age BETWEEN 25 AND 34 THEN '25-34'
    WHEN ca.age BETWEEN 35 AND 42 THEN '35-42'
    ELSE '43+' END ) AS age_group,
COUNT(*) AS number_of_bookings,
SUM(hb.number_of_nights * hb.per_night_rate) AS revenue 
FROM hotel_bookings hb
JOIN customer_age ca ON ca.customer_id=hb.customer_id
GROUP BY age_group
ORDER BY revenue DESC, number_of_bookings DESC;


-- Q: What % of bookings are local (customer's home city = hotel's city) vs travel?
SELECT 
CASE WHEN cus.city_id = h.city_id THEN 'Local' ELSE 'Travel' END AS booking_type,
COUNT(*) AS number_of_bookings,
ROUND(100* COUNT(*)/(SELECT COUNT(*) FROM hotel_bookings_clean),2) AS percent_contribution_of_booking_type
FROM hotel_bookings hb
JOIN customer cus ON hb.customer_id = cus.customer_id
JOIN hotels h ON hb.hotel_id = h.id
GROUP BY booking_type;


-- Q: Find the top 5 customers who did most number booking in the same city where they live. Display customer id and percent of those bookings compare to total number of bookings done by them.	
SELECT hb.customer_id , COUNT(*) as number_of_bookings
, COUNT(CASE WHEN h.city_id = cus.city_id THEN booking_id END) AS local_bookings
, COUNT(CASE WHEN h.city_id = cus.city_id THEN booking_id END)*100.0 / COUNT(*) as local_bookings_percent
from hotel_bookings hb
JOIN hotels h on hb.hotel_id=h.id
JOIN customer cus on hb.customer_id=cus.customer_id
GROUP BY hb.customer_id
ORDER BY local_bookings DESC, local_bookings_percent DESC
LIMIT 5 
;


-- Q: What is the volume and revenue split by booking channel?
SELECT
booking_channel,
COUNT(*) AS number_of_bookings,
SUM(number_of_nights * per_night_rate) AS revenue,
ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM hotel_bookings_clean), 2) AS percent_of_bookings
FROM hotel_bookings
GROUP BY booking_channel
ORDER BY revenue DESC;