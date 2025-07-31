-- 日付を1日進める修正

UPDATE user_nfts 
SET purchase_date = purchase_date + INTERVAL '1 day',
    operation_start_date = operation_start_date + INTERVAL '1 day'
WHERE is_active = true;

SELECT 
    u.name,
    u.user_id,
    DATE(un.purchase_date) as purchase_date,
    DATE(un.operation_start_date) as operation_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true;