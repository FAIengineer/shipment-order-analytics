SELECT * FROM orders_data

-- Write a SQL query to list all distinct cities where orders have been shipped.

SELECT DISTINCT city FROM orders_data ORDER BY city

-- Calculate the total selling price and profits for all orders

SELECT order_id, SUM(quantity*unit_selling_price)::DECIMAL(10,2) AS total_selling_price, 
	sum(quantity*unit_profit)::DECIMAL(10,2) AS total_profit 
	FROM orders_data GROUP BY 1 ORDER BY 3

-- Write a query to find all the orders from the 'Technology' category that were shipped 
-- using 'Second Class' ship mode, ordered by Order Date
SELECT order_id, order_date, category, ship_mode FROM orders_data 
	WHERE category = 'Technology' AND ship_mode = 'Second Class' ORDER BY 2

-- Write a query to find the average order value
SELECT AVG(quantity*unit_selling_price)::DECIMAL(10,2) AS average FROM orders_data

--Find the city with the highest total quantity of products ordered
SELECT * FROM orders_data
SELECT city, SUM(quantity) FROM orders_data GROUP BY city ORDER BY 2 DESC

--Use a window function to rank orders in each region by quantity in descending order
SELECT order_id, region, quantity, 
	DENSE_RANK() OVER(PARTITION BY region ORDER BY quantity DESC) AS ranking 
	FROM orders_data ORDER BY 2,4

--Write a SQL query to list all orders placed in the first quarter of any year (January to March), including the total cost for these orders.

SELECT order_id, EXTRACT(MONTH FROM order_date) AS month_number, 
	(quantity*unit_selling_price)::DECIMAL(10,2) AS total_cost 
	FROM orders_data WHERE EXTRACT(MONTH FROM order_date) IN (1,2,3)
	ORDER BY 3 DESC

--Find top 10 highest profit generating prducts
SELECT product_id, SUM(total_profit)::DECIMAL(10,2) AS total_profit 
FROM orders_data GROUP BY product_id ORDER BY 2 DESC LIMIT 10

--Alternative using Window Function With Ranking
WITH cte AS (
SELECT product_id, SUM(total_profit)::DECIMAL(10,2) AS total_profit,
ROW_NUMBER() OVER(ORDER BY SUM(total_profit) DESC) AS ranking
FROM orders_data GROUP BY product_id ORDER BY 2 DESC
) 
SELECT * FROM cte WHERE ranking <=10 ORDER BY ranking

--Find top 3 highest selling products in each region based on total sale price
WITH cte AS (
SELECT product_id, region, SUM(quantity*unit_selling_price)::DECIMAL(10,2) AS total_sales,
	ROW_NUMBER() OVER(PARTITION BY region ORDER BY SUM(quantity*unit_selling_price) DESC) AS ranking
	FROM orders_data GROUP BY 1,2
)
SELECT * FROM cte WHERE ranking <= 3 ORDER BY region

--Find month over month growth comparison for 2022 and 2023 sales eg: Jan 2022 vs Jan 2023
WITH cte AS (
SELECT EXTRACT(MONTH FROM order_date) AS month_number, 
SUM(quantity*unit_selling_price)::DECIMAL(10,2) AS profits_2022
	FROM orders_data WHERE EXTRACT(YEAR FROM order_date) = 2022 
	GROUP BY month_number
), 
cte2 AS (
SELECT EXTRACT(MONTH FROM order_date) AS month_number, 
SUM(quantity*unit_selling_price)::DECIMAL(10,2) AS profits_2023
	FROM orders_data WHERE EXTRACT(YEAR FROM order_date) = 2023 
	GROUP BY month_number
)
SELECT cte.month_number, profits_2022, profits_2023, 
	(((profits_2023-profits_2022)/profits_2022)*100)::DECIMAL(10,2) AS growth_percentage 
FROM cte JOIN cte2 ON cte.month_number = cte2.month_number

--For each category, which month had the highest sales
WITH cte AS (
SELECT category, TO_CHAR(order_date, 'YYYY-MM') AS year_month, 
	SUM(quantity*unit_selling_price)::DECIMAL(10,2) AS total_sales,
	DENSE_RANK() OVER(PARTITION BY category ORDER BY SUM(quantity*unit_selling_price) DESC) as ranking
	FROM orders_data
	GROUP BY category, year_month
)
SELECT * FROM cte WHERE ranking = 1

--Which sub category had the highest growth percentage by sales in 2023 compared to 2022
WITH cte AS (
SELECT sub_category,
	SUM(quantity*unit_selling_price)::DECIMAL(10,2) AS sales_2022
	FROM orders_data WHERE EXTRACT(YEAR FROM order_date) = 2022 
	GROUP BY sub_category
), 
cte2 AS (
SELECT sub_category, 
	SUM(quantity*unit_selling_price)::DECIMAL(10,2) AS sales_2023
	FROM orders_data WHERE EXTRACT(YEAR FROM order_date) = 2023 
	GROUP BY sub_category
)
SELECT cte.sub_category, sales_2022, sales_2023, 
	(((sales_2023-sales_2022)/sales_2022)*100)::DECIMAL(10,2) AS growth_percentage 
	FROM cte JOIN cte2 ON cte.sub_category = cte2.sub_category
	ORDER BY growth_percentage DESC