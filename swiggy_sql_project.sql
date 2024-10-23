-- EDA

SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

-- here, order is very important. O/W error. Because, we've establihed relationship b/w all the tables (ERD). 
-- import datasets


-- let's check for NULL Values

SELECT COUNT(*) FROM customers
WHERE 
	customer_id IS NULL    -- customer_id can't be NULL > it's PRIMARY KEY
	OR
	customer_name IS NULL
	OR 
	reg_date IS NULL;


SELECT COUNT(*) FROM restaurants
WHERE 
	restaurant_id IS NULL    -- restaurant_id can't be NULL > it's PRIMARY KEY
	OR
	restaurant_name IS NULL
	OR 
	city IS NULL
	OR
	opening_hours IS NULL;


SELECT * FROM orders  --- order_id can't be NULL > it's PRIMARY KEY, customer_id & restaurant_id can't be NULL > FOREIGN KEY
WHERE 
	order_item IS NULL
	OR 
	order_date IS NULL
	OR
	order_time IS NULL
	OR
	order_status IS NULL
	OR 
	total_amount IS NULL;


--supose some values in 'orders' table are NULL. How to remove those values? > 
-- DELETE FROM orders
-- WHERE 
--	order_item IS NULl
--	OR 
--	order_date IS NULL
--	OR
--	order_time IS NULL
--	OR
--	order_status IS NULL
--	OR 
--	total_amount IS NULL;

SELECT * 
FROM 
	deliveries
WHERE                        -- other 3 columns are either PK or FK. No need to check. 
	delivery_time IS NULL
	OR
	delivery_status IS NULL;



-- -----------------------------
-- Analysis & Reports
-- -----------------------------

-- Q1. Top 5 Most Frequently Ordered Dishes
-- Question:
-- Write a query to find the top 5 most frequently ordered dishes by the customer "Arjun Mehta" in the last 1 year.

-- Approach:
-- (1) join cx & orders
-- (2) filter for lst 1 yr
-- (3) filter 'Arjun Mehta'
-- (4) group by cx id, dishes, cnt

-- Method - 1
SELECT 
	c.customer_id,
	c.customer_name,
	o.order_item AS dishes,
	COUNT(*) AS total_orders,
	DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rank
FROM 
	orders as o
JOIN
	customers as c
ON
	o.customer_id = c.customer_id
WHERE
	o.order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
	AND
	c.customer_name = 'Arjun Mehta'
GROUP BY 
	1, 2, 3
ORDER BY
	1, 4 DESC;

-- to get top 5 rank; we can't directly use WHERE & put DENSE_RANK or rank. > we need to use CTE

SELECT 
	customer_name,
	dishes,
	total_orders
FROM (
	SELECT 
		c.customer_id,
		c.customer_name,
		o.order_item AS dishes,
		COUNT(*) AS total_orders,
		DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rank
	FROM 
		orders as o
	JOIN
		customers as c
	ON
		o.customer_id = c.customer_id
	WHERE
		o.order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
		AND
		c.customer_name = 'Arjun Mehta'
	GROUP BY 
		1, 2, 3
	ORDER BY
		1, 4 DESC
     ) AS t1
WHERE 
	RANK <= 5;


-- Method - 2
SELECT 
	orders.order_item,
	COUNT(orders.order_id) AS total_orders
FROM
	customers
LEFT JOIN
	orders
ON
	customers.customer_id = orders.customer_id
WHERE
	customer_name = 'Arjun Mehta' AND
	orders.order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
GROUP BY
	orders.order_item
ORDER BY
	total_orders DESC;


-- Q2. Popular Time Slots
-- Question:
-- Identify the time slots during which the most orders are placed, based on 2-hour intervals.

-- Approach: (solve with 2 approach)
-- (1) we'll create 2 hour slots from order_time.

-- Approach 1:-

-- SELECT 00:59:59 AM > 0
-- SELECT 01:59:59 AM > 1

SELECT 
	CASE 
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
	END AS time_slot,
	COUNT(order_id) AS order_count
FROM 
	orders
GROUP BY
	time_slot
ORDER BY
	order_count DESC;

-- Approach 2: little complicated, but easy to apply if understand properly

SELECT
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 AS start_time,   --23/2=11.5 ,FLOOR(23/2)=11*2=22 >start_time & 22+2=24 >end_time
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 + 2 AS end_time,
	COUNT(*) AS total_orders
FROM 
	orders
GROUP BY
	1, 2
ORDER BY
	3 DESC;


-- Q3. Order Value Analysis
-- Question:
-- Find the average order value (AOV) per customer who has placed more than 750 orders.
-- Return: customer_name, aov (average order value).

SELECT * FROM ORDERS;

SELECT
	customer_name,
	AVG(orders.total_amount) AS AOV,
	COUNT(orders.order_id) AS total_order_placed
FROM
	customers
LEFT JOIN
	orders
ON
	customers.customer_id = orders.customer_id
GROUP BY
	customer_name
HAVING
	COUNT(orders.order_id) > 750
ORDER BY
 	total_order_placed DESC;
	

-- Approach 2:

SELECT
	customer_id,
	COUNT(order_id) AS total_orders,
	AVG(total_amount) AS aov
FROM
	orders
GROUP BY 
	1
HAVING
	COUNT(order_id) > 750;

-- APPLYING JOIN B/W customers & orders

SELECT
	--o.customer_id,                    -- "o or c". No worries
	c.customer_name,
	AVG(o.total_amount) AS aov
FROM
	orders AS o
JOIN
	customers AS c
ON
	o.customer_id = c.customer_id
GROUP BY 
	1
HAVING
	COUNT(order_id) > 750;


-- Q4. High-Value Customers
-- Question:
-- List the customers who have spent more than 100K in total on food orders.
-- Return: customer_name, customer_id.

SELECT
	o.customer_id,
	c.customer_name,
	SUM(total_amount) AS total_food_orders
FROM
	orders AS o
JOIN
	customers AS c
ON
	o.customer_id = c.customer_id
GROUP BY
	1, 2
HAVING
	SUM(total_amount) > 100000


-- Q5. Orders Without Delivery   "CRITICAL QUESTION" > important to know, due to which reasons, restaurants couldn't deliver order
-- Question:
-- Write a query to find orders that were placed but not delivered.
-- Return: restaurant_name, city, and the number of not delivered orders.

SELECT 
	r.restaurant_name,
	COUNT(o.order_id) AS cnt_not_delivered_orders
FROM 
	orders AS o
LEFT JOIN
	restaurants AS r
ON
	o.restaurant_id = r.restaurant_id 
LEFT JOIN
	deliveries AS d
ON
	o.order_id = d.order_id
WHERE
	d.delivery_id IS NULL
GROUP BY
	1
ORDER BY
	cnt_not_delivered_orders DESC;


-- Q6. Restaurant Revenue Ranking
-- Question:
-- Rank restaurants by their total revenue from the last year.
-- Return: restaurant_name, total_revenue, and their rank within their city.

SELECT 
	r.city,
	r.restaurant_name,
	SUM(o.total_amount) AS revenue,
	RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
FROM	
	orders AS o
JOIN
	restaurants AS r
ON
	o.restaurant_id = r.restaurant_id
WHERE
	o.order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
GROUP BY
	1, 2
ORDER BY
	1, 3 DESC;

-- Applying CTE to know rank 1 fro all the city
WITH ranking_table
AS
(
	SELECT 
		r.city,
		r.restaurant_name,
		SUM(o.total_amount) AS revenue,
		RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
	FROM	
		orders AS o
	JOIN
		restaurants AS r
	ON
		o.restaurant_id = r.restaurant_id
	WHERE
		o.order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
	GROUP BY
		1, 2
	ORDER BY
		1, 3 DESC
)
SELECT *
FROM 
	ranking_table
WHERE 
	rank = 1;


-- Q7. Most Popular Dish by City
-- Question:
-- Identify the most popular dish in each city based on the number of orders.


-- Using CTE 
WITH ranking_table
AS
(
	SELECT
		r.city AS city,
		o.order_item AS most_popular_dish,
		COUNT(o.order_id) AS total_orders,
		RANK() OVER(PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS rank
	FROM
		orders AS o
	JOIN
		restaurants AS r
	ON
		o.restaurant_id = r.restaurant_id
	GROUP BY
		1, 2
)
SELECT 
	city,
	most_popular_dish
FROM
	ranking_table
WHERE
	rank = 1;

-- If I'll use SUM(o.total_amount) >> result will be different

-- Using Subquery
SELECT
	city,
	most_popular_dish
FROM
	(
	SELECT
			r.city AS city,
			o.order_item AS most_popular_dish,
			COUNT(o.order_id) AS total_orders,
			RANK() OVER(PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS rank
		FROM
			orders AS o
		JOIN
			restaurants AS r
		ON
			o.restaurant_id = r.restaurant_id
		GROUP BY
			1, 2
	)
WHERE
	rank = 1; 


-- Q8. Customer Churn
-- Question:
-- Find customers who haven’t placed an order in 2024 but did in 2023.

-- We need to figure out 2 things:
-- (1) find customers who has done orders in 2023
-- (2) find customers who has NOT done ordes in 2024
-- (3) compare (1) & (2) using subqueries

SELECT 
	DISTINCT o.customer_id,
	c.customer_name
FROM 
	orders AS o
JOIN
	customers AS c
ON
	o.customer_id = c.customer_id
WHERE
	EXTRACT(YEAR FROM order_date) = 2023
	AND
	o.customer_id NOT IN
				(
				SELECT customer_id FROM orders
				WHERE EXTRACT(YEAR FROM order_date) = 2024
				)


-- Q9. Cancellation Rate Comparison
-- Question:
-- Calculate and compare the order cancellation rate for each restaurant between the current year and the previous year.

SELECT                  
	o.restaurant_id,
	COUNT(o.order_id) AS total_orders,
	COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
FROM 
	orders AS o
LEFT JOIN
	deliveries AS d
ON
	d.order_id = o.order_id
WHERE
	EXTRACT(YEAR FROM order_date) = 2023
GROUP BY
	1;

-- to find out cancellation rate >>  not delivered/total_orders


WITH cancel_ratio
AS
(
	SELECT                  
		o.restaurant_id,
		COUNT(o.order_id) AS total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
	FROM 
		orders AS o
	LEFT JOIN
		deliveries AS d
	ON
		d.order_id = o.order_id
	WHERE
		EXTRACT(YEAR FROM order_date) = 2023
	GROUP BY
		1
)
SELECT
	restaurant_id,
	total_orders,
	not_delivered,
	ROUND(
	not_delivered::numeric / total_orders::numeric * 100 ,
	2) AS cancel_ratio
FROM
	cancel_ratio;
	
----------------
-- to compare --
----------------

WITH cancel_ratio_23 AS (
	-- Get the total orders and undelivered orders for 2023
	SELECT                  
		o.restaurant_id,
		COUNT(o.order_id) AS total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
	FROM 
		orders AS o
	LEFT JOIN
		deliveries AS d
	ON
		d.order_id = o.order_id
	WHERE
		EXTRACT(YEAR FROM order_date) = 2023
	GROUP BY
		o.restaurant_id
),
cancel_ratio_24 AS (
	-- Get the total orders and undelivered orders for 2024
	SELECT                  
		o.restaurant_id,
		COUNT(o.order_id) AS total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
	FROM 
		orders AS o
	LEFT JOIN
		deliveries AS d
	ON
		d.order_id = o.order_id
	WHERE
		EXTRACT(YEAR FROM order_date) = 2024
	GROUP BY
		o.restaurant_id
),
last_year_data AS (
	-- Calculate cancel ratio for 2023
	SELECT
		restaurant_id,
		total_orders,
		not_delivered,
		ROUND(
			(not_delivered::numeric / total_orders::numeric) * 100, 
			2
		) AS cancel_ratio
	FROM
		cancel_ratio_23
),
current_year_data AS (
	-- Calculate cancel ratio for 2024
	SELECT
		restaurant_id,
		total_orders,
		not_delivered,
		ROUND(
			(not_delivered::numeric / total_orders::numeric) * 100, 
			2
		) AS cancel_ratio
	FROM
		cancel_ratio_24
)

-- Perform the final join to compare cancel ratios between 2023 and 2024
SELECT 
	c.restaurant_id AS restaurant_id,
	l.cancel_ratio AS last_year_cancel_ratio,
	c.cancel_ratio AS current_year_cancel_ratio
FROM
	current_year_data AS c
INNER JOIN
	last_year_data AS l
ON
	c.restaurant_id = l.restaurant_id;


-- Q10. Rider Average Delivery Time
-- Question:
-- Determine each rider's average delivery time.


SELECT
	o.order_id,
	o.order_time,
	d.delivery_time,
	d.rider_id,
	d.delivery_time - o.order_time AS time_difference,
	EXTRACT(
			EPOCH FROM (
						d.delivery_time - o.order_time +
						CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 DAY'
						ELSE INTERVAL '0 DAY' END))/60 AS time_diff_min
FROM 
	orders AS o
JOIN 
	deliveries AS d
ON
	o.order_id = d.delivery_id
WHERE
	d.delivery_status = 'Delivered'
ORDER BY
time_diff_min ASC;

-- EXTRACT(EPOCH FROM ...)> time interval into a number representing seconds. "Epoch" time format as the number of seconds 




-- Q11. Monthly Restaurant Growth Ratio
-- Question:
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining.


WITH growth_ratio 
AS 
(SELECT
	restaurant_id,
	TO_CHAR(o.order_date, 'mm-yy') AS month,
	COUNT(o.order_id) AS cr_month_orders,
	LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date, 'mm-yy')) AS prev_month_orders
FROM 
	orders AS o
JOIN
	deliveries AS d
ON
	o.order_id = d.order_id
WHERE
	d.delivery_status = 'Delivered'
GROUP BY
	1, 2
ORDER BY
	1, 2
)
SELECT
	restaurant_id,
	month,
	prev_month_orders,
	cr_month_orders,
	ROUND(
	(cr_month_orders::Numeric - prev_month_orders::Numeric)/cr_month_orders::Numeric * 100 , 2) AS growth_ratio
FROM
	growth_ratio;



-- Q12. Customer Segmentation
-- Question:
-- Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the average order value (AOV). 
-- If a customer's total spending exceeds the AOV, label them as 'Gold'; otherwise, label them as 'Silver'.
-- Return: The total number of orders and total revenue for each segment.


SELECT
	customer_category,
	SUM(total_orders) AS total_orders,
	SUM(total_spent) AS total_revenue
FROM
(
	SELECT
		customer_id,
		SUM(total_amount) AS total_spent,
		COUNT(order_id) AS total_orders,
		CASE 
			WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
			ELSE 'Silver'
		END AS customer_category
	FROM
		orders
	GROUP BY
		1
	ORDER BY
		1
) AS t1
GROUP BY 1;


-- Q13. Rider Monthly Earnings
-- Question:
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.


SELECT * FROM orders;
SELECT * FROM deliveries;

SELECT
	d.rider_id,
	TO_CHAR(o.order_date, 'mm-yy') AS month,
	SUM(o.total_amount)*0.08 AS earning
FROM
	deliveries AS d
LEFT JOIN
	orders AS o
ON
	d.order_id = o.order_id
WHERE 
	delivery_status = 'Delivered'
GROUP BY
	1,2
ORDER BY
	1,2


-- Q14. Rider Ratings Analysis
-- Question:
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- Riders receive ratings based on delivery time:
-- ● 5-star: Delivered in less than 15 minutes
-- ● 4-star: Delivered between 15 and 20 minutes
-- ● 3-star: Delivered after 20 minutes


SELECT
	rider_id,
	rating,
	COUNT(*) AS total_rating
FROM
(
	SELECT
		rider_id,
		time_taken_delivery,
		CASE
			WHEN time_taken_delivery < 15 THEN '5-star'
			WHEN time_taken_delivery BETWEEN 15 AND 20 THEN '4-star'
			ELSE '3-star'
		END AS rating
	FROM
	(
		SELECT 
			o.order_id,
			o.order_time,
			d.delivery_time,
			EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
			CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 DAY'
			ELSE '0 DAY' END
			)) / 60  AS time_taken_delivery,                  -- converting into minutes
			d.rider_id
		FROM 
			deliveries AS d
		JOIN
			orders AS o
		ON
			d.order_id = o.order_id
		WHERE 
			d.delivery_status = 'Delivered'
	) AS t1
) AS t2
GROUP BY 1, 2
ORDER BY 1, 3 DESC;



-- Q15. Order Frequency by Day
-- Question:
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.


SELECT
	restaurant_name,
	day,
	total_orders
FROM
(
	SELECT
		r.restaurant_name,
		TO_CHAR(o.order_date, 'Day') AS day,
		COUNT(o.order_id) AS total_orders,
		RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC)
	FROM
		orders AS o
	JOIN
		restaurants AS r
	ON
		o.restaurant_id = r.restaurant_id
	GROUP BY 
		1, 2
	ORDER BY
		1, 3 DESC
)
WHERE 
	rank = 1;



-- Q16. Customer Lifetime Value (CLV)
-- Question:
-- Calculate the total revenue generated by each customer over all their orders.

SELECT
	c.customer_name,
	SUM(o.total_amount) AS CLV
FROM
	customers AS c
JOIN
	orders AS o
ON
	c.customer_id = o.customer_id
GROUP BY
	1
ORDER BY
	2 DESC;



-- Q17. Monthly Sales Trends
-- Question:
-- Identify sales trends by comparing each month's total sales to the previous month.

SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month,
	SUM(total_amount) AS total_sale,
	LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) AS prev_month_sale
FROM
	orders
GROUP BY
	1, 2



-- Q18. Rider Efficiency
-- Question:
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.


WITH new_table
AS
(
	SELECT  
		*,
		d.rider_id AS riders_id,
		ROUND(EXTRACT(EPOCH FROM(d.delivery_time - o.order_time +
			  CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 DAY'
		      ELSE INTERVAL '0 DAY' END)) / 60, 2) AS time_deliver
	FROM
		orders AS o
	JOIN
		deliveries AS d
	ON
		o.order_id = d.order_id
	WHERE
		d.delivery_status = 'Delivered'
),
riders_time AS
(
SELECT
	riders_id,
	AVG(time_deliver) AS avg_delivery_time
FROM 
	new_table
GROUP BY 1
)
SELECT
	MIN(avg_delivery_time),
	MAX(avg_delivery_time)
FROM
	riders_time




-- Q19. Order Item Popularity
-- Question:
-- Track the popularity of specific order items over time and identify seasonal demand spikes.


SELECT
	order_item,
	seasons,
	COUNT(order_id) AS total_orders
FROM(
	SELECT
		*,
		EXTRACT(MONTH FROM order_date) AS month,
		CASE 
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 3 AND 4 THEN 'Spring'
			WHEN EXTRACT(MONTH FROM order_date) > 4 AND EXTRACT(MONTH FROM order_date) < 7 THEN 'Summer'
			WHEN EXTRACT(MONTH FROM order_date) > 6 AND EXTRACT(MONTH FROM order_date) < 10 THEN 'Monsoon'
			WHEN EXTRACT(MONTH FROM order_date) > 9 AND EXTRACT(MONTH FROM order_date) < 12 THEN 'Autumn'
			ELSE 'Winter'
		END AS seasons
	FROM
		orders
	) AS t1
GROUP BY
	1, 2
ORDER BY
	1, 3 DESC


-- Q20. City Revenue Ranking
-- Question:
-- Rank each city based on the total revenue for the last year (2023).


SELECT
	EXTRACT(YEAR FROM o.order_date) AS year,
	r.city,
	SUM(o.total_amount) AS total_revenue,
	RANK() OVER(ORDER BY SUM(o.total_amount) DESC) AS city_rank
FROM
	restaurants AS r
JOIN
	orders AS o
ON
	r.restaurant_id = o.restaurant_id
GROUP BY
	1, 2
HAVING
	EXTRACT(YEAR FROM o.order_date) = 2023
ORDER BY
	4


-----------------------------------------------------------------------
-- END OF REPORT OF SWIGGY_SALES
-----------------------------------------------------------------------

