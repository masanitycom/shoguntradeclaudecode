-- 2025年2月10日週の設定準備（修正版）

-- 1. 日付検証
SELECT 'Verifying February 10, 2025 is a Monday...' as status;

SELECT 
    '2025-02-10'::DATE as target_date,
    EXTRACT(DOW FROM '2025-02-10'::DATE) as day_of_week,
    CASE WHEN EXTRACT(DOW FROM '2025-02-10'::DATE) = 1 
         THEN '✅ Monday - Correct!' 
         ELSE '❌ Not Monday - Error!' 
    END as validation;

-- 2. 週の終了日計算
SELECT 'Calculating week end date...' as status;

SELECT 
    '2025-02-10'::DATE as week_start,
    '2025-02-10'::DATE + 4 as week_end,
    '2025-02-10'::DATE + 6 as week_end_sunday;

-- 3. 現在のグループ構造確認
SELECT 'Current NFT groups structure...' as status;

SELECT 
    drg.group_name,
    drg.daily_rate_limit,
    ROUND(drg.daily_rate_limit * 100, 2) as daily_rate_percent,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 4. 推奨週利設定値
SELECT 'Recommended weekly rates for February 10, 2025...' as status;

SELECT 
    '0.5%グループ' as group_name, 1.5 as recommended_weekly_rate_percent
UNION ALL SELECT '1.0%グループ', 2.0
UNION ALL SELECT '1.25%グループ', 2.3
UNION ALL SELECT '1.5%グループ', 2.6
UNION ALL SELECT '1.75%グループ', 2.9
UNION ALL SELECT '2.0%グループ', 3.2;

-- 5. 既存の2/10週設定確認
SELECT 'Checking existing February 10 settings...' as status;

SELECT 
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 2) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 6. バックアップテーブル確認
SELECT 'Checking backup table status...' as status;

SELECT 
    COUNT(*) as total_backup_records,
    COUNT(DISTINCT week_start_date) as unique_weeks_backed_up,
    MIN(created_at) as oldest_backup,
    MAX(created_at) as newest_backup
FROM group_weekly_rates_backup;

-- 7. 設定実行用SQLコマンド生成
SELECT 'Generated SQL commands for February 10 setup...' as status;

SELECT 
    format('SELECT set_group_weekly_rate(''%s'', ''%s'', %s);', 
           '2025-02-10', 
           group_name, 
           recommended_weekly_rate_percent / 100.0
    ) as sql_command
FROM (
    SELECT '0.5%グループ' as group_name, 1.5 as recommended_weekly_rate_percent
    UNION ALL SELECT '1.0%グループ', 2.0
    UNION ALL SELECT '1.25%グループ', 2.3
    UNION ALL SELECT '1.5%グループ', 2.6
    UNION ALL SELECT '1.75%グループ', 2.9
    UNION ALL SELECT '2.0%グループ', 3.2
) rates;

SELECT 'February 10, 2025 setup preparation completed!' as status;
