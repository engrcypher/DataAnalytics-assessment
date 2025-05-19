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