-- すべての関数をテスト

-- 1. show_available_groups関数テスト
SELECT 'Testing show_available_groups():' as test;
SELECT * FROM show_available_groups();

-- 2. list_weekly_rates_backups関数テスト
SELECT 'Testing list_weekly_rates_backups():' as test;
SELECT * FROM list_weekly_rates_backups() LIMIT 5;

-- 3. get_system_status関数テスト
SELECT 'Testing get_system_status():' as test;
SELECT * FROM get_system_status();

-- 4. get_backup_list関数テスト
SELECT 'Testing get_backup_list():' as test;
SELECT * FROM get_backup_list() LIMIT 5;

-- 5. get_weekly_rates_with_groups関数テスト
SELECT 'Testing get_weekly_rates_with_groups():' as test;
SELECT * FROM get_weekly_rates_with_groups() LIMIT 5;

-- 6. list_configured_weeks関数テスト
SELECT 'Testing list_configured_weeks():' as test;
SELECT * FROM list_configured_weeks() LIMIT 5;

-- 7. check_weekly_rate関数テスト（既存データがある場合）
DO $$
DECLARE
    test_date DATE;
BEGIN
    SELECT week_start_date INTO test_date
    FROM group_weekly_rates 
    LIMIT 1;
    
    IF test_date IS NOT NULL THEN
        RAISE NOTICE 'Testing check_weekly_rate() with date: %', test_date;
        PERFORM * FROM check_weekly_rate(test_date);
    ELSE
        RAISE NOTICE 'No existing weekly rates found for testing';
    END IF;
END;
$$;

-- 8. force_daily_calculation関数テスト
SELECT 'Testing force_daily_calculation():' as test;
SELECT * FROM force_daily_calculation();

SELECT 'All function tests completed' as status;
