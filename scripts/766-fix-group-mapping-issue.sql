-- グループマッピングの問題を修正

-- 1. 現在のNFTとグループの対応状況を確認
SELECT 
    '=== 現在のマッピング状況 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    drg.group_name,
    COUNT(un.id) as nft_count
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
WHERE n.is_active = true
GROUP BY n.name, n.daily_rate_limit, drg.group_name
ORDER BY nft_count DESC;

-- 2. 不足しているグループを作成
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, created_at, updated_at)
SELECT DISTINCT
    CASE 
        WHEN n.daily_rate_limit <= 5 THEN 'Group_100'
        WHEN n.daily_rate_limit <= 15 THEN 'Group_500'
        WHEN n.daily_rate_limit <= 50 THEN 'Group_1000'
        WHEN n.daily_rate_limit <= 150 THEN 'Group_5000'
        WHEN n.daily_rate_limit <= 500 THEN 'Group_10000'
        ELSE 'Group_Special'
    END as group_name,
    n.daily_rate_limit,
    NOW(),
    NOW()
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE n.is_active = true
AND drg.group_name IS NULL
ON CONFLICT (daily_rate_limit) DO NOTHING;

-- 3. 新しく作成されたグループの週利設定を追加
INSERT INTO group_weekly_rates (
    week_start_date,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    distribution_method,
    created_at,
    updated_at
)
SELECT DISTINCT
    '2025-02-10'::date as week_start_date,
    drg.group_name,
    0.026 as weekly_rate,
    0.005 as monday_rate,
    0.006 as tuesday_rate,
    0.005 as wednesday_rate,
    0.005 as thursday_rate,
    0.005 as friday_rate,
    'manual' as distribution_method,
    NOW() as created_at,
    NOW() as updated_at
FROM daily_rate_groups drg
WHERE NOT EXISTS (
    SELECT 1 FROM group_weekly_rates gwr 
    WHERE gwr.week_start_date = '2025-02-10' 
    AND gwr.group_name = drg.group_name
);

-- 4. 2025-02-17週の設定も追加
INSERT INTO group_weekly_rates (
    week_start_date,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    distribution_method,
    created_at,
    updated_at
)
SELECT DISTINCT
    '2025-02-17'::date as week_start_date,
    drg.group_name,
    0.026 as weekly_rate,
    0.005 as monday_rate,
    0.006 as tuesday_rate,
    0.005 as wednesday_rate,
    0.005 as thursday_rate,
    0.005 as friday_rate,
    'manual' as distribution_method,
    NOW() as created_at,
    NOW() as updated_at
FROM daily_rate_groups drg
WHERE NOT EXISTS (
    SELECT 1 FROM group_weekly_rates gwr 
    WHERE gwr.week_start_date = '2025-02-17' 
    AND gwr.group_name = drg.group_name
);

-- 5. 修正後の状況を確認
SELECT 
    '=== 修正後マッピング状況 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    drg.group_name,
    gwr.monday_rate,
    COUNT(un.id) as nft_count
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN group_weekly_rates gwr ON drg.group_name = gwr.group_name AND gwr.week_start_date = '2025-02-10'
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
WHERE n.is_active = true
GROUP BY n.name, n.daily_rate_limit, drg.group_name, gwr.monday_rate
ORDER BY nft_count DESC;

SELECT '✅ グループマッピング修正完了' as status;
