-- CSVデータに基づく紹介関係の修正実行

-- Step 1: 修正前の状態をバックアップ（通常テーブルとして作成）
DROP TABLE IF EXISTS pre_fix_backup;
CREATE TABLE pre_fix_backup AS
SELECT 
    u.user_id,
    u.name,
    u.email,
    u.referrer_id,
    r.user_id as referrer_code,
    r.name as referrer_name,
    u.updated_at
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204');

-- バックアップ作成確認
SELECT 
    'バックアップ作成完了: ' || COUNT(*) || ' 件のレコード' as backup_status
FROM pre_fix_backup;

-- Step 2: 修正前の状態を表示
SELECT 
    '=== 修正前の状態 ===' as status,
    user_id,
    name,
    referrer_code as current_referrer,
    referrer_name
FROM pre_fix_backup
ORDER BY user_id;

-- Step 3: CSVデータに基づく修正実行
BEGIN;

-- 1. 1125Ritsuko の紹介者を USER0a18 に変更
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = '1125Ritsuko';

-- ログ記録
SELECT log_referral_change(
    '1125Ritsuko',
    'bighand1011',
    'USER0a18',
    'CSV data correction - correct referrer relationship',
    'CSV_DATA_CORRECTION'
) as log_1125ritsuko;

-- 2. bighand1011 の紹介者を削除（NULL）
UPDATE users 
SET 
    referrer_id = NULL,
    updated_at = NOW()
WHERE user_id = 'bighand1011';

-- ログ記録
SELECT log_referral_change(
    'bighand1011',
    '1125Ritsuko',
    NULL,
    'CSV data correction - should have no referrer',
    'CSV_DATA_CORRECTION'
) as log_bighand1011;

-- 3. klmiklmi0204 の紹介者を削除（NULL）
UPDATE users 
SET 
    referrer_id = NULL,
    updated_at = NOW()
WHERE user_id = 'klmiklmi0204';

-- ログ記録
SELECT log_referral_change(
    'klmiklmi0204',
    'yasui001',
    NULL,
    'CSV data correction - should have no referrer',
    'CSV_DATA_CORRECTION'
) as log_klmiklmi0204;

-- 4. USER0a18 の紹介者を削除（NULL）
UPDATE users 
SET 
    referrer_id = NULL,
    updated_at = NOW()
WHERE user_id = 'USER0a18';

-- ログ記録
SELECT log_referral_change(
    'USER0a18',
    'masataka001',
    NULL,
    'CSV data correction - should have no referrer',
    'CSV_DATA_CORRECTION'
) as log_user0a18;

-- 5. Mira の紹介者を削除（NULL）
UPDATE users 
SET 
    referrer_id = NULL,
    updated_at = NOW()
WHERE user_id = 'Mira';

-- ログ記録
SELECT log_referral_change(
    'Mira',
    'Maripeko3587',
    NULL,
    'CSV data correction - should have no referrer',
    'CSV_DATA_CORRECTION'
) as log_mira;

-- OHTAKIYO は既に正しいのでそのまま
SELECT 'OHTAKIYO は既に正しい紹介者 (klmiklmi0204) を持っているため変更なし' as ohtakiyo_status;

COMMIT;

-- Step 4: 修正後の状態を確認
SELECT 
    '=== 修正後の状態 ===' as status,
    u.user_id,
    u.name,
    u.email,
    COALESCE(r.user_id, 'なし') as new_referrer,
    COALESCE(r.name, 'なし') as new_referrer_name,
    u.updated_at
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204')
ORDER BY u.user_id;

-- Step 5: 修正前後の比較
SELECT 
    '=== 修正前後の比較 ===' as status,
    b.user_id,
    b.name,
    COALESCE(b.referrer_code, 'なし') as before_referrer,
    COALESCE(r.user_id, 'なし') as after_referrer,
    CASE 
        WHEN COALESCE(b.referrer_code, '') != COALESCE(r.user_id, '') THEN '🔄 変更あり'
        ELSE '➡️ 変更なし'
    END as change_status
FROM pre_fix_backup b
LEFT JOIN users u ON b.user_id = u.user_id
LEFT JOIN users r ON u.referrer_id = r.id
ORDER BY b.user_id;

-- Step 6: 修正結果のサマリー
SELECT 
    '=== 修正結果サマリー ===' as status,
    COUNT(*) as total_fixed_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as users_without_referrer
FROM users 
WHERE user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204');

-- Step 7: システム健全性チェック
SELECT 
    '=== 循環参照チェック ===' as status,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 循環参照なし'
        ELSE '❌ 循環参照あり: ' || COUNT(*)::TEXT || '件'
    END as circular_check
FROM check_circular_references();

SELECT 
    '=== 無効な紹介者チェック ===' as status,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 無効な紹介者なし'
        ELSE '❌ 無効な紹介者あり: ' || COUNT(*)::TEXT || '件'
    END as invalid_referrer_check
FROM check_invalid_referrers();

-- Step 8: CSVデータとの整合性確認
WITH csv_expected AS (
    SELECT 'OHTAKIYO' as user_id, 'klmiklmi0204' as expected_referrer
    UNION ALL
    SELECT '1125Ritsuko', 'USER0a18'
    UNION ALL
    SELECT 'USER0a18', NULL
    UNION ALL
    SELECT 'bighand1011', NULL
    UNION ALL
    SELECT 'Mira', NULL
    UNION ALL
    SELECT 'klmiklmi0204', NULL
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
    '=== CSVデータとの整合性確認 ===' as status,
    e.user_id,
    COALESCE(e.expected_referrer, 'なし') as expected,
    COALESCE(c.actual_referrer, 'なし') as actual,
    CASE 
        WHEN COALESCE(e.expected_referrer, '') = COALESCE(c.actual_referrer, '') THEN '✅ 正しい'
        ELSE '❌ 不一致'
    END as match_status
FROM csv_expected e
LEFT JOIN current_state c ON e.user_id = c.user_id
ORDER BY e.user_id;

-- Step 9: 1125Ritsukoの紹介統計
SELECT 
    '=== 1125Ritsukoの紹介統計 ===' as status,
    COUNT(*) as total_referrals,
    COUNT(CASE WHEN email LIKE '%@shogun-trade.com' THEN 1 END) as proxy_email_count,
    COUNT(CASE WHEN email NOT LIKE '%@shogun-trade.com' THEN 1 END) as real_email_count
FROM users 
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko')
AND is_admin = false;

-- Step 10: バックアップテーブルの削除
DROP TABLE IF EXISTS pre_fix_backup;

SELECT '🎉 CSVデータに基づく紹介関係の修正が完了しました！' as completion_message;
SELECT '📊 次は scripts/268-final-verification.js を実行して最終検証を行ってください' as next_step;
