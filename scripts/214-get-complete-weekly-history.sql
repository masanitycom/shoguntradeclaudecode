-- 17週以前を含む完全な週利履歴を取得

-- 1. 週利履歴の全体概要
SELECT 
    'Weekly History Overview' as check_type,
    COUNT(*) as total_records,
    MIN(week_number) as earliest_week,
    MAX(week_number) as latest_week,
    COUNT(DISTINCT nft_id) as unique_nfts,
    COUNT(DISTINCT week_number) as unique_weeks
FROM nft_weekly_rates;

-- 2. 週別の設定数
SELECT 
    'Weekly Settings Count' as check_type,
    week_number,
    COUNT(*) as nft_count,
    AVG(weekly_rate) as avg_weekly_rate,
    MIN(weekly_rate) as min_weekly_rate,
    MAX(weekly_rate) as max_weekly_rate
FROM nft_weekly_rates
GROUP BY week_number
ORDER BY week_number;

-- 3. 17週以前の詳細履歴
SELECT 
    'Pre-Week-17 History' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate,
    nwr.week_start_date,
    nwr.created_at
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.week_number < 17
ORDER BY nwr.week_number DESC, n.name;

-- 4. 17週以降の履歴
SELECT 
    'Week-17-and-Later History' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate,
    nwr.week_start_date,
    nwr.created_at
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.week_number >= 17
ORDER BY nwr.week_number DESC, n.name;

-- 5. 均等配分vs不均等配分の分析
SELECT 
    'Distribution Analysis' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate,
    CASE 
        WHEN ABS(nwr.monday_rate - nwr.tuesday_rate) < 0.01 
         AND ABS(nwr.tuesday_rate - nwr.wednesday_rate) < 0.01
         AND ABS(nwr.wednesday_rate - nwr.thursday_rate) < 0.01
         AND ABS(nwr.thursday_rate - nwr.friday_rate) < 0.01
        THEN 'EQUAL_DISTRIBUTION'
        ELSE 'UNEQUAL_DISTRIBUTION'
    END as distribution_type,
    CASE 
        WHEN nwr.monday_rate = 0 OR nwr.tuesday_rate = 0 OR nwr.wednesday_rate = 0 
         OR nwr.thursday_rate = 0 OR nwr.friday_rate = 0
        THEN 'HAS_ZERO_DAYS'
        ELSE 'NO_ZERO_DAYS'
    END as zero_days_status
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
ORDER BY nwr.week_number DESC, n.name
LIMIT 50;

-- 6. 最新の設定状況
SELECT 
    'Latest Settings' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate,
    nwr.created_at
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.week_number = (SELECT MAX(week_number) FROM nft_weekly_rates)
ORDER BY n.name;
