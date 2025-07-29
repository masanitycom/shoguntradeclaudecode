-- 日利計算が0件になる原因を調査

-- 1. 週利設定の確認
SELECT 
    '=== 週利設定確認 ===' as section,
    week_start_date,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    distribution_method
FROM group_weekly_rates
WHERE week_start_date = '2025-02-10'
ORDER BY group_name;

-- 2. NFTとグループの対応確認
SELECT 
    '=== NFTグループ対応確認 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    drg.group_name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE un.is_active = true
AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= '2025-02-10'
GROUP BY n.name, n.daily_rate_limit, drg.group_name
ORDER BY nft_count DESC;

-- 3. 日利計算のステップバイステップ確認
WITH week_start AS (
    SELECT '2025-02-10'::date - (EXTRACT(DOW FROM '2025-02-10'::date)::INTEGER - 1) as monday
),
daily_rates AS (
    SELECT 
        gwr.group_name,
        gwr.monday_rate,
        gwr.weekly_rate
    FROM group_weekly_rates gwr, week_start ws
    WHERE gwr.week_start_date = ws.monday
),
eligible_nfts AS (
    SELECT 
        un.id as user_nft_id,
        un.user_id,
        un.nft_id,
        un.purchase_price,
        n.name as nft_name,
        n.daily_rate_limit,
        drg.group_name,
        un.operation_start_date,
        (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as operation_date
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    WHERE un.is_active = true
    AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= '2025-02-10'
)
SELECT 
    '=== 計算ステップ確認 ===' as section,
    en.nft_name,
    en.group_name,
    dr.monday_rate,
    en.purchase_price,
    CASE 
        WHEN dr.monday_rate IS NULL THEN 'グループレートなし'
        WHEN dr.monday_rate = 0 THEN 'レート0%'
        ELSE '計算可能'
    END as status,
    CASE 
        WHEN dr.monday_rate IS NOT NULL AND dr.monday_rate > 0 
        THEN LEAST(en.purchase_price * dr.monday_rate, en.daily_rate_limit)
        ELSE 0
    END as calculated_reward
FROM eligible_nfts en
LEFT JOIN daily_rates dr ON en.group_name = dr.group_name
ORDER BY en.nft_name
LIMIT 20;

-- 4. 問題の特定
SELECT 
    '=== 問題特定 ===' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = '2025-02-10') = 0 
        THEN '週利設定なし'
        WHEN (SELECT COUNT(*) FROM daily_rate_groups) = 0 
        THEN 'グループ設定なし'
        WHEN (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) = 0 
        THEN 'アクティブNFTなし'
        ELSE '他の問題'
    END as issue_type;
