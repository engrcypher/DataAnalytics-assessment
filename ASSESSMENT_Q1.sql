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