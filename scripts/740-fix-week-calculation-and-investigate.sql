-- 週計算の修正と詳細調査

-- 1. 実際の運用開始日を確認（月曜日かどうか）
SELECT 
    un.operation_start_date,
    EXTRACT(DOW FROM un.operation_start_date) as day_of_week, -- 1=月曜日
    TO_CHAR(un.operation_start_date, 'Day') as day_name,
    COUNT(*) as nft_count,
    CASE 
        WHEN EXTRACT(DOW FROM un.operation_start_date) = 1 THEN '✅ 月曜日'
        WHEN EXTRACT(DOW FROM un.operation_start_date) = 0 THEN '❌ 日曜日'
        WHEN EXTRACT(DOW FROM un.operation_start_date) = 6 THEN '❌ 土曜日'
        ELSE '❌ 平日（月曜以外）'
    END as day_check
FROM user_nfts un
WHERE un.is_active = true
GROUP BY un.operation_start_date, EXTRACT(DOW FROM un.operation_start_date)
ORDER BY un.operation_start_date;

-- 2. 正しい月曜日ベースの週計算
WITH monday_weeks AS (
    SELECT 
        un.operation_start_date,
        -- 月曜日を週の開始とする正しい計算
        CASE 
            WHEN EXTRACT(DOW FROM un.operation_start_date) = 1 THEN un.operation_start_date::date
            ELSE (un.operation_start_date::date - EXTRACT(DOW FROM un.operation_start_date)::int + 1)
        END as correct_week_start,
        COUNT(*) as nft_count
    FROM user_nfts un
    WHERE un.is_active = true
    GROUP BY un.operation_start_date
)
SELECT 
    correct_week_start,
    SUM(nft_count) as total_nfts,
    STRING_AGG(operation_start_date::text, ', ') as actual_start_dates
FROM monday_weeks
GROUP BY correct_week_start
ORDER BY total_nfts DESC, correct_week_start;

-- 3. 既存の週利設定との照合
WITH monday_weeks AS (
    SELECT 
        CASE 
            WHEN EXTRACT(DOW FROM un.operation_start_date) = 1 THEN un.operation_start_date::date
            ELSE (un.operation_start_date::date - EXTRACT(DOW FROM un.operation_start_date)::int + 1)
        END as correct_week_start,
        COUNT(*) as nft_count
    FROM user_nfts un
    WHERE un.is_active = true
    GROUP BY 1
),
existing_rates AS (
    SELECT DISTINCT week_start_date
    FROM group_weekly_rates
)
SELECT 
    mw.correct_week_start,
    mw.nft_count,
    CASE 
        WHEN er.week_start_date IS NOT NULL THEN '✅ 設定済み'
        ELSE '❌ 未設定'
    END as rate_status,
    CASE 
        WHEN mw.nft_count > 100 THEN '🔥 最優先'
        WHEN mw.nft_count > 10 THEN '⚠️ 高優先'
        ELSE '📝 通常'
    END as priority
FROM monday_weeks mw
LEFT JOIN existing_rates er ON mw.correct_week_start = er.week_start_date
ORDER BY mw.nft_count DESC, mw.correct_week_start;

-- 4. 運用開始日の設定が正しいかの検証
SELECT 
    '運用開始日設定の検証' as check_type,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date) = 1 THEN 1 END) as monday_starts,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date) != 1 THEN 1 END) as non_monday_starts,
    CASE 
        WHEN COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date) = 1 THEN 1 END) = COUNT(*) 
        THEN '✅ 全て月曜日'
        ELSE '❌ 月曜日以外あり'
    END as validation_result
FROM user_nfts 
WHERE is_active = true;
