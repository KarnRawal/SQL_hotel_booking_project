# Hotel Booking SQL Project

## Project Overview
This is a project done in MySQL for the purpose of demonstrating SQL skills. It involves exploration, cleaning, and analysis of a hotel booking dataset. The dataset contains data of various bookings at multiple hotels and cities in India and has four different tables:-

1. hotel_bookings  : This table contains the data at each booking level. Customer id in this table refers to id in customers table and city id refers to id in cities table														
2. customer : Details of all the customers . City id refers to the id of cities table and it tells you to the home city of the  customer
3. hotels: details of each hotel . City id refers to id in city table and this tells you the city where hotel is located
4. cities : details of each city along with state where it is located


<img width="604" height="411" alt="Screenshot 2026-08-03 at 10 40 47 PM" src="https://github.com/user-attachments/assets/6362068c-3478-4384-b510-c7097752843b" />

## Project Structure 
### 1. Data Cleaning Checks and Data Exploration

**Duplicate Booking IDs: None found — all 4,954 booking_id values in hotel_bookings are unique.**

```sql
SELECT booking_id ,COUNT(*) as cnt
FROM hotel_bookings
GROUP BY booking_id
HAVING cnt>1;
```

**Orphaned Foreign Keys: None found — every booking maps to a valid customer_id and hotel_id; no broken joins.**

```sql
SELECT *
FROM hotel_bookings hb 
LEFT JOIN customer cus ON hb.customer_id = cus.customer_id
WHERE cus.customer_id IS NULL ;

SELECT *
FROM hotel_bookings hb 
LEFT JOIN hotels h ON hb.hotel_id= h.id
WHERE h.id IS NULL ;
```
**Impossible Values: None found — no bookings with zero/negative number_of_nights or negative per_night_rate.**

```sql
SELECT number_of_nights, per_night_rate 
FROM hotel_bookings 
WHERE number_of_nights <= 0 OR per_night_rate < 0;
```

**Date Logic: None found — no booking has a stay_start_date earlier than its booking_date.**

```sql
SELECT * 
FROM hotel_bookings
WHERE stay_start_date < booking_date;

SELECT 
MIN(booking_date), MAX(booking_date), MIN(stay_start_date), MAX(stay_start_date) 
FROM hotel_bookings;
```

**Coverage: Bookings were made between Oct 2023 and Nov 2024, for stays between Sep 2024 and Dec 2024. The dataset is clean and required no corrective transformation.**

```sql
SELECT YEAR(booking_date) as year
FROM hotel_bookings
GROUP BY year;
```
### 2. Data Analysis and Findings

The following SQL queries were developed to answer specific business questions:

1. **Which customers never did any booking?**
```sql
SELECT * FROM  customers
WHERE customer_id NOT IN (SELECT customer_id FROM hotel_bookings);
```
2. **What's the number of bookings made per month for each year?**

```sql
SELECT
YEAR(booking_date) AS booking_year,
MONTHNAME(booking_date) AS booking_month,
COUNT(*) AS number_of_bookings
FROM hotel_bookings
GROUP BY booking_year, booking_month, MONTH(booking_date)
ORDER BY booking_year, MONTH(booking_date);

```

3. **What's total revenue per month for each year?**

```sql
SELECT YEAR(booking_date) AS Year ,MONTHNAME(booking_date) AS Month ,SUM(number_of_nights * per_night_rate) AS revenue 
FROM hotel_bookings
GROUP BY Year, MONTH(booking_date), Month 
ORDER BY Year, MONTH(booking_date);
```

4. **What's total revenue and total bookings per hotel?**

```sql
SELECT h.name ,SUM(hb.number_of_nights * hb.per_night_rate) AS revenue, COUNT(*) AS number_of_bookings
FROM hotel_bookings hb 
LEFT JOIN hotels h ON h.id=hb.hotel_id 
GROUP BY h.name
ORDER BY revenue DESC, number_of_bookings DESC;
```

5. **Find the average number of days customers book in advance for each hotel.**

```sql
SELECT hotel_id, 
AVG(TIMESTAMPDIFF(DAY,booking_date,stay_start_date)*1.0) AS avg_advanced_booked_days
FROM hotel_bookings
GROUP BY hotel_id;
```

6. **For each hotel what is the average stay duration.**

```sql
SELECT hotel_id , AVG(number_of_nights*1.0) AS avg_duration
FROM hotel_bookings
GROUP BY hotel_id;
```

7. **What is the revenue and booking count split by gender, and what percent of total revenue does each gender represent?**

```sql
SELECT cus.gender,
ROUND(SUM(hb.number_of_nights * hb.per_night_rate),2) AS revenue, 
ROUND(100*SUM(hb.number_of_nights * hb.per_night_rate)/(SELECT SUM(number_of_nights * per_night_rate) FROM hotel_bookings_clean),2) AS percent_contribution,
COUNT(*) 
FROM hotel_bookings hb
LEFT JOIN customer cus ON cus.customer_id=hb.customer_id
GROUP BY cus.gender;
```

8. **What is the percent contribution by females in terms of revenue and no of bookings for each hotel**

```sql
SELECT hb.hotel_id , COUNT(*) as total_bookings,
SUM(CASE WHEN cus.gender='F' THEN 1 END) AS female_bookings,
SUM(per_night_rate*number_of_nights) AS total_revenue,
SUM(CASE WHEN cus.gender='F' THEN per_night_rate*number_of_nights END) AS female_revenue,
ROUND(SUM(CASE WHEN cus.gender='F' THEN 1 END) *100.0/ COUNT(*),2) AS female_booking_percent,
ROUND(SUM(CASE WHEN cus.gender='F' THEN per_night_rate*number_of_nights END)*100/SUM(per_night_rate*number_of_nights),2) AS female_revenue_percent
FROM hotel_bookings hb
JOIN customers cus ON hb.customer_id=cus.customer_id
GROUP BY hb.hotel_id;

```

9. **Which age group books the most, and spends the most? (18-24, 25-34, 35-42, 42+ are the age buckets)**

```sql
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
```

10. **What % of bookings are local (customer's home city = hotel's city) vs travel?**
```sql
SELECT 
CASE WHEN cus.city_id = h.city_id THEN 'Local' ELSE 'Travel' END AS booking_type,
COUNT(*) AS number_of_bookings,
ROUND(100* COUNT(*)/(SELECT COUNT(*) FROM hotel_bookings_clean),2) AS percent_contribution_of_booking_type
FROM hotel_bookings hb
JOIN customer cus ON hb.customer_id = cus.customer_id
JOIN hotels h ON hb.hotel_id = h.id
GROUP BY booking_type;
```

11. **Find the top 5 customers who did most number booking in the same city where they live. Display customer id and percent of those bookings compare to total number of bookings done by them.**
```sql
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
```

12. **What is the volume and revenue split by booking channel?**
```sql
SELECT
booking_channel,
COUNT(*) AS number_of_bookings,
SUM(number_of_nights * per_night_rate) AS revenue,
ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM hotel_bookings_clean), 2) AS percent_of_bookings
FROM hotel_bookings
GROUP BY booking_channel
ORDER BY revenue DESC;
```
### Findings
* Scale: The dataset covers 4,954 bookings across 500 booking customers (out of 501 total customers — 1 customer has never booked) at 10 hotels across 20 cities, generating $1,313,554.94 in total revenue.
* Booking Volume Trend: Volume ramped up sharply through 2024, peaking in September 2024 (2,249 bookings, ~$588K revenue) — nearly 4x the next-busiest month (October: 1,582 bookings, ~$391K) — before falling off steeply in November. This points to a strong seasonal/promotional spike in September rather than a steady trend.
* Hotel Performance: Revenue is fairly evenly distributed across properties (~$124K–$145K each). ITC Grand leads in revenue ($144.7K, 521 bookings), followed closely by Lalitha Mahal ($143.8K) and Fortune ($138.0K, the highest booking count at 527). Southern Star trails the pack ($124.0K).
* Booking Lead Time & Stay Length: Customers book 21–25 days in advance on average depending on hotel (Fortune highest at 25 days, Leela Palace lowest at 21 days), and stays average 1.7–1.9 nights — this is a short-stay market with fairly consistent behavior across properties.
* Gender Split: Revenue and bookings are nearly even between genders — Female customers contribute 50.2% of revenue (2,478 bookings) vs. Male at 49.8% (2,476 bookings). At the hotel level, female revenue share ranges narrowly from 47.9% (The Oberoi) to 52.8% (Royal Orchid) — no hotel skews meaningfully toward one gender.
* Age Group: The 25–34 age group is the clear leader, driving 1,637 bookings and $432K in revenue (33% of total revenue) despite being only the largest customer segment (169 of 500 customers) — they also spend the most per booking on average of any group.
* Local vs. Travel: The vast majority of bookings are travel-driven (96.0%, 4,758 bookings); only 3.96% (196 bookings) are local (customer's home city matches the hotel's city). This is overwhelmingly a tourism/travel booking base, not a local-stay business.
* Top Local Bookers: A small handful of customers book unusually often in their own city — the top being Customer #101 (13 bookings, 69% local) and Customer #268 (11 bookings, 55% local) — likely frequent local/business stayers worth flagging separately from the travel majority.
* Booking Channel: Velora.com is the top channel by both bookings (1,273, 25.7%) and revenue ($347K), followed by GDS ($329K) and at-the-hotel walk-ins (24.4% of bookings). The App and Phone channels lag well behind, and Other is negligible (0.14%).
* Top Spenders: The five highest-spending individual customers each generated over $5,100 in lifetime revenue (top: Customer #56 at $5,630), each having also booked well above the ~$265 average booking value.

