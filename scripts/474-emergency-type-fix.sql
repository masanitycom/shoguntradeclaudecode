-- 緊急型修正 - 問題の関数を完全に削除して再作成

-- 1. 問題のある関数を完全削除
DROP FUNCTION IF EXISTS get_admin_weekly_rates_summary() CASCADE;
DROP FUNCTION IF EXISTS get_weekly_rates_for_admin() CASCADE;
DROP FUNCTION IF EXISTS get_daily_rate_groups_for_admin() CASCADE;
DROP FUNCTION IF EXISTS get_system_status_for_admin() CASCADE;

-- 2. テーブル構造を正確に確認
SELECT 
    '🔍 daily_rate_groups テーブル構造' as section,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
ORDER BY ordinal_position;

-- 3. 実際のデータ型を確認
SELECT 
    '🔧 実際のデータ型確認' as section,
    pg_typeof(group_name) as group_name_type,
    pg_typeof(description) as description_type,
    pg_typeof(daily_rate_limit) as daily_rate_limit_type
FROM daily_rate_groups 
LIMIT 1;

-- 4. 現在の週利設定を直接確認
SELECT 
    '📊 現在の週利設定' as section,
    gwr.id,
    gwr.group_id,
    drg.group_name,
    drg.daily_rate_limit,
    gwr.weekly_rate,
    gwr.week_start_date
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY drg.daily_rate_limit;

-- 5. 管理画面用の簡単なクエリテスト
SELECT 
    '🧪 管理画面用クエリテスト' as section,
    drg.id as group_id,
    drg.group_name,
    drg.daily_rate_limit,
    COUNT(gwr.id) as weekly_settings_count
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON gwr.group_id = drg.id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
