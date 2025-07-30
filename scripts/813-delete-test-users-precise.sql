-- 精密なテストユーザー削除スクリプト

SELECT '=== PRECISE TEST USER DELETION ===' as section;

-- 削除対象の明確化
WITH test_users AS (
    SELECT id FROM users
    WHERE 
        -- パターン1: 名前が「ユーザー」で始まる
        name LIKE 'ユーザー%'
        -- パターン2: 名前が「テストユーザー」で始まる
        OR name LIKE 'テストユーザー%'
        -- パターン3: 電話番号が000-0000-0000
        OR phone = '000-0000-0000'
        -- パターン4: 2025/6/26 04:20:09に一括作成された大文字メール
        OR (created_at = '2025-06-26 04:20:09.784831+00' AND email ~ '^[A-Z]')
        -- パターン5: 単一文字/短いメールアドレス（小文字）で大文字版が存在する
        OR (email ~ '^[a-z0-9]{1,3}@shogun-trade\.com$' AND EXISTS (
            SELECT 1 FROM users u2 
            WHERE UPPER(users.email) = u2.email 
            AND users.id != u2.id
        ))
        -- adminは除外
        AND email != 'admin@shogun-trade.com'
)
SELECT COUNT(*) as test_users_to_delete FROM test_users;

-- 削除対象の詳細確認
SELECT 'Test users to be deleted:' as info;
SELECT id, name, email, phone, created_at
FROM users
WHERE id IN (SELECT id FROM test_users)
ORDER BY name, email;

-- 1. user_nftsから削除
SELECT 'Deleting from user_nfts...' as action;
DELETE FROM user_nfts
WHERE user_id IN (SELECT id FROM test_users);

-- 2. daily_rewardsから削除
SELECT 'Deleting from daily_rewards...' as action;
DELETE FROM daily_rewards
WHERE user_id IN (SELECT id FROM test_users);

-- 3. mlm_downline_volumesから削除
SELECT 'Deleting from mlm_downline_volumes...' as action;
DELETE FROM mlm_downline_volumes
WHERE user_id IN (SELECT id FROM test_users);

-- 4. reward_claimsから削除
SELECT 'Deleting from reward_claims...' as action;
DELETE FROM reward_claims
WHERE user_id IN (SELECT id FROM test_users);

-- 5. 紹介関係のクリア（referrer_idをNULLに）
SELECT 'Clearing referrer relationships...' as action;
UPDATE users
SET referrer_id = NULL
WHERE referrer_id IN (SELECT id FROM test_users);

-- 6. usersテーブルから削除
SELECT 'Deleting from users table...' as action;
DELETE FROM users
WHERE id IN (SELECT id FROM test_users);

-- 削除結果確認
SELECT 'Deletion results:' as result;
SELECT 
    (SELECT COUNT(*) FROM users) as remaining_users,
    (SELECT COUNT(*) FROM users WHERE email LIKE '%@shogun-trade.com%') as shogun_domain_users,
    (SELECT COUNT(*) FROM users WHERE name LIKE 'ユーザー%') as users_with_test_name;

SELECT '=== TEST USER CLEANUP COMPLETE ===' as status;