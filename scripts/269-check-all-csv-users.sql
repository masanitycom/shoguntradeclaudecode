-- CSVの全ユーザーと現在のDBの状態を比較

-- 1. 現在のDBの全ユーザー状態
SELECT 
    '=== 現在のDB状態（全ユーザー） ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users;

-- 2. 紹介者なしのユーザー一覧
SELECT 
    '=== 紹介者なしのユーザー ===' as status,
    user_id,
    name,
    email,
    created_at
FROM users
WHERE referrer_id IS NULL
ORDER BY created_at;

-- 3. 最近修正されたユーザー（今日の修正分）
SELECT 
    '=== 今日修正されたユーザー ===' as status,
    u.user_id,
    u.name,
    u.email,
    COALESCE(r.user_id, 'なし') as current_referrer,
    COALESCE(r.name, 'なし') as current_referrer_name,
    u.updated_at
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.updated_at >= '2025-06-29T06:00:00Z'
ORDER BY u.updated_at DESC;

-- 4. 代理メールアドレスのユーザー統計
SELECT 
    '=== 代理メールユーザー統計 ===' as status,
    COUNT(*) as proxy_email_count,
    COUNT(referrer_id) as proxy_with_referrer,
    COUNT(*) - COUNT(referrer_id) as proxy_without_referrer
FROM users
WHERE email LIKE '%@shogun-trade.com';

-- 5. 代理メールユーザーの紹介者別統計（上位10位）
WITH proxy_referrer_stats AS (
    SELECT 
        r.user_id as referrer_user_id,
        r.name as referrer_name,
        COUNT(*) as proxy_referral_count
    FROM users u
    JOIN users r ON u.referrer_id = r.id
    WHERE u.email LIKE '%@shogun-trade.com'
    GROUP BY r.user_id, r.name
)
SELECT 
    '=== 代理メール紹介者ランキング ===' as status,
    referrer_user_id,
    referrer_name,
    proxy_referral_count
FROM proxy_referrer_stats
ORDER BY proxy_referral_count DESC
LIMIT 10;

-- 6. 問題のあるユーザー（循環参照など）
WITH RECURSIVE referral_chain AS (
    -- 開始点
    SELECT 
        user_id,
        name,
        referrer_id,
        ARRAY[user_id] as chain,
        1 as depth
    FROM users
    WHERE referrer_id IS NOT NULL
    
    UNION ALL
    
    -- 再帰部分
    SELECT 
        rc.user_id,
        rc.name,
        u.referrer_id,
        rc.chain || u.user_id,
        rc.depth + 1
    FROM referral_chain rc
    JOIN users u ON rc.referrer_id = u.id
    WHERE u.referrer_id IS NOT NULL 
    AND rc.depth < 10
    AND NOT (u.user_id = ANY(rc.chain))
)
SELECT 
    '=== 循環参照チェック ===' as status,
    user_id,
    name,
    chain,
    depth
FROM referral_chain
WHERE user_id = ANY(chain[2:])
LIMIT 5;

SELECT '📋 CSVファイルを分析して正しい紹介関係を確認します' as next_step;
