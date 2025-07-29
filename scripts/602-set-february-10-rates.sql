-- 2/10の週（2025年2月10日〜14日）のグループ別週利設定

-- 利用可能なグループを確認
SELECT * FROM show_available_groups();

-- 2/10の週設定（手動入力用テンプレート）
-- 以下のコメントを外して各グループの週利を設定してください

/*
-- 0.5%グループの週利設定
SELECT * FROM set_group_weekly_rate('2025-02-10', '0.5%グループ', 1.5);

-- 1.0%グループの週利設定  
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.0%グループ', 2.0);

-- 1.25%グループの週利設定
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.25%グループ', 2.3);

-- 1.5%グループの週利設定
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.5%グループ', 2.6);

-- 1.75%グループの週利設定
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.75%グループ', 2.9);

-- 2.0%グループの週利設定
SELECT * FROM set_group_weekly_rate('2025-02-10', '2.0%グループ', 3.2);
*/

-- 設定確認
-- SELECT * FROM check_weekly_rate('2025-02-10');

-- 設定済み週一覧確認
-- SELECT * FROM list_configured_weeks();
