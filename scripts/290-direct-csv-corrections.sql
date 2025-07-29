-- 🔥 CSVの通りに直接修正するSQL
-- 確実に一発で修正します

BEGIN;

-- バックアップテーブル作成
DROP TABLE IF EXISTS referral_backup_final;
CREATE TABLE referral_backup_final AS
SELECT 
    id,
    user_id,
    name,
    referrer_id,
    (SELECT user_id FROM users u2 WHERE u2.id = u1.referrer_id) as referrer_user_id,
    NOW() as backup_time
FROM users u1
WHERE is_admin = false;

-- 🎯 CSVの通りに直接修正

-- 1125Ritsuko -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = '1125Ritsuko';

-- kazukazu2 -> kazukazu1
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'kazukazu1' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'kazukazu2';

-- yatchan002 -> yatchan
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'yatchan002';

-- yatchan003 -> yatchan
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'yatchan003';

-- bighand1011 -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'bighand1011';

-- klmiklmi0204 -> yasui001
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'yasui001' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'klmiklmi0204';

-- Mira -> Mickey
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'Mickey' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'Mira';

-- OHTAKIYO -> klmiklmi0204
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'klmiklmi0204' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'OHTAKIYO';

-- 🔥 重要な修正確認
SELECT 
    '=== 重要ユーザーの修正確認 ===' as check_type,
    u.user_id,
    u.name,
    r.user_id as referrer_user_id,
    r.name as referrer_name
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('1125Ritsuko', 'kazukazu2', 'yatchan002', 'yatchan003', 'bighand1011', 'klmiklmi0204', 'Mira', 'OHTAKIYO')
ORDER BY u.user_id;

-- 1125Ritsukoの紹介数確認
SELECT 
    '=== 1125Ritsukoの現在の紹介数 ===' as check_type,
    COUNT(*) as referral_count
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正前後の比較
SELECT 
    '=== 修正されたユーザー数 ===' as check_type,
    COUNT(*) as modified_users
FROM users u
JOIN referral_backup_final b ON u.id = b.id
WHERE u.referrer_id != b.referrer_id 
   OR (u.referrer_id IS NULL) != (b.referrer_id IS NULL);

COMMIT;

-- 最終確認
SELECT 
    '🔥 CSVベース修正完了' as status,
    NOW() as completion_time;
