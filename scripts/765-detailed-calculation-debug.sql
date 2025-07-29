-- 詳細な日利計算デバッグ

-- 1. 基本データの存在確認
SELECT 
    '=== 基本データ確認 ===' as section,
    'user_nfts' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_count
FROM user_nfts
UNION ALL
SELECT 
    '=== 基本データ確認 ===' as section,
    'nfts' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_count
FROM nfts
UNION ALL
SELECT 
    '=== 基本データ確認 ===' as section,
    'daily_rate_groups' as table_name,
    COUNT(*) as total_count,
    COUNT(*) as active_count
FROM daily_rate_groups
UNION ALL
SELECT 
    '=== 基本データ確認 ===' as section,
    'group_weekly_rates' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN week_start_date = '2025-02-10' THEN 1 END) as active_count
FROM group_weekly_rates;

-- 2. NFTとグループの関連確認
SELECT 
    '=== NFTグループ関連確認 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    drg.group_name,
    drg.daily_rate_limit as group_limit,
    CASE 
        WHEN drg.group_name IS NULL THEN 'グループなし'
        ELSE 'グループあり'
    END as group_status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE n.is_active = true
ORDER BY n.daily_rate_limit;

-- 3. 週利設定の詳細確認
SELECT 
    '=== 週利設定詳細 ===' as section,
    gwr.week_start_date,
    gwr.group_name,
    gwr.monday_rate,
    drg.group_name as drg_group_name,
    CASE 
        WHEN drg.group_name IS NULL THEN 'グループ定義なし'
        ELSE 'グループ定義あり'
    END as group_definition_status
FROM group_weekly_rates gwr
LEFT JOIN daily_rate_groups drg ON gwr.group_name = drg.group_name
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY gwr.group_name;

-- 4. 実際の計算ロジックをステップバイステップで確認
WITH target_date_info AS (
    SELECT 
        '2025-02-10'::date as target_date,
        '2025-02-10'::date - (EXTRACT(DOW FROM '2025-02-10'::date)::INTEGER - 1) as week_start_monday,
        EXTRACT(DOW FROM '2025-02-10'::date)::INTEGER as day_of_week
),
daily_rates AS (
    SELECT 
        gwr.group_name,
        CASE tdi.day_of_week
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as daily_rate,
        gwr.weekly_rate,
        tdi.day_of_week,
        tdi.week_start_monday
    FROM group_weekly_rates gwr
    CROSS JOIN target_date_info tdi
    WHERE gwr.week_start_date = tdi.week_start_monday
),
eligible_nfts AS (
    SELECT 
        un.id as user_nft_id,
        un.user_id,
        un.nft_id,
        un.purchase_price,
        n.daily_rate_limit,
        n.name as nft_name,
        drg.group_name,
        un.operation_start_date,
        (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as operation_date,
        tdi.target_date
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    CROSS JOIN target_date_info tdi
    WHERE un.is_active = true
    AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= tdi.target_date
),
calculation_details AS (
    SELECT 
        en.user_nft_id,
        en.nft_name,
        en.purchase_price,
        en.daily_rate_limit,
        en.group_name,
        dr.daily_rate,
        dr.weekly_rate,
        CASE 
            WHEN en.group_name IS NULL THEN 'グループなし'
            WHEN dr.group_name IS NULL THEN 'レートなし'
            WHEN dr.daily_rate = 0 THEN 'レート0%'
            WHEN dr.daily_rate IS NULL THEN 'レートNULL'
            ELSE '計算可能'
        END as calculation_status,
        CASE 
            WHEN en.group_name IS NOT NULL AND dr.daily_rate IS NOT NULL AND dr.daily_rate > 0
            THEN LEAST(en.purchase_price * dr.daily_rate, en.daily_rate_limit)
            ELSE 0
        END as calculated_reward
    FROM eligible_nfts en
    LEFT JOIN daily_rates dr ON en.group_name = dr.group_name
)
SELECT 
    '=== 計算詳細分析 ===' as section,
    calculation_status,
    COUNT(*) as nft_count,
    SUM(purchase_price) as total_investment,
    SUM(calculated_reward) as total_rewards
FROM calculation_details
GROUP BY calculation_status
ORDER BY nft_count DESC;

-- 5. 具体的な計算例を表示
WITH target_date_info AS (
    SELECT 
        '2025-02-10'::date as target_date,
        '2025-02-10'::date - (EXTRACT(DOW FROM '2025-02-10'::date)::INTEGER - 1) as week_start_monday,
        EXTRACT(DOW FROM '2025-02-10'::date)::INTEGER as day_of_week
),
sample_calculation AS (
    SELECT 
        un.id as user_nft_id,
        n.name as nft_name,
        un.purchase_price,
        n.daily_rate_limit,
        drg.group_name,
        gwr.monday_rate,
        LEAST(un.purchase_price * COALESCE(gwr.monday_rate, 0), n.daily_rate_limit) as calculated_reward
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    LEFT JOIN group_weekly_rates gwr ON drg.group_name = gwr.group_name AND gwr.week_start_date = '2025-02-10'
    CROSS JOIN target_date_info tdi
    WHERE un.is_active = true
    AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= tdi.target_date
    LIMIT 10
)
SELECT 
    '=== 計算サンプル ===' as section,
    nft_name,
    purchase_price,
    daily_rate_limit,
    group_name,
    (COALESCE(monday_rate, 0) * 100)::numeric(5,2) as monday_rate_percent,
    calculated_reward
FROM sample_calculation
ORDER BY purchase_price DESC;
