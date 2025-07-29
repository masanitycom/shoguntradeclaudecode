-- 最終検証とテスト

-- 1. 作成された関数の確認
SELECT 
    '📋 作成された関数一覧' as section,
    routine_name,
    routine_type,
    external_language
FROM information_schema.routines 
WHERE routine_name LIKE '%admin%'
ORDER BY routine_name;

-- 2. 週利サマリー関数の詳細テスト
SELECT '🖥️ 週利サマリー詳細テスト' as section;
SELECT 
    group_name,
    rate_display,
    nft_count,
    weekly_rate,
    weekly_rate_percent,
    has_weekly_setting,
    week_start_date
FROM get_admin_weekly_rates_summary()
ORDER BY daily_rate_limit;

-- 3. 週利設定履歴の確認
SELECT '📊 週利設定履歴' as section;
SELECT 
    group_name,
    week_start_date,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM get_weekly_rates_for_admin()
ORDER BY week_start_date DESC, group_name;

-- 4. グループ情報の確認
SELECT '🎯 グループ情報確認' as section;
SELECT 
    group_name,
    daily_rate_limit,
    nft_count,
    description
FROM get_daily_rate_groups_for_admin()
ORDER BY daily_rate_limit;

-- 5. システム状況の確認
SELECT '💻 システム状況' as section;
SELECT 
    active_user_nfts,
    total_user_nfts,
    active_nfts,
    current_week_rates,
    is_weekday,
    day_of_week
FROM get_system_status_for_admin();

-- 6. 管理画面表示予想
SELECT '🖥️ 管理画面表示予想' as section;
SELECT 
    '週利管理ページに以下が表示されます：' as message
UNION ALL
SELECT 
    '- ' || group_name || ' (' || rate_display || '): ' ||
    CASE 
        WHEN has_weekly_setting THEN '週利' || weekly_rate_percent || '%設定済み'
        ELSE '未設定'
    END
FROM get_admin_weekly_rates_summary()
ORDER BY message;

-- 7. エラーチェック
SELECT '🔍 エラーチェック' as section;
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM get_admin_weekly_rates_summary()) >= 5
        THEN '✅ 成功：関数が正常に動作'
        ELSE '❌ 失敗：関数に問題あり'
    END as function_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM group_weekly_rates) >= 5
        THEN '✅ 成功：週利設定が存在'
        ELSE '❌ 失敗：週利設定が不足'
    END as data_status;

-- 8. 最終メッセージ
SELECT '🎉 最終確認' as section;
SELECT 
    '型エラーが修正されました。管理画面をリロードしてください。' as message,
    'ブラウザのキャッシュもクリアすることを推奨します。' as tip,
    '週利管理ページで6つのグループ全てに2.6%設定を確認できるはずです。' as expected_result;

-- 9. 直接的な週利設定確認
SELECT '📋 直接的な週利設定確認' as section;
SELECT 
    drg.group_name,
    drg.daily_rate_limit * 100 || '%' as daily_rate,
    gwr.weekly_rate * 100 || '%' as weekly_rate,
    gwr.week_start_date,
    '設定済み' as status
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE
ORDER BY drg.daily_rate_limit;

-- 10. 管理画面用の最終クエリテスト
SELECT '🚀 管理画面用最終クエリ' as section;
WITH weekly_summary AS (
    SELECT * FROM get_admin_weekly_rates_summary()
)
SELECT 
    group_name as "グループ名",
    rate_display as "日利上限",
    nft_count as "NFT数",
    weekly_rate_percent || '%' as "週利設定",
    CASE 
        WHEN has_weekly_setting THEN '✅'
        ELSE '❌'
    END as "設定状況"
FROM weekly_summary
ORDER BY daily_rate_limit;
