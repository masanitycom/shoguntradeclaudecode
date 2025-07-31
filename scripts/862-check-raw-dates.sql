-- 生の日付データ確認

SELECT 
    u.name,
    u.user_id,
    un.purchase_date,
    un.operation_start_date,
    DATE(un.purchase_date) as purchase_date_only,
    DATE(un.operation_start_date) as operation_date_only
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true
LIMIT 5;