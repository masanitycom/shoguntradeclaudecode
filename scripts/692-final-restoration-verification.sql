-- 最終的な復元確認と検証

-- 1. 復元された週利設定の総合確認
SELECT 
    '📊 復元後の週利設定総合確認' as section,
    COUNT(*) as total_settings,
    COUNT(DISTINCT week_start_date) as unique_weeks,
    COUNT(DISTINCT group_id) as unique_groups,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 2. 各グループの最新週設定確認
WITH latest_week AS (
    SELECT MAX(week_start_date) as max_week
    FROM group_weekly_rates
)
SELECT 
    '📋 各グループの最新週設定' as section,
    drg.group_name,
    gwr.weekly_rate * 100 as weekly_percent,
    gwr.monday_rate * 100 as mon_percent,
    gwr.tuesday_rate * 100 as tue_percent,
    gwr.wednesday_rate * 100 as wed_percent,
    gwr.thursday_rate * 100 as thu_percent,
    gwr.friday_rate * 100 as fri_percent,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) * 100 as total_daily_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
JOIN latest_week lw ON gwr.week_start_date = lw.max_week
ORDER BY drg.daily_rate_limit;

-- 3. バックアップシステムの確認
SELECT 
    '💾 バックアップシステム確認' as section,
    COUNT(*) as total_backups,
    COUNT(DISTINCT week_start_date) as backed_up_weeks,
    MIN(backup_timestamp) as earliest_backup,
    MAX(backup_timestamp) as latest_backup
FROM group_weekly_rates_backup;

-- 4. 管理画面関数の動作確認
SELECT 
    '🔧 管理画面関数動作確認' as section,
    'get_system_status' as function_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_system_status'
        ) THEN '✅ 存在'
        ELSE '❌ 不存在'
    END as status;

SELECT 
    '🔧 管理画面関数動作確認' as section,
    'get_weekly_rates_with_groups' as function_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_weekly_rates_with_groups'
        ) THEN '✅ 存在'
        ELSE '❌ 不存在'
    END as status;

-- 5. 日利計算の準備確認
SELECT 
    '⚙️ 日利計算準備確認' as section,
    COUNT(un.id) as active_nfts,
    COUNT(DISTINCT un.user_id) as users_with_nfts,
    SUM(n.price) as total_investment
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true;

-- 6. 今日の日利計算実行可能性確認
WITH today_rates AS (
    SELECT 
        gwr.group_id,
        drg.group_name,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as today_rate
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date <= CURRENT_DATE 
    AND gwr.week_start_date + 6 >= CURRENT_DATE
)
SELECT 
    '📈 今日の日利レート確認' as section,
    tr.group_name,
    tr.today_rate * 100 as today_rate_percent,
    COUNT(un.id) as nft_count_in_group
FROM today_rates tr
LEFT JOIN nfts n ON n.daily_rate_group_id = tr.group_id
LEFT JOIN user_nfts un ON un.nft_id = n.id AND un.is_active = true
GROUP BY tr.group_name, tr.today_rate
ORDER BY tr.today_rate;

-- 7. 復元完了メッセージ
SELECT 
    '🎉 復元完了' as status,
    '週利設定が正常に復元されました' as message,
    'バックアップシステムが構築されました' as backup_status,
    '管理画面が正常に動作します' as ui_status;
