-- 🚨 緊急データ復旧 - 手動設定週利の復元

-- 1. 現在の状況を緊急調査
SELECT 
    '🚨 現在の週利設定状況' as status,
    COUNT(*) as total_settings,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week,
    STRING_AGG(DISTINCT distribution_method, ', ') as methods_used
FROM group_weekly_rates;

-- 2. バックアップテーブルの確認
SELECT 
    '💾 バックアップ状況確認' as status,
    COUNT(*) as backup_count,
    MIN(backup_timestamp) as earliest_backup,
    MAX(backup_timestamp) as latest_backup,
    STRING_AGG(DISTINCT backup_reason, ', ') as backup_reasons
FROM group_weekly_rates_backup
WHERE backup_reason LIKE '%Manual%' OR backup_reason LIKE '%手動%';

-- 3. 最新の手動バックアップを探す
SELECT 
    '🔍 手動バックアップ検索' as status,
    week_start_date,
    backup_timestamp,
    backup_reason,
    COUNT(*) as group_count
FROM group_weekly_rates_backup
WHERE backup_reason LIKE '%Manual%' 
   OR backup_reason LIKE '%手動%'
   OR backup_reason LIKE '%admin%'
ORDER BY backup_timestamp DESC
LIMIT 10;

-- 4. 自動変更された設定を特定
SELECT 
    '⚠️ 自動変更された設定' as status,
    week_start_date,
    group_name,
    weekly_rate * 100 as weekly_percent,
    distribution_method,
    created_at
FROM group_weekly_rates
WHERE distribution_method IN ('RESTORED_FROM_SPECIFICATION', 'EMERGENCY_DEFAULT', 'MANUAL_CORRECTED')
ORDER BY week_start_date DESC, group_name;

-- 5. 緊急停止 - 自動変更処理を無効化
UPDATE group_weekly_rates 
SET distribution_method = 'EMERGENCY_FROZEN'
WHERE distribution_method IN ('RESTORED_FROM_SPECIFICATION', 'EMERGENCY_DEFAULT', 'MANUAL_CORRECTED');

-- 6. 手動設定データの痕跡を探す
SELECT 
    '🔍 手動設定の痕跡検索' as status,
    week_start_date,
    group_name,
    weekly_rate * 100 as weekly_percent,
    monday_rate * 100 as mon_percent,
    tuesday_rate * 100 as tue_percent,
    wednesday_rate * 100 as wed_percent,
    thursday_rate * 100 as thu_percent,
    friday_rate * 100 as fri_percent,
    distribution_method,
    created_at
FROM group_weekly_rates_backup
WHERE backup_reason NOT LIKE '%automatic%'
   AND backup_reason NOT LIKE '%RESTORED%'
ORDER BY backup_timestamp DESC
LIMIT 20;
