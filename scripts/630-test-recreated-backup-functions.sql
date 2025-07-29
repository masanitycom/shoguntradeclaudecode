-- 再作成されたバックアップ関数のテスト

-- 1. バックアップテーブル構造確認
SELECT 
    '📋 バックアップテーブル構造確認' as section,
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

-- 4. 現在の週利設定確認
SELECT '📈 現在の週利設定確認' as section;
SELECT * FROM get_weekly_rates_with_groups();

-- 5. バックアップ一覧確認
SELECT '📦 バックアップ一覧確認' as section;
SELECT * FROM get_backup_list();

-- 6. テスト用バックアップ作成
SELECT '🧪 テスト用バックアップ作成' as section;
SELECT * FROM admin_create_backup('2025-02-10', 'システムテスト用バックアップ');

-- 7. 作成されたバックアップ確認
SELECT '✅ 作成されたバックアップ確認' as section;
SELECT * FROM get_backup_list() WHERE week_start_date = '2025-02-10';

-- 8. 関数の戻り値型確認
SELECT 
    '🔍 関数の戻り値型確認' as section,
    routine_name,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE 'admin_%'
ORDER BY routine_name;

SELECT 'Recreated backup functions test completed!' as status;
