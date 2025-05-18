create database buildweek2;
use buildweek2;

-- 1. Customers who placed more than 5 orders with a total spend above 10,000
SELECT customer_id, 
       COUNT(order_id) AS order_count, 
       SUM(price * quantity) AS total_spent
FROM ecommerce
GROUP BY customer_id
HAVING COUNT(order_id) > 5 AND SUM(price * quantity) > 10000;


-- 2. Top 5 highest revenue-generating products
SELECT product, 
       ROUND(SUM(price * quantity),2) AS total_revenue
FROM ecommerce
GROUP BY product
ORDER BY total_revenue DESC
LIMIT 5;


-- 3. Find the month with the highest number of orders
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
       COUNT(order_id) AS total_orders
FROM ecommerce
GROUP BY order_month
ORDER BY total_orders DESC
LIMIT 1;


-- 4. Find the product with the highest return rate
SELECT product, 
       COUNT(CASE WHEN status = 'Returned' THEN 1 END) * 100 / COUNT(*) AS return_rate_percent
FROM ecommerce
GROUP BY product
ORDER BY return_rate DESC
LIMIT 1;


-- 5. Which day of the week has the highest average sales volume?
SELECT DAYOFWEEK(order_date) - 1 AS weekday, 
       AVG(price * quantity) AS avg_sales
FROM ecommerce
GROUP BY weekday
ORDER BY avg_sales DESC
LIMIT 1;


-- 6. Detect any products with an unusually high quantity sold in a single order (potential fraud detection)
SELECT order_id, product, quantity
FROM ecommerce
WHERE quantity > (
    SELECT AVG(quantity) + 3 * STDDEV(quantity)
    FROM ecommerce
);

-- Advanced Queries
-- 1. Monthly revenue trend using a CTE to summarize total sales per month
WITH MonthlyRevenue AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS YearMonth,
        ROUND(SUM(price * quantity),2) AS TotalRevenue
    FROM ecommerce
    GROUP BY YearMonth
)
SELECT * FROM MonthlyRevenue
ORDER BY YearMonth;


-- 2. Rank top 10 products by revenue using RANK() window function
SELECT
    product,
    ROUND(SUM(price * quantity),2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(price * quantity) DESC) AS revenue_rank
FROM ecommerce
GROUP BY product
ORDER BY revenue_rank
LIMIT 10;


-- 3. Customer cohort analysis: find each customer’s first order month, monthly spend, and cumulative spend over time
WITH CustomerFirstOrder AS (
    SELECT 
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS first_order_month
    FROM ecommerce
    GROUP BY customer_id
),
CustomerSpend AS (
    SELECT 
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        SUM(price * quantity) AS monthly_spend
    FROM ecommerce
    GROUP BY customer_id, order_month
)
SELECT 
    cs.customer_id,
    cfo.first_order_month,
    cs.order_month,
    cs.monthly_spend,
    SUM(cs.monthly_spend) OVER (PARTITION BY cs.customer_id ORDER BY cs.order_month) AS cumulative_spend
FROM CustomerSpend cs
JOIN CustomerFirstOrder cfo ON cs.customer_id = cfo.customer_id
ORDER BY cs.customer_id, cs.order_month;


-- 4. Show product-level revenue alongside average revenue per category using subqueries and join
SELECT
    p.product,
    p.category,
    ROUND(p.total_revenue,2),
    ROUND(c.avg_category_revenue,2)
FROM
    (SELECT product, category, SUM(price * quantity) AS total_revenue
     FROM ecommerce
     GROUP BY product, category) p
JOIN
    (SELECT category, AVG(price * quantity) AS avg_category_revenue
     FROM ecommerce
     GROUP BY category) c
ON p.category = c.category
ORDER BY p.total_revenue DESC;
