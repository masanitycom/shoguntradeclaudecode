-- 管理画面で使用されるデータの確認
SELECT 
    u.name as user_name,
    u.user_id,
    un.is_active,
    un.purchase_date,
    un.operation_start_date,
    n.name as nft_name,
    CASE 
        WHEN un.purchase_date IS NULL THEN 'purchase_date が NULL'
        WHEN un.operation_start_date IS NULL THEN 'operation_start_date が NULL'
        WHEN NOT un.is_active THEN 'NFT が非アクティブ'
        ELSE 'データ正常'
    END as status
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN nfts n ON un.nft_id = n.id
ORDER BY u.created_at DESC
LIMIT 20;