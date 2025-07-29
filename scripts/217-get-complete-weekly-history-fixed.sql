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

-- 2. 週別の設定数と統計
SELECT 
    'Weekly Settings Statistics' as check_type,
    week_number,
    COUNT(*) as nft_count,
    ROUND(AVG(weekly_rate), 3) as avg_weekly_rate,
    ROUND(MIN(weekly_rate), 3) as min_weekly_rate,
    ROUND(MAX(weekly_rate), 3) as max_weekly_rate,
    week_start_date
FROM nft_weekly_rates
GROUP BY week_number, week_start_date
ORDER BY week_number;

-- 3. 17週以前の詳細履歴（サンプル20件）
SELECT 
    'Pre-Week-17 Sample' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate,
    nwr.week_start_date,
    DATE(nwr.created_at) as created_date
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.week_number < 17
ORDER BY nwr.week_number DESC, n.name
LIMIT 20;

-- 4. 17週以降の履歴（サンプル20件）
SELECT 
    'Week-17-and-Later Sample' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate,
    nwr.week_start_date,
    DATE(nwr.created_at) as created_date
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.week_number >= 17
ORDER BY nwr.week_number DESC, n.name
LIMIT 20;

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
        THEN 'EQUAL'
        ELSE 'RANDOM'
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
LIMIT 30;

-- 6. 0%の日がある設定例
SELECT 
    'Zero Rate Days Examples' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    CASE WHEN nwr.monday_rate = 0 THEN 'Monday=0%' ELSE NULL END as zero_monday,
    CASE WHEN nwr.tuesday_rate = 0 THEN 'Tuesday=0%' ELSE NULL END as zero_tuesday,
    CASE WHEN nwr.wednesday_rate = 0 THEN 'Wednesday=0%' ELSE NULL END as zero_wednesday,
    CASE WHEN nwr.thursday_rate = 0 THEN 'Thursday=0%' ELSE NULL END as zero_thursday,
    CASE WHEN nwr.friday_rate = 0 THEN 'Friday=0%' ELSE NULL END as zero_friday,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.monday_rate = 0 
   OR nwr.tuesday_rate = 0 
   OR nwr.wednesday_rate = 0 
   OR nwr.thursday_rate = 0 
   OR nwr.friday_rate = 0
ORDER BY nwr.week_number DESC
LIMIT 15;

-- 7. 最新の設定状況（第20週）
SELECT 
    'Latest Week Settings' as check_type,
    nwr.week_number,
    n.name as nft_name,
    nwr.weekly_rate,
    nwr.monday_rate,
    nwr.tuesday_rate,
    nwr.wednesday_rate,
    nwr.thursday_rate,
    nwr.friday_rate,
    DATE(nwr.created_at) as created_date
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.week_number = (SELECT MAX(week_number) FROM nft_weekly_rates)
ORDER BY n.name;

-- 8. 週利設定の変化履歴（同じNFTの週利変化）
SELECT 
    'Rate Change History' as check_type,
    n.name as nft_name,
    nwr.week_number,
    nwr.weekly_rate,
    LAG(nwr.weekly_rate) OVER (PARTITION BY nwr.nft_id ORDER BY nwr.week_number) as previous_rate,
    CASE 
        WHEN LAG(nwr.weekly_rate) OVER (PARTITION BY nwr.nft_id ORDER BY nwr.week_number) IS NULL THEN 'INITIAL'
        WHEN nwr.weekly_rate > LAG(nwr.weekly_rate) OVER (PARTITION BY nwr.nft_id ORDER BY nwr.week_number) THEN 'INCREASED'
        WHEN nwr.weekly_rate < LAG(nwr.weekly_rate) OVER (PARTITION BY nwr.nft_id ORDER BY nwr.week_number) THEN 'DECREASED'
        ELSE 'UNCHANGED'
    END as rate_change
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE n.name IN ('SHOGUN NFT 1000', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000')
ORDER BY n.name, nwr.week_number;
