-- 2月10日週の最終設定

-- 1. 利用可能グループの確認
SELECT '📊 利用可能グループ一覧' as section;
SELECT * FROM show_available_groups();

-- 2. 2月10日週のバックアップ作成
SELECT '📦 バックアップ作成' as section;
SELECT * FROM admin_create_backup('2025-02-10'::DATE, '2月10日週設定前の自動バックアップ');

-- 3. 各グループの週利設定実行
SELECT '⚙️ 週利設定開始' as section;

-- 0.5%グループ: 週利1.5%
SELECT '設定中: 0.5%グループ' as action;
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '0.5%グループ', 1.5);

-- 1.0%グループ: 週利2.0%
SELECT '設定中: 1.0%グループ' as action;
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.0%グループ', 2.0);

-- 1.25%グループ: 週利2.3%
SELECT '設定中: 1.25%グループ' as action;
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.25%グループ', 2.3);

-- 1.5%グループ: 週利2.6%
SELECT '設定中: 1.5%グループ' as action;
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.5%グループ', 2.6);

-- 1.75%グループ: 週利2.9%
SELECT '設定中: 1.75%グループ' as action;
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.75%グループ', 2.9);

-- 2.0%グループ: 週利3.2%
SELECT '設定中: 2.0%グループ' as action;
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '2.0%グループ', 3.2);

-- 4. 設定結果の詳細確認
SELECT '✅ 2月10日週設定結果' as section;
SELECT 
    drg.group_name,
    drg.daily_rate_limit,
    ROUND(drg.daily_rate_limit * 100, 2) || '%' as daily_limit_display,
    ROUND(gwr.weekly_rate * 100, 1) || '%' as weekly_rate_display,
    ROUND(gwr.monday_rate * 100, 2) || '%' as monday_display,
    ROUND(gwr.tuesday_rate * 100, 2) || '%' as tuesday_display,
    ROUND(gwr.wednesday_rate * 100, 2) || '%' as wednesday_display,
    ROUND(gwr.thursday_rate * 100, 2) || '%' as thursday_display,
    ROUND(gwr.friday_rate * 100, 2) || '%' as friday_display,
    gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'::DATE
ORDER BY drg.daily_rate_limit;

-- 5. 管理画面用データ確認
SELECT '🖥️ 管理画面用データ確認' as section;
SELECT * FROM get_weekly_rates_with_groups() 
WHERE week_start_date = '2025-02-10';

-- 6. システム状況確認
SELECT '📈 システム状況確認' as section;
SELECT * FROM get_system_status();

-- 7. バックアップ確認
SELECT '📦 バックアップ確認' as section;
SELECT * FROM get_backup_list() 
WHERE week_start_date = '2025-02-10'::DATE;

-- 8. 最終確認メッセージ
SELECT 
    '🎉 2月10日週設定完了!' as status,
    COUNT(*) || '個のグループに週利設定済み' as summary,
    '管理画面から確認可能' as note
FROM group_weekly_rates 
WHERE week_start_date = '2025-02-10'::DATE;
