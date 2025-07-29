-- CSVデータに基づく正確な紹介関係修正
-- 実行前に scripts/280-show-specific-corrections.js を実行して内容を確認してください

BEGIN;

-- 現在の問題のある状態を確認
SELECT 
    '=== 現在の問題のある状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE((SELECT user_id FROM users WHERE id = u.referrer_id), 'なし') as current_referrer,
    COALESCE((SELECT name FROM users WHERE id = u.referrer_id), 'なし') as current_referrer_name
FROM users u
WHERE u.user_id IN ('klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 'bighand1011', 'Mira', 'OHTAKIYO')
ORDER BY u.user_id;

-- 修正前の状態をバックアップ
DROP TABLE IF EXISTS csv_correction_backup_final;
CREATE TABLE csv_correction_backup_final AS
SELECT 
    user_id,
    name,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as current_referrer_user_id,
    updated_at,
    NOW() as backup_created_at
FROM users u
WHERE user_id IN ('klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 'bighand1011', 'Mira', 'OHTAKIYO');

-- CSVデータに基づく修正を実行
-- 注意: 実際のCSV分析結果に基づいて以下のUPDATE文を調整してください

-- 例: kazukazu2の紹介者修正（CSVで確認された正しい紹介者に設定）
-- UPDATE users 
-- SET 
--     referrer_id = (SELECT id FROM users WHERE user_id = 'CSV_CORRECT_REFERRER'),
--     updated_at = NOW()
-- WHERE user_id = 'kazukazu2'
-- AND EXISTS (SELECT 1 FROM users WHERE user_id = 'CSV_CORRECT_REFERRER');

-- 修正後の状態を確認
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

-- システム健全性チェック
SELECT 
    '=== システム健全性チェック ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users;

-- 紹介者なしユーザーの確認
SELECT 
    '=== 紹介者なしユーザー ===' as status,
    user_id,
    name,
    CASE 
        WHEN user_id = 'admin001' THEN '✅ 管理者（正常）'
        WHEN user_id LIKE 'USER%' THEN '✅ ルートユーザー（正常）'
        ELSE '❌ 紹介者が必要'
    END as expected_status
FROM users
WHERE referrer_id IS NULL
ORDER BY user_id;

-- 1125Ritsukoの紹介統計
SELECT 
    '=== 1125Ritsukoの紹介統計 ===' as status,
    COUNT(*) as total_referrals
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 安全のため、まずはROLLBACKで確認
ROLLBACK;

-- 実際に修正を実行する場合は、上記のROLLBACKをCOMMIT;に変更し、
-- scripts/280-show-specific-corrections.js の結果に基づいてUPDATE文を追加してください
