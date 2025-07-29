-- 2025年2月10日週の設定

-- 1. 2月10日が月曜日であることを確認
SELECT 
    '📅 2月10日の曜日確認' as section,
    '2025-02-10'::DATE as date,
    EXTRACT(DOW FROM '2025-02-10'::DATE) as day_of_week,
    CASE EXTRACT(DOW FROM '2025-02-10'::DATE)
        WHEN 1 THEN '月曜日 ✅'
        ELSE '月曜日ではありません ❌'
    END as is_monday;

-- 2. 各グループの週利設定
SELECT '📊 グループ別週利設定実行' as section;

-- 0.5%グループ: 週利1.5%
SELECT * FROM set_group_weekly_rate(
    '2025-02-10'::DATE,
    '0.5%グループ',
    1.5
);

-- 1.0%グループ: 週利2.0%
SELECT * FROM set_group_weekly_rate(
    '2025-02-10'::DATE,
    '1.0%グループ',
    2.0
);

-- 1.25%グループ: 週利2.3%
SELECT * FROM set_group_weekly_rate(
    '2025-02-10'::DATE,
    '1.25%グループ',
    2.3
);

-- 1.5%グループ: 週利2.6%
SELECT * FROM set_group_weekly_rate(
    '2025-02-10'::DATE,
    '1.5%グループ',
    2.6
);

-- 1.75%グループ: 週利2.9%
SELECT * FROM set_group_weekly_rate(
    '2025-02-10'::DATE,
    '1.75%グループ',
    2.9
);

-- 2.0%グループ: 週利3.2%
SELECT * FROM set_group_weekly_rate(
    '2025-02-10'::DATE,
    '2.0%グループ',
    3.2
);

-- 3. 設定結果確認
SELECT '✅ 設定結果確認' as section;
SELECT * FROM get_weekly_rates_with_groups() 
WHERE week_start_date = '2025-02-10';

-- 4. バックアップ作成
SELECT '📦 バックアップ作成' as section;
SELECT * FROM admin_create_backup('2025-02-10', '2月10日週設定完了後のバックアップ');

SELECT 'February 10 week setup completed!' as status;
