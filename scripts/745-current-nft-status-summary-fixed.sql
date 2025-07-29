-- 現在のNFT購入・運用状況の完全な把握（修正版）

-- 1. 全体サマリー
SELECT 
    '=== 全体サマリー ===' as section,
    COUNT(*) as total_active_nfts,
    COUNT(DISTINCT user_id) as total_users,
    SUM(purchase_price) as total_investment,
    MIN(purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') as earliest_purchase_jst,
    MAX(purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') as latest_purchase_jst,
    MIN(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') as earliest_operation_jst,
    MAX(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') as latest_operation_jst
FROM user_nfts 
WHERE is_active = true;

-- 2. ユーザー別詳細（購入日・運用開始日）
SELECT 
    '=== ユーザー別詳細 ===' as section,
    u.name as user_name,
    u.user_id,
    n.name as nft_name,
    un.purchase_price,
    un.purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo' as jst_purchase_date,
    un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo' as jst_operation_start,
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date - 
    (un.purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as wait_days,
    TO_CHAR(un.purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD (Day)') as purchase_day,
    TO_CHAR(un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD (Day)') as operation_day,
    un.current_investment,
    un.total_earned,
    CASE 
        WHEN un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo' <= NOW() AT TIME ZONE 'Asia/Tokyo'
        THEN '✅ 運用中'
        ELSE '⏳ 運用前'
    END as status
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.purchase_date, u.name
LIMIT 20; -- 最初の20件

-- 3. 運用開始日別グループ（修正版）
SELECT 
    '=== 運用開始日別グループ ===' as section,
    operation_start_date_jst,
    formatted_date,
    nft_count,
    user_count,
    total_investment,
    operation_status,
    weekly_rate_status
FROM (
    SELECT 
        (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as operation_start_date_jst,
        TO_CHAR(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD (Day)') as formatted_date,
        COUNT(*) as nft_count,
        COUNT(DISTINCT user_id) as user_count,
        SUM(purchase_price) as total_investment,
        CASE 
            WHEN (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= (NOW() AT TIME ZONE 'Asia/Tokyo')::date
            THEN '✅ 運用開始済み'
            ELSE '⏳ 運用開始前'
        END as operation_status,
        -- 週利設定の確認
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM group_weekly_rates 
                WHERE week_start_date = (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
            )
            THEN '✅ 週利設定済み'
            ELSE '❌ 週利未設定'
        END as weekly_rate_status
    FROM user_nfts 
    WHERE is_active = true
    GROUP BY (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
) subquery
ORDER BY operation_start_date_jst;

-- 4. 週利設定の現状
SELECT 
    '=== 週利設定の現状 ===' as section,
    week_start_date,
    week_end_date,
    group_name,
    weekly_rate,
    monday_rate + tuesday_rate + wednesday_rate + thursday_rate + friday_rate as total_daily_rate,
    -- この週に運用開始するNFT数
    (
        SELECT COUNT(*) 
        FROM user_nfts 
        WHERE is_active = true 
        AND (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date = gwr.week_start_date
    ) as affected_nfts
FROM group_weekly_rates gwr
ORDER BY week_start_date, group_name;

-- 5. 未設定の週利（緊急対応が必要）
SELECT 
    '=== 未設定の週利（緊急対応必要） ===' as section,
    missing_week_start,
    formatted_date,
    affected_nfts,
    affected_users,
    total_investment,
    priority_level
FROM (
    SELECT 
        (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as missing_week_start,
        TO_CHAR(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD (Day)') as formatted_date,
        COUNT(*) as affected_nfts,
        COUNT(DISTINCT user_id) as affected_users,
        SUM(purchase_price) as total_investment,
        CASE 
            WHEN COUNT(*) > 100 THEN '🔥 最優先'
            WHEN COUNT(*) > 10 THEN '⚠️ 高優先'
            ELSE '📝 通常'
        END as priority_level
    FROM user_nfts un
    WHERE is_active = true
    AND NOT EXISTS (
        SELECT 1 FROM group_weekly_rates gwr
        WHERE gwr.week_start_date = (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
    )
    GROUP BY (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
) subquery
ORDER BY affected_nfts DESC, missing_week_start;

-- 6. テーブル構造確認
SELECT 
    '=== テーブル構造確認 ===' as section,
    'user_nfts' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;
