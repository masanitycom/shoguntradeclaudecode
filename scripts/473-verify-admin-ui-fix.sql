-- 管理画面修正の検証

-- 1. 作成された関数の確認
SELECT '📋 作成された関数一覧' as section, routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name IN (
    'get_weekly_rates_for_admin',
    'get_daily_rate_groups_for_admin', 
    'get_admin_weekly_rates_summary',
    'get_system_status_for_admin'
)
ORDER BY routine_name;

-- 2. 週利設定の詳細確認
SELECT '📊 週利設定詳細確認' as section;
SELECT * FROM get_weekly_rates_for_admin() ORDER BY group_name;

-- 3. グループ情報の詳細確認
SELECT '🎯 グループ情報詳細確認' as section;
SELECT * FROM get_daily_rate_groups_for_admin() ORDER BY daily_rate_limit;

-- 4. 週利サマリーの確認（これが管理画面で使用される）
SELECT '🖥️ 管理画面用週利サマリー' as section;
SELECT * FROM get_admin_weekly_rates_summary() ORDER BY daily_rate_limit;

-- 5. システム状況の確認
SELECT '💻 システム状況確認' as section;
SELECT * FROM get_system_status_for_admin();

-- 6. 管理画面表示データの最終確認
SELECT '✅ 管理画面表示データ最終確認' as section;
SELECT 
    group_name,
    rate_display,
    nft_count,
    weekly_rate_percent || '%' as weekly_rate_display,
    CASE 
        WHEN has_weekly_setting THEN '✅ 設定済み'
        ELSE '❌ 未設定'
    END as setting_status
FROM get_admin_weekly_rates_summary()
ORDER BY daily_rate_limit;

-- 7. 週利設定の存在確認
SELECT '🔍 週利設定存在確認' as section;
SELECT 
    COUNT(*) as total_weekly_settings,
    COUNT(DISTINCT group_id) as groups_with_settings,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 8. 最終確認メッセージ
SELECT '🎉 修正完了確認' as section;
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM get_admin_weekly_rates_summary()) >= 5
        THEN '✅ 成功：管理画面用関数が正常に動作しています'
        ELSE '❌ 失敗：関数に問題があります'
    END as status,
    '管理画面をリロードして週利管理ページを確認してください' as instruction,
    'ブラウザのキャッシュクリアも推奨します' as tip;

-- 9. 管理画面で期待される表示内容
SELECT '📋 管理画面期待表示' as section;
SELECT 
    '以下のデータが管理画面に表示されるはずです：' as message
UNION ALL
SELECT '- ' || group_name || ': ' || rate_display || ' (週利' || weekly_rate_percent || '%)' 
FROM get_admin_weekly_rates_summary()
ORDER BY message;
