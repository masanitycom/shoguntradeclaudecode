-- 手動週利設定を開始するためのスクリプト

-- まず現在の状況を確認
SELECT 'CURRENT STATUS CHECK' as section;

-- 設定済み週利の確認
SELECT 'Configured weeks count:' as info, COUNT(*) as count 
FROM (SELECT DISTINCT week_start_date FROM group_weekly_rates) as weeks;

-- 最新の設定を確認
SELECT 
    'Latest configured week:' as info,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 今週の設定状況
SELECT 
    'This week status:' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM group_weekly_rates 
            WHERE week_start_date = (DATE_TRUNC('week', CURRENT_DATE)::DATE + 1)
        ) 
        THEN 'CONFIGURED' 
        ELSE 'NOT CONFIGURED' 
    END as status,
    (DATE_TRUNC('week', CURRENT_DATE)::DATE + 1) as this_monday;

-- 2月の週を表示
WITH february_weeks AS (
    SELECT generate_series(
        '2025-02-03'::DATE,  -- 2月最初の月曜日
        '2025-02-24'::DATE,  -- 2月最後の月曜日
        '7 days'::INTERVAL
    )::DATE as monday
)
SELECT 
    'February Weeks for Manual Setting' as info,
    fw.monday as monday_date,
    fw.monday + 4 as friday_date,
    format('2月第%s週', 
           CASE 
               WHEN fw.monday = '2025-02-03' THEN '1'
               WHEN fw.monday = '2025-02-10' THEN '2'
               WHEN fw.monday = '2025-02-17' THEN '3'
               WHEN fw.monday = '2025-02-24' THEN '4'
           END
    ) as week_info,
    EXISTS(SELECT 1 FROM group_weekly_rates WHERE week_start_date = fw.monday) as configured
FROM february_weeks fw
ORDER BY fw.monday;

-- 設定が必要な週の提案
SELECT 'SUGGESTED WEEKS TO CONFIGURE' as section;

-- 過去4週間で未設定の週を表示
WITH past_weeks AS (
    SELECT generate_series(
        DATE_TRUNC('week', CURRENT_DATE - INTERVAL '4 weeks')::DATE + 1,
        DATE_TRUNC('week', CURRENT_DATE)::DATE + 1,
        '7 days'::INTERVAL
    )::DATE as monday_date
),
configured_weeks AS (
    SELECT DISTINCT week_start_date FROM group_weekly_rates
)
SELECT 
    'Unconfigured past weeks:' as info,
    pw.monday_date,
    pw.monday_date + 4 as friday_date,
    'NEEDS CONFIGURATION' as status
FROM past_weeks pw
LEFT JOIN configured_weeks cw ON pw.monday_date = cw.week_start_date
WHERE cw.week_start_date IS NULL
ORDER BY pw.monday_date;

-- 今後4週間の設定推奨
WITH future_weeks AS (
    SELECT generate_series(
        DATE_TRUNC('week', CURRENT_DATE + INTERVAL '1 week')::DATE + 1,
        DATE_TRUNC('week', CURRENT_DATE + INTERVAL '4 weeks')::DATE + 1,
        '7 days'::INTERVAL
    )::DATE as monday_date
)
SELECT 
    'Future weeks to configure:' as info,
    fw.monday_date,
    fw.monday_date + 4 as friday_date,
    'RECOMMENDED TO CONFIGURE' as status
FROM future_weeks fw
ORDER BY fw.monday_date;

-- 今後の月曜日（設定可能な週）を表示
WITH future_mondays AS (
    SELECT generate_series(
        CURRENT_DATE + (1 - EXTRACT(DOW FROM CURRENT_DATE))::INTEGER + 7,
        CURRENT_DATE + INTERVAL '2 months',
        '7 days'::INTERVAL
    )::DATE as monday
)
SELECT 
    'Future Mondays for Manual Setting' as info,
    monday as monday_dates
FROM future_mondays
ORDER BY monday
LIMIT 10;

-- 実際の設定コマンド例
SELECT 'READY TO USE COMMANDS' as section;

-- 今週の設定コマンド（コピペ用）
SELECT 
    'Set this week (2.6%):' as command_type,
    format('SELECT * FROM set_weekly_rate_manual(''%s'', 2.6, ''random'');', 
           (DATE_TRUNC('week', CURRENT_DATE)::DATE + 1)) as copy_paste_command;

-- 先週の設定コマンド（コピペ用）
SELECT 
    'Set last week (2.6%):' as command_type,
    format('SELECT * FROM set_weekly_rate_manual(''%s'', 2.6, ''random'');', 
           (DATE_TRUNC('week', CURRENT_DATE - INTERVAL '1 week')::DATE + 1)) as copy_paste_command;

-- 確認コマンド（コピペ用）
SELECT 
    'Check this week:' as command_type,
    format('SELECT * FROM check_weekly_rate(''%s'');', 
           (DATE_TRUNC('week', CURRENT_DATE)::DATE + 1)) as copy_paste_command;

-- 全体確認コマンド
SELECT 
    'Command Templates' as command_type,
    'List all configured weeks:' as description,
    'SELECT * FROM list_configured_weeks();' as copy_paste_command;
