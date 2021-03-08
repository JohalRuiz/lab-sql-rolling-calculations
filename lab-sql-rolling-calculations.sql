-- Lab | SQL Rolling calculations

use sakila;

-- 1. Get number of monthly active customers.
select * from customer;
select * from rental;

CREATE OR REPLACE VIEW rental_1 AS 
SELECT inventory_id, customer_id, extract(YEAR_MONTH FROM rental_date) as yearmonth FROM rental;
SELECT * FROM rental_1;

SELECT yearmonth, count(distinct customer_id) as monthly_active_customers FROM rental_1 -- distinct is important here to avoid counting several times customers that rented more than one a month
GROUP BY yearmonth; -- monthly active customers

-- Other option with CTE:
WITH cte_monthly_customers AS (
SELECT rental_id, inventory_id, customer_id, extract(YEAR_MONTH FROM rental_date) as yearmonth FROM rental
)
SELECT yearmonth, count(distinct customer_id) as monthly_active_customers FROM rental_1
GROUP BY yearmonth;


-- 2. Active users in the previous month.
USE sakila;
CREATE OR REPLACE VIEW monthly_active_users AS 
SELECT yearmonth, count(distinct customer_id) AS Active_users FROM rental_1
GROUP BY yearmonth
ORDER BY yearmonth;

SELECT * FROM monthly_active_users;

CREATE OR REPLACE VIEW monthly_active_users_comparison AS 
SELECT yearmonth, Active_users, LAG(Active_users) OVER (ORDER BY yearmonth) AS Last_month
FROM monthly_active_users;
SELECT * FROM monthly_active_users_comparison;

-- 3. Percentage change in the number of active customers.
WITH cte_comparison AS (
SELECT yearmonth, Active_users, LAG(Active_users) OVER (ORDER BY yearmonth) AS Last_month
FROM monthly_active_users_comparison)
SELECT *, (Active_users-Last_month) AS Difference, (Active_users-Last_month)/Active_users*100 AS Percentage_variation
FROM cte_comparison;
-- OR:
SELECT *, (Active_users-Last_month) AS Difference, (Active_users-Last_month)/Active_users*100 AS Percentage_variation 
FROM monthly_active_users_comparison; -- easier solution using previous view

-- 4. Retained customers every month
USE sakila;
select * from rental;
select * from rental_1;
select * from monthly_active_users;
select * from monthly_active_users_comparison;

-- step 1: get the unique active users per month
CREATE OR REPLACE VIEW distinct_customers AS
SELECT DISTINCT customer_id AS Active_id, yearmonth FROM rental_1
ORDER BY yearmonth, customer_id;

SELECT * FROM distinct_customers;

-- step 2: 
CREATE OR REPLACE VIEW monthly_distinct_customers AS
SELECT yearmonth, count(yearmonth) as Active_users
from distinct_customers
group by yearmonth;
SELECT * FROM monthly_distinct_customers;

-- step3: self-joining the table
select *, lag(Active_users) over () from monthly_distinct_customers;

create or replace view retained_customers as 
select d1.yearmonth, count(distinct d1.Active_id) as Retained_customers -- (so 3 columns in total)
from distinct_customers as d1
join distinct_customers as d2
on d1.Active_id = d2.Active_id 
and d2.yearmonth = d1.yearmonth + 1 
group by d1.yearmonth
order by d1.yearmonth;

SELECT * FROM retained_customers;

