-- 運用開始日の簡単修正

UPDATE user_nfts 
SET operation_start_date = CASE 
    WHEN EXTRACT(DOW FROM purchase_date) = 0 THEN purchase_date + INTERVAL '1 day'
    WHEN EXTRACT(DOW FROM purchase_date) = 6 THEN purchase_date + INTERVAL '2 days'
    ELSE purchase_date + INTERVAL '1 day'
END
WHERE operation_start_date IS NULL
  AND is_active = true;

UPDATE user_nfts 
SET purchase_date = '2025-01-27 15:00:00+00'::timestamp with time zone,
    operation_start_date = '2025-01-28 15:00:00+00'::timestamp with time zone
WHERE user_id IN (
    SELECT id FROM users WHERE name IN ('サカイユカ2', 'サカイユカ3')
)
AND is_active = true;

SELECT 
    u.name,
    u.user_id,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD (Dy)') as purchase_formatted,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_formatted
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true;