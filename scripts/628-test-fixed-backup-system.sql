-- 修正されたバックアップシステムのテスト

-- 1. バックアップテーブル構造確認
SELECT 
    '📋 修正後バックアップテーブル構造' as section,
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup'
ORDER BY ordinal_position;

-- 2. 利用可能グループ確認
SELECT '🔗 利用可能グループ確認' as section;
SELECT * FROM show_available_groups();

-- 3. システム状況確認
SELECT '📊 システム状況確認' as section;
SELECT * FROM get_system_status();

-- 4. バックアップ一覧確認
SELECT '📦 バックアップ一覧確認' as section;
SELECT * FROM get_backup_list();

-- 5. 週利設定履歴確認
SELECT '📈 週利設定履歴確認' as section;
SELECT * FROM get_weekly_rates_with_groups();

-- 6. テスト用バックアップ作成
SELECT '🧪 テスト用バックアップ作成' as section;
SELECT * FROM admin_create_backup('2025-02-10', 'システムテスト用バックアップ');

-- 7. 作成されたバックアップ確認
SELECT '✅ 作成されたバックアップ確認' as section;
SELECT * FROM get_backup_list() WHERE week_start_date = '2025-02-10';

SELECT 'Fixed backup system test completed!' as status;
