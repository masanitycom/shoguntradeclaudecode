-- ダッシュボードと管理画面のデータ比較
-- ユーザーダッシュボードで使用されるクエリの再現
SELECT 
    'ダッシュボード用クエリ結果' as query_type,
    un.id,
    un.nft_id,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    un.purchase_date,
    un.operation_start_date,
    n.name as nft_name,
    n.image_url,
    n.daily_rate_limit,
    n.price,
    u.name as user_name,
    u.user_id
FROM user_nfts un
INNER JOIN nfts n ON un.nft_id = n.id
INNER JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
ORDER BY u.created_at DESC
LIMIT 5;

-- 管理画面用クエリの再現  
SELECT 
    'ダッシュボード統計関数結果' as query_type,
    u.name as user_name,
    u.user_id,
    u.total_investment,
    u.total_earned
FROM users u
ORDER BY u.created_at DESC
LIMIT 5;