# DataAnalytics-assessment
									ASSESSMENT_Q1

SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ',  u.last_name) AS name,
    s.savings_count,
    p.investment_count,
    (s.total_savings + p.total_investment) AS total_deposits
FROM 
    users_customuser u
INNER JOIN (
    SELECT 
        owner_id,
        COUNT(distinct(id)) AS savings_count,
        COALESCE(SUM(amount), 0) AS total_savings
    FROM 
        savings_savingsaccount s
    WHERE 
        amount > 0
    GROUP BY 
        owner_id
) s ON u.id = s.owner_id
INNER JOIN (
    SELECT 
        owner_id,
        COUNT(distinct(id)) AS investment_count,
        COALESCE(SUM(amount), 0) AS total_investment
    FROM 
        plans_plan
    WHERE 
        amount > 0
    GROUP BY 
        owner_id
) p ON u.id = p.owner_id
ORDER BY 
    (s.total_savings + p.total_investment) DESC
LIMIT  1000; 

							EXPLANATION
To get a list of users who have both savings and investment accounts, along with their total deposits, sorted by the highest total.

	1.	Main Table (users_customuser u):
Start with the user info (ID, first name, last name).
	2.	Join on Savings:
Subquery s calculates:
	•	How many savings accounts each user has (savings_count),
	•	The total saved amount (total_savings),
for users with savings > 0.
	3.	Join on Investments:
Subquery p calculates:
	•	How many investments each user has (investment_count),
	•	The total investment amount (total_investment),
for users with investments > 0.
	4.	Combine & Calculate:
	•	Join both subqueries on user ID.
	•	Add savings + investments to get total_deposits.
	5.	Sort & Limit:
	•	Sort users by total_deposits in descending order.
	•	Show only the top 1000 users.

							ASSESSMENT_Q2

WITH transactions_per_user_month AS (
    SELECT 
        id,
        DATE_FORMAT(transaction_date, '%Y-%m-01') AS month,
        COUNT(*) AS txn_count
    FROM 
        savings_savingsaccount
    GROUP BY 
        id, 
        DATE_FORMAT(transaction_date, '%Y-%m-01')
),
average_txn_per_user AS (
    SELECT 
        id,
        AVG(txn_count) AS avg_txn_per_month
    FROM 
        transactions_per_user_month
    GROUP BY 
        id
)
SELECT 
    CASE 
        WHEN avg_txn_per_month >= 10 THEN 'High Frequency'
        WHEN avg_txn_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
    END AS frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_txn_per_month), 1) AS avg_transactions_per_month
FROM 
    average_txn_per_user
GROUP BY 
    frequency_category
ORDER BY 
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
		ELSE 3
        END;
							EXPLANATION
1. transactions_per_user_month (CTE 1):
	•	For each user (id) and month, count how many transactions they made.
	•	DATE_FORMAT(transaction_date, '%Y-%m-01') groups by month (e.g., “2025-05-01”).

	Result: User, Month, and number of transactions that month.
2. average_txn_per_user (CTE 2):
	•	Take the output from the first CTE.
	•	For each user, calculate the average number of transactions per month.

	Result: User and their average monthly transaction count.
3. Final SELECT:
	•	Categorize users into:
	•	High Frequency: Avg >= 10 txns/month
	•	Medium Frequency: 3–9 txns/month
	•	Low Frequency: < 3 txns/month
	•	Count how many users fall into each category.
	•	Also calculate the average of their average transactions per month, rounded to 1 decimal.
Sorting:

The results are sorted with High → Medium → Low frequency using a custom ORDER BY clause.

									ASSESSMENT Q3
WITH active_accounts AS (
    -- Savings accounts
    SELECT 
        id AS plan_id,
        owner_id,
        'Savings' AS type
    FROM 
        savings_savingsaccount
    WHERE 
        transaction_status = 'active' -- Adjust based on actual status column
    UNION ALL
    -- Investment plans
    SELECT 
        id AS plan_id,
        owner_id,
        'Investment' AS type
    FROM 
        plans_plan
    WHERE 
        plan_type_id = '1' -- Adjust based on actual status column
),
last_inflow AS (
    SELECT 
        COALESCE(t.id, t.plan_id) AS account_id,
        MAX(t.transaction_date) AS last_transaction_date
    FROM 
        withdrawals_withdrawal t
    WHERE 
        t.amount > 0 -- Inflow transactions
        AND t.transaction_date <= '2025-05-18'
    GROUP BY 
        COALESCE(t.id, t.plan_id)
)
SELECT 
    a.plan_id,
    a.owner_id,
    a.type,
    li.last_transaction_date,
    DATEDIFF('2025-05-18', li.last_transaction_date) AS inactivity_days
FROM 
    active_accounts a
LEFT JOIN 
    last_inflow li ON a.plan_id = li.account_id
WHERE 
    li.last_transaction_date IS NULL 
    OR li.last_transaction_date < DATE_SUB('2025-05-18', INTERVAL 365 DAY)
ORDER BY 
    DATEDIFF("2025-05-18", 
    li.last_transaction_date)
DESC;

								EXPLANATION
1. active_accounts CTE:
	•	Combines active savings accounts and specific investment plans into one list.
	•	Each entry includes:
	•	plan_id (the account or plan ID),
	•	owner_id (the user who owns it),
	•	type (‘Savings’ or ‘Investment’).

	Uses filters:
		•	transaction_status = 'active' for savings,
	•	plan_type_id = '1' for investment (can be adjusted as needed).
2. last_inflow CTE:
	•	Finds the most recent inflow transaction (amount > 0) for each account (savings or investment) before or on '2025-05-18'.
	•	Uses MAX(transaction_date) to get the last date an inflow occurred.
	•	COALESCE(t.id, t.plan_id) ensures both savings and investments are covered depending on where the ID is stored.
3. Final SELECT:
	•	Joins the active_accounts with their last_inflow date.
	•	Calculates the number of days since the last inflow using DATEDIFF.

	Filters to find “inactive” accounts:
		•	No inflow ever (last_transaction_date IS NULL), or
	•	Last inflow was more than 365 days ago.
4. Ordering:
	•	Results are sorted by how long it’s been since the last inflow (longest inactivity first).


							ASSESSMENT Q4
WITH customer_transactions AS (
    SELECT 
        u.id AS customer_id,
		CONCAT(u.first_name, ' ',  u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, u.date_joined, '2025-05-18') AS tenure_months,
        COUNT(t.id) AS total_transactions,
        AVG(0.001 * t.amount) AS avg_profit_per_transaction
    FROM 
        users_customuser u
    LEFT JOIN 
        savings_savingsaccount s ON u.id = s.owner_id
    LEFT JOIN 
        plans_plan t ON s.id = t.id
    GROUP BY 
        u.id, u.name
)
SELECT 
    customer_id,
    name,
    tenure_months,
    total_transactions,
    ROUND(
        CASE 
            WHEN tenure_months = 0 THEN 0
            ELSE (total_transactions / tenure_months) * 12 * avg_profit_per_transaction
        END, 2
    ) AS estimated_clv
FROM 
    customer_transactions
ORDER BY 5 DESC; -- 5th column is estimated_clv

EXPLNATION
1. customer_transactions CTE:
	•	For each user (u), it calculates:
	•	tenure_months: How many months they’ve been a customer, using the difference between their join date and '2025-05-18'.
	•	total_transactions: The count of transactions (joining with plans_plan t).
	•	avg_profit_per_transaction: Assumes 0.1% (0.001) profit on each transaction amount.

	Note: The join savings_savingsaccount s ON u.id = s.owner_id and plans_plan t ON s.id = t.id seems off — see notes below.

2. Final SELECT:

For each user, it outputs:
	•	ID, name, tenure, total transactions,
	•	And calculates estimated CLV using this formula:
	(total_transactions / tenure_months) * 12 * avg_profit_per_transaction
This gives an annualized estimate of profit per customer.

	•	If tenure_months = 0, CLV is set to 0 to avoid division by zero.
3. Ordering:

Sorts the users by highest estimated CLV (column 5) in descending order.


				CHALLENGES FACED
1.Join Issues
	•	Incorrect joins (e.g., joining on the wrong columns) can return inaccurate or incomplete data.
	•	Missing relationships might result in empty or duplicate rows.

2. Null and Missing Values
	•	Columns like last_transaction_date or amount might be NULL, leading to errors or unexpected results (e.g., AVG, SUM, or DATEDIFF).

3. Performance Problems
	•	Complex subqueries, large datasets, and multiple joins can slow down query execution.
	•	Lack of indexes on join or filter columns can make queries inefficient.

4. Logic Errors
	•	Misinterpreting business rules (e.g., how to define an “active” account or “valid” transaction).
	•	Incorrect calculations (e.g., CLV formula errors or dividing by zero).

5. Time-based Calculations
	•	Calculating tenure or age using DATEDIFF or TIMESTAMPDIFF can be tricky with timezone or format mismatches.
	•	Hardcoded dates (e.g., '2025-05-18') can lead to outdated results over time.
