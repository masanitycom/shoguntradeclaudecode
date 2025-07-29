-- 🚨 グループ作成と2月10日設定

-- 1. 必要なグループが存在するか確認し、なければ作成
INSERT INTO daily_rate_groups (group_name, daily_rate_limit) VALUES
('0.5%グループ', 0.005),
('1.0%グループ', 0.01),
('1.25%グループ', 0.0125),
('1.5%グループ', 0.015),
('1.75%グループ', 0.0175),
('2.0%グループ', 0.02)
ON CONFLICT (group_name) DO UPDATE SET
    daily_rate_limit = EXCLUDED.daily_rate_limit;

-- 2. グループ作成確認
SELECT 
    id,
    group_name as "グループ名",
    daily_rate_limit as "日利上限",
    created_at as "作成日時"
FROM daily_rate_groups 
ORDER BY daily_rate_limit;

-- 3. 2025年2月10日の週利を設定
DO $$
DECLARE
    group_names TEXT[] := ARRAY['0.5%グループ', '1.0%グループ', '1.25%グループ', '1.5%グループ', '1.75%グループ', '2.0%グループ'];
    group_rates NUMERIC[] := ARRAY[1.5, 2.0, 2.3, 2.6, 2.9, 3.2];
    i INTEGER;
    result_json JSON;
BEGIN
    RAISE NOTICE '=== 2025年2月10日週利設定開始 ===';
    
    FOR i IN 1..array_length(group_names, 1) LOOP
        SELECT set_group_weekly_rate('2025-02-10', group_names[i], group_rates[i]) INTO result_json;
        
        RAISE NOTICE '設定結果: % - %', group_names[i], result_json->>'message';
    END LOOP;
    
    RAISE NOTICE '=== 設定完了 ===';
END $$;

-- 4. 設定結果確認
SELECT 
    drg.group_name as "グループ名",
    (gwr.weekly_rate * 100)::NUMERIC(5,2) as "週利(%)",
    (gwr.monday_rate * 100)::NUMERIC(5,2) as "月(%)",
    (gwr.tuesday_rate * 100)::NUMERIC(5,2) as "火(%)",
    (gwr.wednesday_rate * 100)::NUMERIC(5,2) as "水(%)",
    (gwr.thursday_rate * 100)::NUMERIC(5,2) as "木(%)",
    (gwr.friday_rate * 100)::NUMERIC(5,2) as "金(%)",
    gwr.created_at as "設定日時"
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 5. システム状況再確認
SELECT 
    (get_system_status()->>'total_users')::INTEGER as "総ユーザー数",
    (get_system_status()->>'active_nfts')::INTEGER as "アクティブNFT",
    (get_system_status()->>'pending_rewards')::NUMERIC as "保留中報酬",
    (get_system_status()->>'current_week_rates')::INTEGER as "設定済み週数";

-- 6. 管理画面用データ確認
SELECT 
    json_array_length(get_weekly_rates_with_groups()) as "管理画面表示可能レコード数";

-- 7. 完了メッセージ
SELECT 
    '=== 2月10日設定完了 ===' as "結果",
    COUNT(*) as "設定されたグループ数"
FROM group_weekly_rates gwr
WHERE gwr.week_start_date = '2025-02-10';
