-- 2/10の週にグループ別週利を設定

-- 2/10の週にグループ別週利を設定（例）
SELECT '=== 2/10の週 グループ別週利設定例 ===' as title;

-- 各グループに異なる週利を設定する例
SELECT 'Group-based weekly rate setting for 2025-02-10 week' as info;

-- 実際の設定コマンド例（コメントアウト）
/*
SELECT * FROM set_group_weekly_rate('2025-02-10', '0.5%グループ', 1.5);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.0%グループ', 2.0);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.25%グループ', 2.3);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.5%グループ', 2.6);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.75%グループ', 2.9);
SELECT * FROM set_group_weekly_rate('2025-02-10', '2.0%グループ', 3.2);
*/

-- または全グループ一括設定（基準週利2.6%で自動調整）
-- SELECT * FROM set_all_groups_weekly_rate('2025-02-10', 2.6);

-- 設定確認用
SELECT 'Use these commands to set and check:' as instructions;
SELECT 'set_group_weekly_rate(date, group_name, weekly_rate)' as function_1;
SELECT 'set_all_groups_weekly_rate(date, base_rate)' as function_2;
SELECT 'check_weekly_rate(date)' as function_3;
SELECT 'list_configured_weeks()' as function_4;
