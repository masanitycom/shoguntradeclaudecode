-- 週利設定と運用開始日のカバレッジ確認

-- 1. 運用開始日に対応する週利設定があるかチェック
WITH nft_weeks AS (
    SELECT DISTINCT
        operation_start_date,
        -- 運用開始日の週の月曜日を計算
        operation_start_date - (EXTRACT(DOW FROM operation_start_date) - 1)::int * INTERVAL '1 day' as week_monday
    FROM user_nfts 
    WHERE is_active = true
),
missing_rates AS (
    SELECT 
        nw.operation_start_date,
        nw.week_monday,
        CASE 
            WHEN gwr.week_start_date IS NULL THEN '❌ 週利設定なし'
            ELSE '✅ 週利設定あり'
        END as rate_status
    FROM nft_weeks nw
    LEFT JOIN group_weekly_rates gwr ON nw.week_monday = gwr.week_start_date
)
SELECT 
    rate_status,
    COUNT(*) as count,
    MIN(operation_start_date) as earliest_operation,
    MAX(operation_start_date) as latest_operation
FROM missing_rates
GROUP BY rate_status
ORDER BY rate_status;

-- 2. 週利設定が必要な期間の特定
SELECT DISTINCT
    operation_start_date - (EXTRACT(DOW FROM operation_start_date) - 1)::int * INTERVAL '1 day' as needed_week_start,
    COUNT(*) as nft_count
FROM user_nfts 
WHERE is_active = true
AND operation_start_date - (EXTRACT(DOW FROM operation_start_date) - 1)::int * INTERVAL '1 day' 
    NOT IN (SELECT week_start_date FROM group_weekly_rates)
GROUP BY needed_week_start
ORDER BY needed_week_start;
