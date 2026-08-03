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
'''sql
SELECT booking_id ,COUNT(*) as cnt
FROM hotel_bookings
GROUP BY booking_id
HAVING cnt>1;
'''

**Orphaned Foreign Keys: None found — every booking maps to a valid customer_id and hotel_id; no broken joins.**

**Impossible Values: None found — no bookings with zero/negative number_of_nights or negative per_night_rate.**

**Date Logic: None found — no booking has a stay_start_date earlier than its booking_date.**

**Coverage: Bookings were made between Oct 2023 and Nov 2024, for stays between Sep 2024 and Dec 2024. The dataset is clean and required no corrective transformation.**
