-- ランク計算のデバッグ

-- 1. 現在のuser_rank_historyの状況確認
SELECT 
    'user_rank_history現在の状況' as check_type,
    COUNT(*) as total_records,
    SUM(CASE WHEN is_current = true THEN 1 ELSE 0 END) as current_records,
    SUM(CASE WHEN is_current = false THEN 1 ELSE 0 END) as old_records
FROM user_rank_history;

-- 2. usersテーブルの基本情報確認
SELECT 
    'users基本情報' as check_type,
    COUNT(*) as total_users,
    SUM(CASE WHEN is_admin = true THEN 1 ELSE 0 END) as admin_users,
    SUM(CASE WHEN is_admin = false THEN 1 ELSE 0 END) as regular_users
FROM users;

-- 3. user_nftsテーブルの状況確認
SELECT 
    'user_nfts状況' as check_type,
    COUNT(*) as total_nft_records,
    COUNT(DISTINCT user_id) as users_with_nfts,
    SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as active_nfts,
    SUM(current_investment) as total_investment
FROM user_nfts;

-- 4. 紹介関係の確認
SELECT 
    'referral関係' as check_type,
    COUNT(*) as total_users,
    SUM(CASE WHEN referrer_id IS NOT NULL THEN 1 ELSE 0 END) as users_with_referrer,
    COUNT(DISTINCT referrer_id) as unique_referrers
FROM users
WHERE is_admin = false;

-- 5. 簡単なテストクエリ - 基本情報取得
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.is_admin,
    COALESCE(SUM(un.current_investment), 0) as nft_value
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.is_admin = false
GROUP BY u.id, u.name, u.user_id, u.is_admin
LIMIT 5;
