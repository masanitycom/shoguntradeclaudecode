-- サカイユカ2とサカイユカ3の個別の購入日確認

SELECT 
    u.name,
    u.user_id,
    u.email,
    un.purchase_date,
    un.operation_start_date,
    un.created_at,
    '元の購入日確認' as note
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE (u.name = 'サカイユカ2' OR u.name = 'サカイユカ3')
  AND un.is_active = true
ORDER BY u.name, u.user_id, un.created_at;