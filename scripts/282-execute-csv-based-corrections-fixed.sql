-- CSVデータに基づく正確な紹介関係修正
-- 実行日時: 2025-06-29
-- 対象: 7人の重要ユーザー

BEGIN;

-- 修正前の状態をバックアップ
DROP TABLE IF EXISTS csv_correction_backup;
CREATE TABLE csv_correction_backup AS
SELECT 
    user_id,
    name,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as current_referrer_user_id,
    updated_at,
    NOW() as backup_created_at
FROM users u
WHERE user_id IN ('klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 'bighand1011', 'Mira', 'OHTAKIYO');

-- 修正前の状態を表示
SELECT 
    '=== 修正前の状態 ===' as status,
    user_id,
    name,
    current_referrer_user_id as current_referrer,
    updated_at
FROM csv_correction_backup
ORDER BY user_id;

-- klmiklmi0204 (アラホリキミコ) の紹介者を yasui001 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yasui001'),
    updated_at = NOW()
WHERE user_id = 'klmiklmi0204'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yasui001');

-- kazukazu2 (ヤナギダカツミ2) の紹介者を kazukazu1 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'kazukazu1'),
    updated_at = NOW()
WHERE user_id = 'kazukazu2'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'kazukazu1');

-- yatchan003 (ヤジマモトミ3) の紹介者を yatchan に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan'),
    updated_at = NOW()
WHERE user_id = 'yatchan003'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yatchan');

-- yatchan002 (ヤジマモトミ2) の紹介者を yatchan に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan'),
    updated_at = NOW()
WHERE user_id = 'yatchan002'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yatchan');

-- bighand1011 (オオテヒロユキ) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'bighand1011'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- Mira (オオサワレイコ) の紹介者を Mickey に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Mickey'),
    updated_at = NOW()
WHERE user_id = 'Mira'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Mickey');

-- OHTAKIYO (オオタキヨジ) の紹介者を klmiklmi0204 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'klmiklmi0204'),
    updated_at = NOW()
WHERE user_id = 'OHTAKIYO'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'klmiklmi0204');

-- 修正後の状態を表示
SELECT 
    '=== 修正後の状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE((SELECT user_id FROM users WHERE id = u.referrer_id), 'なし') as new_referrer,
    COALESCE((SELECT name FROM users WHERE id = u.referrer_id), 'なし') as new_referrer_name,
    u.updated_at
FROM users u
WHERE u.user_id IN ('klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 'bighand1011', 'Mira', 'OHTAKIYO')
ORDER BY u.user_id;

-- 1125Ritsukoの紹介統計（修正後）
SELECT 
    '=== 1125Ritsukoの修正後紹介統計 ===' as status,
    COUNT(*) as total_referrals
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- システム健全性チェック
SELECT 
    '=== システム健全性チェック ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer,
    ROUND(COUNT(referrer_id) * 100.0 / COUNT(*), 2) as referrer_percentage
FROM users
WHERE is_admin = false;

-- 簡単な循環参照チェック（修正されたユーザーのみ）
SELECT 
    '=== 循環参照チェック ===' as status,
    u1.user_id as user1,
    u2.user_id as referrer,
    u3.user_id as referrer_of_referrer,
    CASE 
        WHEN u1.user_id = u3.user_id THEN '❌ 循環参照あり'
        ELSE '✅ 正常'
    END as status_check
FROM users u1
LEFT JOIN users u2 ON u2.id = u1.referrer_id
LEFT JOIN users u3 ON u3.id = u2.referrer_id
WHERE u1.user_id IN ('klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 'bighand1011', 'Mira', 'OHTAKIYO')
ORDER BY u1.user_id;

-- 修正されたユーザーの紹介チェーン（3レベルまで）
SELECT 
    '=== 修正されたユーザーの紹介チェーン ===' as status,
    u1.user_id as user_id,
    u1.name as user_name,
    u2.user_id as referrer_lv1,
    u2.name as referrer_lv1_name,
    u3.user_id as referrer_lv2,
    u3.name as referrer_lv2_name,
    u4.user_id as referrer_lv3,
    u4.name as referrer_lv3_name
FROM users u1
LEFT JOIN users u2 ON u2.id = u1.referrer_id
LEFT JOIN users u3 ON u3.id = u2.referrer_id
LEFT JOIN users u4 ON u4.id = u3.referrer_id
WHERE u1.user_id IN ('klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 'bighand1011', 'Mira', 'OHTAKIYO')
ORDER BY u1.user_id;

COMMIT;
