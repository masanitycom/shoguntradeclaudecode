-- 🚨 緊急診断実行

-- 1. システム診断実行
SELECT 
    check_name as "チェック項目",
    status as "状態",
    count_value as "件数",
    details as "詳細"
FROM emergency_system_diagnosis()
ORDER BY check_name;

-- 2. 2月10日データ確認
SELECT 
    data_type as "データ種別",
    found as "存在",
    count_value as "件数",
    sample_data as "サンプル"
FROM check_february_10_data()
ORDER BY data_type;

-- 3. システム状況JSON確認
SELECT 
    get_system_status() as "システム状況JSON";

-- 4. 週利設定JSON確認
SELECT 
    json_array_length(get_weekly_rates_with_groups()) as "週利設定レコード数";

-- 5. 診断結果サマリー
SELECT 
    json_build_object(
        '診断結果', '=== 緊急診断完了 ===',
        '2月10日状況', 
        CASE 
            WHEN EXISTS(SELECT 1 FROM group_weekly_rates WHERE week_start_date = '2025-02-10') 
            THEN '2月10日設定済み' 
            ELSE '2月10日未設定' 
        END,
        'グループ状況',
        CASE 
            WHEN EXISTS(SELECT 1 FROM daily_rate_groups) 
            THEN 'グループ設定済み' 
            ELSE 'グループ未設定' 
        END
    ) as "診断サマリー";
