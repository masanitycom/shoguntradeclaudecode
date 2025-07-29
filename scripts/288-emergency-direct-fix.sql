-- 🔥 緊急直接修正 - SQLで一発修正
-- 実行前に必ずバックアップを作成

BEGIN;

-- 修正前バックアップ
DROP TABLE IF EXISTS emergency_backup_20250629;
CREATE TABLE emergency_backup_20250629 AS
SELECT 
    user_id,
    name,
    referrer_id,
    updated_at,
    NOW() as backup_created_at
FROM users
WHERE is_admin = false;

-- 🔥 直接修正開始

-- 1125Ritsuko の紹介者を USER0a18 に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1)
WHERE user_id = '1125Ritsuko'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- kazukazu2 の紹介者を kazukazu1 に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'kazukazu1' LIMIT 1)
WHERE user_id = 'kazukazu2'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'kazukazu1');

-- yatchan002 の紹介者を yatchan に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan' LIMIT 1)
WHERE user_id = 'yatchan002'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yatchan');

-- yatchan003 の紹介者を yatchan に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan' LIMIT 1)
WHERE user_id = 'yatchan003'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yatchan');

-- bighand1011 の紹介者を USER0a18 に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1)
WHERE user_id = 'bighand1011'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- klmiklmi0204 の紹介者を yasui001 に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'yasui001' LIMIT 1)
WHERE user_id = 'klmiklmi0204'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yasui001');

-- Mira の紹介者を Mickey に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'Mickey' LIMIT 1)
WHERE user_id = 'Mira'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Mickey');

-- OHTAKIYO の紹介者を klmiklmi0204 に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'klmiklmi0204' LIMIT 1)
WHERE user_id = 'OHTAKIYO'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'klmiklmi0204');

-- 全Akiraシリーズを Akira0808 に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808' LIMIT 1)
WHERE user_id LIKE 'Akira0808%'
AND user_id != 'Akira0808'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 修正結果確認
SELECT 
    '=== 修正結果確認 ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users
WHERE is_admin = false;

-- 1125Ritsukoの紹介数確認
SELECT 
    '=== 1125Ritsukoの紹介数 ===' as status,
    COUNT(*) as referral_count
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正されたユーザー数
SELECT 
    '=== 修正されたユーザー数 ===' as status,
    COUNT(*) as modified_count
FROM users u1
JOIN emergency_backup_20250629 b ON u1.user_id = b.user_id
WHERE u1.referrer_id != b.referrer_id OR (u1.referrer_id IS NULL) != (b.referrer_id IS NULL);

COMMIT;

SELECT '🔥 緊急修正完了！' as final_status;
