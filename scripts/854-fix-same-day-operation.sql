-- 購入日と運用開始日を同じ日に修正

UPDATE user_nfts 
SET purchase_date = '2025-02-03 15:00:00+00'::timestamp with time zone,
    operation_start_date = '2025-02-03 15:00:00+00'::timestamp with time zone
WHERE user_id IN (
    SELECT id FROM users WHERE name IN ('サカイユカ2', 'サカイユカ3')
)
AND is_active = true;

SELECT 
    u.name,
    u.user_id,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD') as purchase_date,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD') as operation_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true;