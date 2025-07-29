-- 循環参照チェック機能の修正
-- 配列型の問題を解決

-- 1. 循環参照チェック関数の作成
CREATE OR REPLACE FUNCTION check_circular_references()
RETURNS TABLE(
    user_id VARCHAR(50),
    name VARCHAR(100),
    chain_length INTEGER,
    referral_chain TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE referral_chain AS (
        -- 非再帰部分: 開始点
        SELECT 
            u.user_id,
            u.name,
            u.referrer_id,
            ARRAY[u.user_id]::VARCHAR(50)[] as chain,
            1 as depth
        FROM users u
        WHERE u.referrer_id IS NOT NULL
        
        UNION ALL
        
        -- 再帰部分: 紹介者を辿る
        SELECT 
            rc.user_id,
            rc.name,
            u.referrer_id,
            rc.chain || u.user_id,
            rc.depth + 1
        FROM referral_chain rc
        JOIN users u ON u.id = rc.referrer_id
        WHERE u.referrer_id IS NOT NULL 
        AND rc.depth < 10  -- 無限ループ防止
        AND NOT (u.user_id = ANY(rc.chain))  -- 循環検出
    ),
    circular_refs AS (
        SELECT 
            rc.user_id,
            rc.name,
            rc.depth as chain_length,
            array_to_string(rc.chain, ' -> ') as referral_chain
        FROM referral_chain rc
        JOIN users u ON u.id = rc.referrer_id
        WHERE u.user_id = ANY(rc.chain)  -- 循環が発生している
    )
    SELECT 
        cr.user_id,
        cr.name,
        cr.chain_length,
        cr.referral_chain
    FROM circular_refs cr
    ORDER BY cr.chain_length DESC;
END;
$$ LANGUAGE plpgsql;

-- 2. 循環参照チェックの実行
SELECT '=== 循環参照チェック ===' as status;

SELECT 
    user_id,
    name,
    chain_length,
    referral_chain
FROM check_circular_references();

-- 3. 紹介者なしユーザーの詳細確認
SELECT '=== 問題のあるユーザー詳細 ===' as status;

SELECT 
    user_id,
    name,
    email,
    CASE 
        WHEN user_id = 'admin001' THEN '管理者（正常）'
        WHEN user_id = 'USER0a18' THEN 'ルートユーザー（正常）'
        ELSE '紹介者が必要'
    END as expected_status,
    created_at,
    updated_at
FROM users 
WHERE referrer_id IS NULL
ORDER BY created_at;

-- 4. 今日修正されたユーザーの確認
SELECT '=== 今日修正されたユーザーの紹介関係 ===' as status;

SELECT 
    u.user_id,
    u.name,
    u.email,
    COALESCE(r.user_id, 'なし') as current_referrer,
    COALESCE(r.name, 'なし') as current_referrer_name,
    u.updated_at
FROM users u
LEFT JOIN users r ON r.id = u.referrer_id
WHERE u.updated_at >= '2025-06-29T06:00:00Z'
ORDER BY u.updated_at DESC;

-- 5. システム健全性の確認
SELECT '=== システム健全性統計 ===' as status;

SELECT 
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer,
    (SELECT COUNT(*) FROM users WHERE email LIKE '%@shogun-trade.com') as proxy_email_users
FROM users;

SELECT '📋 次はCSVファイルの分析を実行してください: scripts/270-analyze-all-users.js' as next_step;
