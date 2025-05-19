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