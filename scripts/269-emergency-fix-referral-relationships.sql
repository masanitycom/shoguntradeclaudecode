-- 緊急修正: 間違って削除した紹介関係を復元

-- 修正前の状態を確認
SELECT 
    '=== 現在の間違った状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as current_referrer,
    COALESCE(r.name, 'なし') as current_referrer_name
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('bighand1011', 'klmiklmi0204', 'Mira')
ORDER BY u.user_id;

-- 緊急修正開始
BEGIN;

-- 1. bighand1011 の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'bighand1011';

-- 2. klmiklmi0204 の紹介者を yasui001 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yasui001'),
    updated_at = NOW()
WHERE user_id = 'klmiklmi0204';

-- 3. Mira の紹介者を Mickey に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Mickey'),
    updated_at = NOW()
WHERE user_id = 'Mira';

COMMIT;

-- 修正後の状態を確認
SELECT 
    '=== 修正後の正しい状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as new_referrer,
    COALESCE(r.name, 'なし') as new_referrer_name,
    u.updated_at
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204')
ORDER BY u.user_id;

-- 最終確認: 正しい紹介関係
WITH correct_referrals AS (
    SELECT 'OHTAKIYO' as user_id, 'klmiklmi0204' as expected_referrer
    UNION ALL
    SELECT '1125Ritsuko', 'USER0a18'
    UNION ALL
    SELECT 'USER0a18', NULL  -- ルートユーザー
    UNION ALL
    SELECT 'bighand1011', 'USER0a18'
    UNION ALL
    SELECT 'Mira', 'Mickey'
    UNION ALL
    SELECT 'klmiklmi0204', 'yasui001'
),
current_state AS (
    SELECT 
        u.user_id,
        r.user_id as actual_referrer
    FROM users u
    LEFT JOIN users r ON u.referrer_id = r.id
    WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204')
)
SELECT 
    '=== 最終確認: 正しい紹介関係 ===' as status,
    c.user_id,
    COALESCE(c.expected_referrer, 'なし') as expected,
    COALESCE(s.actual_referrer, 'なし') as actual,
    CASE 
        WHEN COALESCE(c.expected_referrer, '') = COALESCE(s.actual_referrer, '') THEN '✅ 正しい'
        ELSE '❌ まだ間違い'
    END as match_status
FROM correct_referrals c
LEFT JOIN current_state s ON c.user_id = s.user_id
ORDER BY c.user_id;

-- 紹介者が存在するかチェック
SELECT 
    '=== 紹介者存在確認 ===' as status,
    'yasui001' as referrer_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM users WHERE user_id = 'yasui001') THEN '✅ 存在'
        ELSE '❌ 存在しない'
    END as yasui001_exists
UNION ALL
SELECT 
    '=== 紹介者存在確認 ===' as status,
    'Mickey' as referrer_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM users WHERE user_id = 'Mickey') THEN '✅ 存在'
        ELSE '❌ 存在しない'
    END as mickey_exists;

SELECT '🚨 緊急修正完了！正しい紹介関係に復元しました' as completion_message;
