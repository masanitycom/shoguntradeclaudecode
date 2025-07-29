-- 緊急修正: 今日削除してしまった紹介関係を正しく復元

-- 修正前の状態確認
SELECT 
    '=== 修正前の現在の状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as current_referrer,
    COALESCE(r.name, 'なし') as current_referrer_name
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('bighand1011', 'klmiklmi0204', 'Mira')
ORDER BY u.user_id;

-- 紹介者の存在確認
SELECT 
    '=== 紹介者存在確認 ===' as status,
    user_id,
    name,
    email,
    CASE 
        WHEN user_id IN ('USER0a18', 'yasui001', 'Mickey') THEN '✅ 紹介者として利用可能'
        ELSE '❓ 確認が必要'
    END as referrer_status
FROM users 
WHERE user_id IN ('USER0a18', 'yasui001', 'Mickey')
ORDER BY user_id;

-- CSVの分析結果に基づいて修正を実行
-- ※ 実際のCSV分析結果を確認してから実行してください

-- 修正実行（CSVの結果に基づいて調整が必要）
BEGIN;

-- 1. bighand1011 の紹介者を設定（CSVの結果に基づく）
-- UPDATE users 
-- SET 
--     referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
--     updated_at = NOW()
-- WHERE user_id = 'bighand1011';

-- 2. klmiklmi0204 の紹介者を設定（CSVの結果に基づく）
-- UPDATE users 
-- SET 
--     referrer_id = (SELECT id FROM users WHERE user_id = 'yasui001'),
--     updated_at = NOW()
-- WHERE user_id = 'klmiklmi0204';

-- 3. Mira の紹介者を設定（CSVの結果に基づく）
-- UPDATE users 
-- SET 
--     referrer_id = (SELECT id FROM users WHERE user_id = 'Mickey'),
--     updated_at = NOW()
-- WHERE user_id = 'Mira';

-- コミットは手動で実行
-- COMMIT;

SELECT '⚠️ CSVの分析結果を確認してから修正を実行してください' as warning_message;

-- 修正後の確認用クエリ（修正実行後に使用）
-- SELECT 
--     '=== 修正後の状態 ===' as status,
--     u.user_id,
--     u.name,
--     COALESCE(r.user_id, 'なし') as new_referrer,
--     COALESCE(r.name, 'なし') as new_referrer_name,
--     u.updated_at
-- FROM users u
-- LEFT JOIN users r ON u.referrer_id = r.id
-- WHERE u.user_id IN ('bighand1011', 'klmiklmi0204', 'Mira')
-- ORDER BY u.user_id;
