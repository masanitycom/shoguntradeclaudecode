-- 正しいデータと現在のDBの比較（修正版）

-- 1. 重要ユーザーの現在の状態確認
SELECT 
    'Current Important Users Status' as analysis_type,
    u.user_id,
    u.name,
    u.email as current_email,
    ref.user_id as current_referrer_id,
    ref.name as current_referrer_name,
    u.created_at,
    u.updated_at
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204')
ORDER BY u.user_id;

-- 2. CSVから判明した正しい紹介関係（手動入力）
WITH correct_referrals AS (
    SELECT * FROM (VALUES
        ('OHTAKIYO', 'オオタキヨジ', 'klmiklmi0204'),
        ('1125Ritsuko', 'ミズカミヤスナリ', 'USER0a18'),
        ('USER0a18', 'タカクワマサシ', NULL),
        ('bighand1011', 'オオテヒロユキ', NULL),
        ('Mira', 'オオサワレイコ', NULL),
        ('klmiklmi0204', 'アラホリキミコ', NULL)
    ) AS t(user_id, name, correct_referrer_id)
)
SELECT 
    'Referral Comparison' as analysis_type,
    cr.user_id,
    cr.name,
    cr.correct_referrer_id as should_be_referrer,
    current_ref.user_id as current_referrer_id,
    CASE 
        WHEN cr.correct_referrer_id IS NULL AND u.referrer_id IS NULL THEN 'CORRECT ✓'
        WHEN cr.correct_referrer_id IS NOT NULL AND current_ref.user_id = cr.correct_referrer_id THEN 'CORRECT ✓'
        WHEN cr.correct_referrer_id IS NULL AND u.referrer_id IS NOT NULL THEN 'SHOULD_BE_NULL ❌'
        WHEN cr.correct_referrer_id IS NOT NULL AND u.referrer_id IS NULL THEN 'MISSING_REFERRER ❌'
        WHEN cr.correct_referrer_id IS NOT NULL AND current_ref.user_id != cr.correct_referrer_id THEN 'WRONG_REFERRER ❌'
        ELSE 'UNKNOWN_STATUS ❓'
    END as status,
    u.email as current_email
FROM correct_referrals cr
LEFT JOIN users u ON cr.user_id = u.user_id
LEFT JOIN users current_ref ON u.referrer_id = current_ref.id
ORDER BY cr.user_id;

-- 3. 修正が必要なユーザーの特定
WITH correct_referrals AS (
    SELECT * FROM (VALUES
        ('OHTAKIYO', 'klmiklmi0204'),
        ('1125Ritsuko', 'USER0a18'),
        ('USER0a18', NULL),
        ('bighand1011', NULL),
        ('Mira', NULL),
        ('klmiklmi0204', NULL)
    ) AS t(user_id, correct_referrer_id)
)
SELECT 
    'Users Needing Fix' as analysis_type,
    cr.user_id,
    u.name,
    cr.correct_referrer_id as should_be,
    current_ref.user_id as currently_is,
    CASE 
        WHEN cr.correct_referrer_id IS NULL THEN 'SET_TO_NULL'
        ELSE 'UPDATE_REFERRER'
    END as action_needed,
    CASE 
        WHEN cr.correct_referrer_id IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM users WHERE user_id = cr.correct_referrer_id
        ) THEN 'REFERRER_NOT_EXISTS ⚠️'
        WHEN cr.correct_referrer_id IS NULL THEN 'SET_TO_NULL ✓'
        ELSE 'REFERRER_EXISTS ✓'
    END as referrer_status
FROM correct_referrals cr
LEFT JOIN users u ON cr.user_id = u.user_id
LEFT JOIN users current_ref ON u.referrer_id = current_ref.id
WHERE (cr.correct_referrer_id IS NULL AND u.referrer_id IS NOT NULL)
   OR (cr.correct_referrer_id IS NOT NULL AND (u.referrer_id IS NULL OR current_ref.user_id != cr.correct_referrer_id))
ORDER BY cr.user_id;

-- 4. 紹介者として存在確認（修正版）
WITH referrers_to_check AS (
    SELECT unnest(ARRAY['klmiklmi0204', 'USER0a18']) as referrer_id
)
SELECT 
    'Referrer Existence Check' as analysis_type,
    rtc.referrer_id,
    CASE 
        WHEN EXISTS (SELECT 1 FROM users WHERE user_id = rtc.referrer_id) THEN 'EXISTS ✓'
        ELSE 'MISSING ❌'
    END as status,
    (SELECT name FROM users WHERE user_id = rtc.referrer_id) as referrer_name
FROM referrers_to_check rtc
ORDER BY rtc.referrer_id;

-- 5. 代理メールアドレス使用者の統計
SELECT 
    'Proxy Email Statistics' as analysis_type,
    COUNT(*) as total_proxy_users,
    COUNT(DISTINCT ref.user_id) as unique_referrers,
    string_agg(DISTINCT ref.user_id, ', ' ORDER BY ref.user_id) as main_referrers
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.email LIKE '%@shogun-trade.com'
  AND u.is_admin = false;

-- 6. 1125Ritsukoが紹介したユーザー数
SELECT 
    '1125Ritsuko Referrals' as analysis_type,
    COUNT(*) as total_referrals,
    COUNT(CASE WHEN u.email LIKE '%@shogun-trade.com' THEN 1 END) as proxy_email_referrals,
    COUNT(CASE WHEN u.email NOT LIKE '%@shogun-trade.com' THEN 1 END) as real_email_referrals
FROM users u
WHERE u.referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko')
  AND u.is_admin = false;

-- 7. システム健全性の確認
SELECT 
    'System Health Check' as analysis_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    ROUND(COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as referrer_percentage,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_references,
    COUNT(CASE WHEN referrer_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM users ref WHERE ref.id = users.referrer_id
    ) THEN 1 END) as invalid_referrers,
    COUNT(CASE WHEN email LIKE '%@shogun-trade.com' THEN 1 END) as proxy_email_users
FROM users 
WHERE is_admin = false;

-- 8. 循環参照の詳細確認
WITH RECURSIVE referral_chain AS (
    -- 基点となるユーザー
    SELECT 
        u.id,
        u.user_id,
        u.name,
        u.referrer_id,
        0 as depth,
        ARRAY[u.user_id] as chain
    FROM users u
    WHERE u.user_id IN ('1125Ritsuko', 'bighand1011')
    
    UNION ALL
    
    -- 再帰的に紹介者を辿る
    SELECT 
        ref.id,
        ref.user_id,
        ref.name,
        ref.referrer_id,
        rc.depth + 1,
        rc.chain || ref.user_id
    FROM referral_chain rc
    JOIN users ref ON rc.referrer_id = ref.id
    WHERE rc.depth < 10
      AND NOT (ref.user_id = ANY(rc.chain)) -- 循環防止
)
SELECT 
    'Circular Reference Check' as analysis_type,
    user_id,
    name,
    depth,
    array_to_string(chain, ' -> ') as referral_chain
FROM referral_chain
WHERE depth > 0
ORDER BY user_id, depth;
