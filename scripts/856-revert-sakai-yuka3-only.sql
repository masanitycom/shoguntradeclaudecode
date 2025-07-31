-- サカイユカ3の正規アカウント(ys0888)のみ元に戻す

UPDATE user_nfts 
SET purchase_date = '2025-02-03 15:00:00+00'::timestamp with time zone,
    operation_start_date = '2025-02-11 15:00:00+00'::timestamp with time zone
WHERE user_id = (
    SELECT id FROM users WHERE name = 'サカイユカ3' AND user_id = 'ys0888'
)
AND is_active = true;

SELECT 
    u.name,
    u.user_id,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD (Dy)') as purchase_date,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name = 'サカイユカ3'
  AND u.user_id = 'ys0888'
  AND un.is_active = true;