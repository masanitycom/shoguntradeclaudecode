-- 不足している週利設定の詳細サマリー

-- 1. 運用開始日別のNFT数と必要な週利設定
WITH operation_weeks AS (
    SELECT 
        DATE_TRUNC('week', operation_start_date)::date + INTERVAL '0 days' as week_start,
        COUNT(*) as nft_count,
        STRING_AGG(DISTINCT u.name, ', ') as user_names,
        MIN(operation_start_date) as earliest_start,
        MAX(operation_start_date) as latest_start
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    WHERE un.is_active = true
    GROUP BY DATE_TRUNC('week', operation_start_date)::date
),
existing_rates AS (
    SELECT DISTINCT week_start_date
    FROM group_weekly_rates
)
SELECT 
    ow.week_start,
    ow.nft_count,
    CASE 
        WHEN er.week_start_date IS NOT NULL THEN '✅ 設定済み'
        ELSE '❌ 未設定'
    END as rate_status,
    ow.earliest_start,
    ow.latest_start,
    CASE 
        WHEN ow.nft_count > 100 THEN '🔥 高優先度'
        WHEN ow.nft_count > 10 THEN '⚠️ 中優先度'
        ELSE '📝 低優先度'
    END as priority,
    LEFT(ow.user_names, 100) as sample_users
FROM operation_weeks ow
LEFT JOIN existing_rates er ON ow.week_start = er.week_start_date
ORDER BY ow.nft_count DESC, ow.week_start;

-- 2. 最優先対応が必要な週（276個のNFT）
SELECT 
    '2025-02-10'::date as critical_week,
    COUNT(*) as affected_nfts,
    COUNT(DISTINCT un.user_id) as affected_users,
    STRING_AGG(DISTINCT n.name, ', ') as nft_types,
    SUM(n.price) as total_investment
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
AND DATE_TRUNC('week', un.operation_start_date)::date = '2025-02-10'::date;

-- 3. 週利設定作成の優先順位
SELECT 
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) as priority_rank,
    DATE_TRUNC('week', operation_start_date)::date as week_start,
    COUNT(*) as nft_count,
    CASE 
        WHEN COUNT(*) > 100 THEN '即座に対応必要'
        WHEN COUNT(*) > 10 THEN '早急に対応必要'
        ELSE '通常対応'
    END as urgency_level
FROM user_nfts 
WHERE is_active = true
GROUP BY DATE_TRUNC('week', operation_start_date)::date
ORDER BY COUNT(*) DESC;
