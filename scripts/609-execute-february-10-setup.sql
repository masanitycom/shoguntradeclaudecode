-- 2025年2月10日週の設定実行

-- 1. 既存データのバックアップ（存在する場合）
SELECT backup_weekly_rates('2025-02-10'::DATE, 'Before February 10 setup');

-- 2. 2025年2月10日週の週利設定実行
SELECT set_weekly_rates_for_all_groups(
    '2025-02-10'::DATE,  -- week_start_date
    2.6,                 -- total_weekly_rate (2.6%)
    'February 10 week setup - Manual configuration'  -- reason
);

-- 3. 設定結果確認
SELECT 'February 10, 2025 week rates configuration:' as info;
SELECT 
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    ROUND(gwr.monday_rate * 100, 2) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) as friday_percent,
    ROUND((gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) * 100, 2) as total_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'::DATE
ORDER BY drg.daily_rate_limit;

-- 4. システム状況確認
SELECT 'System status after setup:' as info;
SELECT * FROM get_system_status();

-- 5. 日利計算テスト（2025年2月10日）
SELECT 'Testing daily calculation for 2025-02-10:' as info;
SELECT 
    COUNT(*) as eligible_user_nfts,
    SUM(amount) as total_daily_rewards
FROM calculate_daily_rewards_for_date('2025-02-10'::DATE);

SELECT 'February 10, 2025 setup completed successfully!' as status;
