-- 不足している週利設定の作成計画

-- 1. 必要な週利設定の完全リスト
WITH monday_weeks AS (
    SELECT 
        CASE 
            WHEN EXTRACT(DOW FROM un.operation_start_date) = 1 THEN un.operation_start_date::date
            ELSE (un.operation_start_date::date - EXTRACT(DOW FROM un.operation_start_date)::int + 1)
        END as week_start,
        COUNT(*) as nft_count,
        MIN(un.operation_start_date) as earliest_start,
        MAX(un.operation_start_date) as latest_start
    FROM user_nfts un
    WHERE un.is_active = true
    GROUP BY 1
),
existing_rates AS (
    SELECT DISTINCT week_start_date
    FROM group_weekly_rates
),
missing_weeks AS (
    SELECT 
        mw.week_start,
        mw.nft_count,
        mw.earliest_start,
        mw.latest_start,
        ROW_NUMBER() OVER (ORDER BY mw.nft_count DESC, mw.week_start) as priority_order
    FROM monday_weeks mw
    LEFT JOIN existing_rates er ON mw.week_start = er.week_start_date
    WHERE er.week_start_date IS NULL
)
SELECT 
    priority_order,
    week_start,
    week_start + INTERVAL '4 days' as week_end,
    nft_count,
    earliest_start,
    latest_start,
    CASE 
        WHEN nft_count > 100 THEN '🔥 即座に対応'
        WHEN nft_count > 10 THEN '⚠️ 早急に対応'
        ELSE '📝 通常対応'
    END as urgency,
    '-- 週利設定SQL生成用 --' as sql_template
FROM missing_weeks
ORDER BY priority_order;

-- 2. 最優先週の詳細情報
WITH top_priority AS (
    SELECT 
        CASE 
            WHEN EXTRACT(DOW FROM un.operation_start_date) = 1 THEN un.operation_start_date::date
            ELSE (un.operation_start_date::date - EXTRACT(DOW FROM un.operation_start_date)::int + 1)
        END as week_start,
        COUNT(*) as nft_count
    FROM user_nfts un
    WHERE un.is_active = true
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1
)
SELECT 
    tp.week_start as critical_week_start,
    tp.nft_count as affected_nfts,
    COUNT(DISTINCT un.user_id) as affected_users,
    STRING_AGG(DISTINCT n.name, ', ') as nft_types,
    SUM(n.price) as total_investment_amount,
    '次のステップ: この週の週利設定を作成' as next_action
FROM top_priority tp
JOIN user_nfts un ON (
    CASE 
        WHEN EXTRACT(DOW FROM un.operation_start_date) = 1 THEN un.operation_start_date::date
        ELSE (un.operation_start_date::date - EXTRACT(DOW FROM un.operation_start_date)::int + 1)
    END = tp.week_start
)
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
GROUP BY tp.week_start, tp.nft_count;
