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