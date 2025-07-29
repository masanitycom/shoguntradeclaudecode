-- 手動設定の復元

-- 1. 最新の手動バックアップを特定
WITH latest_manual_backup AS (
    SELECT 
        week_start_date,
        MAX(backup_timestamp) as latest_backup
    FROM group_weekly_rates_backup
    WHERE backup_reason LIKE '%Manual%' 
       OR backup_reason LIKE '%手動%'
       OR backup_reason LIKE '%admin%'
       OR backup_reason NOT LIKE '%automatic%'
    GROUP BY week_start_date
)
-- 2. 手動設定データを復元
INSERT INTO group_weekly_rates (
    id,
    week_start_date,
    week_end_date,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    group_id,
    group_name,
    distribution_method,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    gwrb.week_start_date,
    gwrb.week_end_date,
    gwrb.weekly_rate,
    gwrb.monday_rate,
    gwrb.tuesday_rate,
    gwrb.wednesday_rate,
    gwrb.thursday_rate,
    gwrb.friday_rate,
    gwrb.group_id,
    gwrb.group_name,
    'RESTORED_MANUAL_SETTINGS',
    NOW(),
    NOW()
FROM group_weekly_rates_backup gwrb
JOIN latest_manual_backup lmb ON gwrb.week_start_date = lmb.week_start_date 
                              AND gwrb.backup_timestamp = lmb.latest_backup
ON CONFLICT (week_start_date, group_id) DO UPDATE SET
    weekly_rate = EXCLUDED.weekly_rate,
    monday_rate = EXCLUDED.monday_rate,
    tuesday_rate = EXCLUDED.tuesday_rate,
    wednesday_rate = EXCLUDED.wednesday_rate,
    thursday_rate = EXCLUDED.thursday_rate,
    friday_rate = EXCLUDED.friday_rate,
    distribution_method = 'RESTORED_MANUAL_SETTINGS',
    updated_at = NOW();

-- 3. 復元結果確認
SELECT 
    '✅ 手動設定復元結果' as status,
    week_start_date,
    group_name,
    weekly_rate * 100 as weekly_percent,
    distribution_method,
    updated_at
FROM group_weekly_rates
WHERE distribution_method = 'RESTORED_MANUAL_SETTINGS'
ORDER BY week_start_date DESC, group_name;
