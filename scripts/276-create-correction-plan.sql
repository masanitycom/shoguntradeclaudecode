-- CSVデータに基づく修正計画の作成

-- 1. 修正前の状態をバックアップ
DROP TABLE IF EXISTS referral_correction_backup;
CREATE TABLE referral_correction_backup AS
SELECT 
    user_id,
    name,
    email,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as referrer_user_id,
    updated_at,
    created_at
FROM users u
WHERE user_id IN (
    'klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 
    'bighand1011', 'Mira', '1125Ritsuko', 'OHTAKIYO'
);

-- 2. バックアップ確認
SELECT 
    '=== 修正前バックアップ ===' as status,
    user_id,
    name,
    email,
    referrer_user_id as current_referrer,
    updated_at
FROM referral_correction_backup
ORDER BY user_id;

-- 3. 重要ユーザーの現在の状態確認
SELECT 
    '=== 現在の状態確認 ===' as status,
    u.user_id,
    u.name,
    u.email,
    COALESCE((SELECT user_id FROM users WHERE id = u.referrer_id), 'なし') as current_referrer,
    COALESCE((SELECT name FROM users WHERE id = u.referrer_id), 'なし') as current_referrer_name,
    u.updated_at
FROM users u
WHERE u.user_id IN (
    'klmiklmi0204', 'kazukazu2', 'yatchan003', 'yatchan002', 
    'bighand1011', 'Mira', '1125Ritsuko', 'OHTAKIYO'
)
ORDER BY u.user_id;

-- 4. 修正が必要な紹介者の存在確認
SELECT 
    '=== 紹介者存在確認 ===' as status,
    user_id,
    name,
    email,
    '✅ 紹介者として利用可能' as referrer_status
FROM users
WHERE user_id IN (
    'USER0a18',    -- bighand1011の紹介者
    'yasui001',    -- klmiklmi0204の紹介者（要確認）
    'Mickey',      -- Miraの紹介者
    '1125Ritsuko', -- 他のユーザーの紹介者
    'klmiklmi0204' -- OHTAKIYOの紹介者
)
ORDER BY user_id;

-- 5. 1125Ritsukoが紹介したユーザーの確認（サンプル）
SELECT 
    '=== 1125Ritsukoの紹介ユーザー（サンプル10人） ===' as status,
    u.user_id,
    u.name,
    u.email,
    CASE 
        WHEN u.email LIKE '%@shogun-trade.com' THEN '📧 代理メール'
        ELSE '📧 実メール'
    END as email_type
FROM users u
WHERE u.referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko')
ORDER BY u.created_at
LIMIT 10;

-- 6. 代理メールユーザーの統計
SELECT 
    '=== 代理メール統計 ===' as status,
    COUNT(*) as total_proxy_users,
    COUNT(referrer_id) as proxy_with_referrer,
    COUNT(*) - COUNT(referrer_id) as proxy_without_referrer
FROM users
WHERE email LIKE '%@shogun-trade.com';

-- 7. 修正計画の提案
SELECT 
    '=== 修正計画 ===' as status,
    'Phase 1: 重要ユーザーの緊急修正' as phase,
    'klmiklmi0204, kazukazu2, yatchan003, yatchan002など' as target_users,
    'CSVデータに基づく正しい紹介者の設定' as method,
    '🔴 最高' as priority;

SELECT 
    '=== 修正計画 ===' as status,
    'Phase 2: 全ユーザーの段階的修正' as phase,
    '差異のあるすべてのユーザー' as target_users,
    'バッチ処理による段階的修正' as method,
    '🟡 中' as priority;

SELECT 
    '=== 修正計画 ===' as status,
    'Phase 3: 検証とテスト' as phase,
    '修正されたすべてのユーザー' as target_users,
    '循環参照チェック、整合性確認' as method,
    '🟢 低' as priority;

-- 8. 次のアクション
SELECT 
    '=== 次のアクション ===' as status,
    '1. CSVファイルの詳細分析結果を確認' as action_1,
    '2. 重要ユーザーの正しい紹介者を特定' as action_2,
    '3. 段階的修正スクリプトの作成' as action_3,
    '4. テスト環境での検証' as action_4,
    '5. 本番環境での実行' as action_5;

-- 9. システム健全性の現在の状態
SELECT 
    '=== システム健全性 ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users;

-- 10. 紹介者なしユーザーの詳細
SELECT 
    '=== 紹介者なしユーザー ===' as status,
    user_id,
    name,
    email,
    CASE 
        WHEN user_id = 'admin001' THEN '✅ 管理者（正常）'
        WHEN user_id = 'USER0a18' THEN '✅ ルートユーザー（正常）'
        ELSE '❌ 紹介者が必要'
    END as expected_status,
    created_at
FROM users
WHERE referrer_id IS NULL
ORDER BY created_at;
