-- ステップバイステップでデバッグ

-- 1. 基本データの確認
SELECT 
    '=== 基本データ確認 ===' as section,
    'ユーザー数: ' || COUNT(*) as info
FROM users;

SELECT 
    '=== アクティブNFT確認 ===' as section,
    n.name,
    n.daily_rate_limit,
    COUNT(un.id) as user_count
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
GROUP BY n.name, n.daily_rate_limit
ORDER BY n.daily_rate_limit;

-- 2. グループマッピングの確認
SELECT 
    '=== グループマッピング確認 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    drg.group_name
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE n.is_active = true
ORDER BY n.daily_rate_limit;

-- 3. 週利設定の確認
SELECT 
    '=== 週利設定確認 ===' as section,
    week_start_date,
    group_name,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM group_weekly_rates
WHERE week_start_date = '2025-02-10'
ORDER BY group_name;

-- 4. 計算対象NFTの詳細確認
SELECT 
    '=== 計算対象NFT詳細 ===' as section,
    u.name as user_name,
    n.name as nft_name,
    un.purchase_price,
    n.daily_rate_limit,
    drg.group_name,
    un.operation_start_date,
    CASE 
        WHEN (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= '2025-02-10'
        THEN '対象'
        ELSE '対象外'
    END as eligibility
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN users u ON un.user_id = u.id
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE un.is_active = true
ORDER BY u.name, n.name;

-- 5. 手動計算テスト（1件のみ）
WITH test_calculation AS (
    SELECT 
        un.id as user_nft_id,
        u.name as user_name,
        n.name as nft_name,
        un.purchase_price,
        n.daily_rate_limit,
        drg.group_name,
        gwr.monday_rate,
        (un.purchase_price * gwr.monday_rate) as calculated_reward,
        LEAST(un.purchase_price * gwr.monday_rate, n.daily_rate_limit) as final_reward
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    JOIN users u ON un.user_id = u.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    JOIN group_weekly_rates gwr ON drg.group_name = gwr.group_name
    WHERE un.is_active = true
    AND gwr.week_start_date = '2025-02-10'
    AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= '2025-02-10'
    LIMIT 5
)
SELECT 
    '=== 手動計算テスト ===' as section,
    *
FROM test_calculation;

SELECT '✅ デバッグ完了' as status;
