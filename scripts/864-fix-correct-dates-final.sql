-- 正しい日付に修正（購入2025/2/3月曜日、運用開始2025/2/17月曜日）

UPDATE user_nfts 
SET purchase_date = '2025-02-03 15:00:00+00'::timestamp with time zone,
    operation_start_date = '2025-02-17 15:00:00+00'::timestamp with time zone
WHERE is_active = true;

SELECT 
    u.name,
    u.user_id,
    DATE(un.purchase_date) as purchase_date,
    DATE(un.operation_start_date) as operation_date,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD (Dy)') as purchase_formatted,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_formatted
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true;