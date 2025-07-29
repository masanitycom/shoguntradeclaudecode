-- バックアップシステムのテスト

-- 1. 利用可能なグループ確認
SELECT 'Available Groups:' as info;
SELECT * FROM show_available_groups();

-- 2. 現在設定済みの週確認
SELECT 'Currently Configured Weeks:' as info;
SELECT * FROM list_configured_weeks();

-- 3. バックアップ一覧確認
SELECT 'Available Backups:' as info;
SELECT * FROM get_backup_list();

-- 4. システム状況確認
SELECT 'System Status:' as info;
SELECT * FROM get_system_status();

-- 5. テスト用バックアップ作成（既存データがある場合）
DO $$
DECLARE
    test_date DATE := '2025-02-03'; -- 先週の月曜日
    existing_count INTEGER;
BEGIN
    -- 既存データがあるかチェック
    SELECT COUNT(*) INTO existing_count
    FROM group_weekly_rates 
    WHERE week_start_date = test_date;
    
    IF existing_count > 0 THEN
        RAISE NOTICE 'Testing backup creation for %', test_date;
        PERFORM admin_create_backup(test_date);
        RAISE NOTICE 'Backup test completed';
    ELSE
        RAISE NOTICE 'No existing data found for % - skipping backup test', test_date;
    END IF;
END;
$$;

-- 6. バックアップ後の状況確認
SELECT 'After Backup Test:' as info;
SELECT * FROM get_backup_list() LIMIT 5;

SELECT 'Backup system test completed' as status;
