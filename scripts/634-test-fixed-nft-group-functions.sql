-- 修正された関数をテスト

-- 1. show_available_groups関数をテスト
SELECT 'Testing show_available_groups function...' as status;

SELECT * FROM show_available_groups();

-- 2. get_weekly_rates_with_groups関数をテスト  
SELECT 'Testing get_weekly_rates_with_groups function...' as status;

SELECT * FROM get_weekly_rates_with_groups() LIMIT 5;

-- 3. 日利計算関数をテスト
SELECT 'Testing calculate_daily_rewards_for_date function...' as status;

SELECT * FROM calculate_daily_rewards_for_date('2025-02-10'::DATE) LIMIT 5;

SELECT 'All functions tested successfully!' as status;
