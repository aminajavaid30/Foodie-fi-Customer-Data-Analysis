# Case Study 1 - Foodie-Fi

# Explore the tables
# ------------------
# TABLE: plans 
DESCRIBE plans;
SELECT * FROM plans;

# TABLE: subscriptions
DESCRIBE subscriptions;
SELECT * FROM subscriptions;

# Define the Primary Key in 'plans' table
ALTER TABLE plans
ADD PRIMARY KEY(plan_id);  

# Define the Foreign Key in 'subscriptions' table
ALTER TABLE subscriptions
ADD FOREIGN KEY(plan_id) REFERENCES plans(plan_id);

# Questions
#----------
# 1. How many customers has Foodie-Fi ever had? 
SELECT COUNT(DISTINCT customer_id) AS Number_of_customers
FROM subscriptions;

# 2. What is the monthly distribution of trial plan start_date values for our dataset? Use the start of the month as the group by value
WITH trial_plan AS (
	SELECT p.plan_id, p.plan_name, s.start_date, MONTH(s.start_date) AS month, MONTHNAME(s.start_date) AS month_name 
    FROM plans AS p
	INNER JOIN subscriptions AS s
	ON p.plan_id = s.plan_id
	WHERE p.plan_name = 'trial'
)
SELECT `month`, month_name, COUNT(*) AS Number_of_trial_plans
FROM trial_plan
GROUP BY `month`, month_name
ORDER BY `month`;

# 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name, COUNT(*) AS Number_of_plans_after_2020
FROM plans AS p
INNER JOIN subscriptions AS s
ON p.plan_id = s.plan_id
WHERE YEAR(s.start_date) > '2020'
GROUP BY p.plan_name;

# 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH Churned_customers AS ( 
	SELECT COUNT(*) AS churned
	FROM plans AS p
	INNER JOIN subscriptions AS s
	ON p.plan_id = s.plan_id
	WHERE p.plan_name = 'churn'
)
SELECT churned AS 'Churned customers', ROUND(churned/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) * 100, 1) AS 'Percentage of churned customers'
FROM Churned_customers;

# 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH paid_customers AS (
	SELECT DISTINCT customer_id AS customer_id
    FROM plans AS p
    INNER JOIN subscriptions AS s
    ON p.plan_id = s.plan_id
    WHERE p.plan_name = 'basic monthly' OR p.plan_name = 'pro monthly' OR p.plan_name = 'pro annual' 
)
SELECT COUNT(DISTINCT customer_id) AS Churned_after_free_trial, 
	ROUND(COUNT(DISTINCT customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)*100, 0) AS Percentage_churned_after_free_trial 
FROM subscriptions AS s 
WHERE s.customer_id NOT IN (SELECT customer_id FROM paid_customers);

# 6. What is the number and percentage of customer plans after their initial free trial?
WITH customer_plans AS (
	SELECT p.plan_id, p.plan_name, COUNT(*) AS Number_of_plans
	FROM plans AS p
	RIGHT JOIN subscriptions s
	ON p.plan_id = s.plan_id
	GROUP BY p.plan_id
)
SELECT *, ROUND(Number_of_plans/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)*100, 1) AS Percentage_of_plans
FROM customer_plans;

# 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH customer_plans_lastday2020 AS (
	SELECT p.plan_id, p.plan_name, s.start_date, COUNT(*) AS Number_of_customers
	FROM plans AS p
	RIGHT JOIN subscriptions s
	ON p.plan_id = s.plan_id
    WHERE s.start_date = '2020-12-31'
	GROUP BY p.plan_id
)
SELECT *, ROUND(Number_of_customers/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)*100, 1) AS Percentage_of_plans
FROM customer_plans_lastday2020;

# 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS Annual_customers_2020
FROM subscriptions
WHERE plan_id = 3 AND YEAR(start_date) = '2020';

# 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT ROUND(AVG(num_days), 2) AS Average_days_to_annual_plan
FROM(
	WITH Free_trial_customers AS (
		SELECT customer_id, start_date AS free_trial_start_date 
		FROM subscriptions 
		WHERE plan_id = 0
	)
	SELECT s.customer_id, free_trial_start_date, s.start_date AS Annual_start_date, DATEDIFF(s.start_date, free_trial_start_date) AS num_days 
	FROM subscriptions AS s
	INNER JOIN Free_trial_customers AS f
	ON s.customer_id = f.customer_id 
	WHERE s.plan_id = 3
) AS Annual_Plan; 

# 10. Can you further breakdown this average value into 30 day periods? (i.e. 0-30 days, 31-60 days etc)
SELECT time_span, ROUND(AVG(num_days), 2) AS Average_num_days
FROM(
	SELECT *,
		CASE
		WHEN num_days >= 0 AND num_days <= 30 THEN '0-30 days'
		WHEN num_days >= 31 AND num_days <= 60 THEN '31-60 days'
		WHEN num_days >= 61 AND num_days <= 90 THEN '61-90 days'
		WHEN num_days >= 91 AND num_days <= 120 THEN '91-120 days'
		WHEN num_days >= 121 AND num_days <= 150 THEN '121-150 days'
		WHEN num_days >= 151 AND num_days <= 180 THEN '151-180 days'
		WHEN num_days >= 181 AND num_days <= 210 THEN '181-210 days'
		WHEN num_days >= 211 AND num_days <= 240 THEN '211-240 days'
		WHEN num_days >= 241 AND num_days <= 270 THEN '241-270 days'
		WHEN num_days >= 271 AND num_days <= 300 THEN '271-300 days'
		WHEN num_days >= 301 AND num_days <= 330 THEN '301-330 days'
		WHEN num_days >= 331 AND num_days <= 360 THEN '331-360 days'
		END AS time_span
	FROM (
		WITH Free_trial_customers AS (
			SELECT customer_id, start_date AS free_trial_start_date 
			FROM subscriptions 
			WHERE plan_id = 0
		)
		SELECT s.customer_id, free_trial_start_date, s.start_date AS Annual_start_date, DATEDIFF(s.start_date, free_trial_start_date) AS num_days
		FROM subscriptions AS s
		INNER JOIN Free_trial_customers AS f
		ON s.customer_id = f.customer_id 
		WHERE s.plan_id = 3
	) AS Annual_Plan
) AS a
GROUP BY time_span
ORDER BY Average_num_days;

# 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH Pro_monthly_customers_2020 AS (
	SELECT * 
	FROM subscriptions
	WHERE plan_id = 2 AND YEAR(start_date) = '2020'
)
SELECT COUNT(s.customer_id) AS pro_to_basic_monthly_customers
FROM subscriptions s 
INNER JOIN Pro_monthly_customers_2020
ON s.customer_id = Pro_monthly_customers_2020.customer_id
WHERE s.plan_id = 1 
	AND s.customer_id IN (SELECT customer_id FROM Pro_monthly_customers_2020)
    AND s.start_date > Pro_monthly_customers_2020.start_date
    AND YEAR(s.start_date) = '2020';
