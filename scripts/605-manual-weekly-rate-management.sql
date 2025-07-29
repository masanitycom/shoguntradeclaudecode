-- 手動週利管理システム

-- 利用可能なグループ確認
SELECT 'Available Groups:' as info;
SELECT * FROM show_available_groups();

-- 現在設定済みの週確認
SELECT 'Currently Configured Weeks:' as info;
SELECT * FROM list_configured_weeks();

-- バックアップ一覧確認
SELECT 'Available Backups:' as info;
SELECT * FROM list_weekly_rates_backups();

-- ========================================
-- 手動設定用コマンド集
-- ========================================

-- 【1. 事前バックアップ作成】
-- 設定前に必ずバックアップを作成してください
-- SELECT * FROM create_weekly_rates_backup('2025-02-10', '2/10週設定前バックアップ');

-- 【2. グループ別週利設定】
-- 各グループの週利を個別に設定
/*
SELECT * FROM set_group_weekly_rate('2025-02-10', '0.5%グループ', 1.5);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.0%グループ', 2.0);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.25%グループ', 2.3);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.5%グループ', 2.6);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.75%グループ', 2.9);
SELECT * FROM set_group_weekly_rate('2025-02-10', '2.0%グループ', 3.2);
*/

-- 【3. 設定確認】
-- SELECT * FROM check_weekly_rate('2025-02-10');

-- 【4. 間違えた場合の削除】
-- SELECT * FROM delete_weekly_rates_with_backup('2025-02-10', '設定ミスのため削除');

-- 【5. バックアップからの復元】
-- SELECT * FROM restore_weekly_rates_from_backup('2025-02-10');

-- 【6. 特定週のバックアップ詳細確認】
-- SELECT * FROM show_backup_details('2025-02-10');

-- ========================================
-- 使用例
-- ========================================

-- 例1: 2/10の週に設定する場合
/*
-- Step 1: バックアップ作成
SELECT * FROM create_weekly_rates_backup('2025-02-10', '2/10週設定開始');

-- Step 2: 各グループ設定
SELECT * FROM set_group_weekly_rate('2025-02-10', '0.5%グループ', 1.5);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.0%グループ', 2.0);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.25%グループ', 2.3);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.5%グループ', 2.6);
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.75%グループ', 2.9);
SELECT * FROM set_group_weekly_rate('2025-02-10', '2.0%グループ', 3.2);

-- Step 3: 設定確認
SELECT * FROM check_weekly_rate('2025-02-10');
*/

-- 例2: 間違えて削除する場合
/*
SELECT * FROM delete_weekly_rates_with_backup('2025-02-10', '設定値が間違っていたため削除');
*/

-- 例3: バックアップから復元する場合
/*
SELECT * FROM restore_weekly_rates_from_backup('2025-02-10');
*/

SELECT 'Manual weekly rate management system ready' as status;
