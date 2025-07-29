-- 緊急修正: 今日削除してしまった紹介関係を復元
-- 対象: bighand1011, klmiklmi0204, Mira

-- 修正前の状態を記録
DROP TABLE IF EXISTS emergency_fix_backup;
CREATE TABLE emergency_fix_backup AS
SELECT 
    user_id,
    name,
    referrer_id,
    updated_at,
    'before_emergency_fix' as backup_type,
    NOW() as backup_created_at
FROM users 
WHERE user_id IN ('bighand1011', 'klmiklmi0204', 'Mira');

-- 1. bighand1011 → 紹介者: USER0a18 (タカクワマサシ)
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'bighand1011';

-- 2. klmiklmi0204 → 紹介者: yasui001 (ヤスイヒラタカ)
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yasui001'),
    updated_at = NOW()
WHERE user_id = 'klmiklmi0204';

-- 3. Mira → 紹介者: Mickey (ヨシオカヤスエ)
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Mickey'),
    updated_at = NOW()
WHERE user_id = 'Mira';

-- 修正後の状態を表示
SELECT 
    '=== 修正後の状態 ===' as status,
    u.user_id,
    u.name,
    r.user_id as new_referrer,
    r.name as new_referrer_name,
    u.updated_at
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('bighand1011', 'klmiklmi0204', 'Mira')
ORDER BY u.user_id;

-- 修正サマリー
SELECT 
    '=== 修正サマリー ===' as status,
    COUNT(*) as total_fixed_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users 
WHERE user_id IN ('bighand1011', 'klmiklmi0204', 'Mira');

-- システム健全性チェック
SELECT 
    '=== システム健全性チェック ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users;

-- 紹介者なしユーザーの確認
SELECT 
    '=== 紹介者なしユーザー確認 ===' as status,
    user_id,
    name,
    email,
    CASE 
        WHEN user_id = 'admin001' THEN '✅ 管理者（正常）'
        WHEN user_id = 'USER0a18' THEN '✅ ルートユーザー（正常）'
        ELSE '❌ 紹介者が必要'
    END as expected_status
FROM users 
WHERE referrer_id IS NULL
ORDER BY user_id;
