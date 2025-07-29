-- CSVデータに基づく包括的な紹介関係修正
-- 実行日時: 2025-06-29
-- 対象: 重要ユーザーの紹介関係修正

BEGIN;

-- 修正前の状態をバックアップ
DROP TABLE IF EXISTS comprehensive_fix_backup_20250629;
CREATE TABLE comprehensive_fix_backup_20250629 AS
SELECT 
    user_id,
    name,
    email,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as referrer_user_id,
    updated_at,
    NOW() as backup_created_at
FROM users u
WHERE user_id IN (
    'klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 
    'bighand1011', 'Mira', '1125Ritsuko', 'OHTAKIYO'
);

-- 修正前の状態を表示
SELECT 
    '=== 修正前の状態 ===' as status,
    user_id,
    name,
    referrer_user_id as current_referrer,
    updated_at
FROM comprehensive_fix_backup_20250629
ORDER BY user_id;

-- CSVデータに基づく修正（重要ユーザーのみ）
-- 注意: 実際のCSV分析結果に基づいて以下を調整する必要があります

-- klmiklmi0204の紹介者修正（CSVで確認された正しい紹介者に設定）
-- 現在: yasui001 → CSVで確認された正しい紹介者に変更
-- ※ CSVの分析結果を確認してから実行

-- kazukazu2の紹介者修正
-- 現在: 1125Ritsuko → CSVで確認された正しい紹介者に変更
UPDATE users 
SET 
    referrer_id = (
        SELECT id FROM users 
        WHERE user_id = (
            -- CSVで確認されたkazukazu2の正しい紹介者をここに設定
            -- 例: 'correct_referrer_id'
            SELECT 'CSVで確認された紹介者' as placeholder
        )
    ),
    updated_at = NOW()
WHERE user_id = 'kazukazu2'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'CSVで確認された紹介者');

-- yatchan003の紹介者修正
-- 現在: 1125Ritsuko → CSVで確認された正しい紹介者に変更
UPDATE users 
SET 
    referrer_id = (
        SELECT id FROM users 
        WHERE user_id = (
            -- CSVで確認されたyatchan003の正しい紹介者をここに設定
            SELECT 'CSVで確認された紹介者' as placeholder
        )
    ),
    updated_at = NOW()
WHERE user_id = 'yatchan003'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'CSVで確認された紹介者');

-- yatchan002の紹介者修正
-- 現在: 1125Ritsuko → CSVで確認された正しい紹介者に変更
UPDATE users 
SET 
    referrer_id = (
        SELECT id FROM users 
        WHERE user_id = (
            -- CSVで確認されたyatchan002の正しい紹介者をここに設定
            SELECT 'CSVで確認された紹介者' as placeholder
        )
    ),
    updated_at = NOW()
WHERE user_id = 'yatchan002'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'CSVで確認された紹介者');

-- 修正後の状態を表示
SELECT 
    '=== 修正後の状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE((SELECT user_id FROM users WHERE id = u.referrer_id), 'なし') as new_referrer,
    COALESCE((SELECT name FROM users WHERE id = u.referrer_id), 'なし') as new_referrer_name,
    u.updated_at
FROM users u
WHERE u.user_id IN ('klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 'bighand1011', 'Mira')
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
    email,
    CASE 
        WHEN user_id = 'admin001' THEN '✅ 管理者（正常）'
        WHEN user_id = 'USER0a18' THEN '✅ ルートユーザー（正常）'
        ELSE '❌ 紹介者が必要'
    END as expected_status
FROM users
WHERE referrer_id IS NULL
ORDER BY user_id;

-- 1125Ritsukoの紹介統計
SELECT 
    '=== 1125Ritsukoの紹介統計 ===' as status,
    COUNT(*) as total_referrals,
    COUNT(CASE WHEN email LIKE '%@shogun-trade.com' THEN 1 END) as proxy_email_referrals,
    COUNT(CASE WHEN email NOT LIKE '%@shogun-trade.com' THEN 1 END) as real_email_referrals
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

ROLLBACK; -- 安全のため、まずはROLLBACKで確認

-- 実際に修正を実行する場合は、上記のROLLBACKをCOMMIT;に変更してください
