-- システム全体の動作確認

-- 1. 全テーブル構造確認
SELECT '📋 主要テーブル構造確認' as section;

SELECT 
    'group_weekly_rates' as table_name,
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
UNION ALL
SELECT 
    'group_weekly_rates_backup' as table_name,
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup'
ORDER BY table_name, ordinal_position;

-- 2. 全関数確認
SELECT '🔧 利用可能関数確認' as section;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE 'admin_%' OR routine_name LIKE 'get_%' OR routine_name LIKE 'show_%')
ORDER BY routine_name;

-- 3. システム状況
SELECT '📊 システム状況' as section;
SELECT * FROM get_system_status();

-- 4. 週利設定履歴
SELECT '📈 週利設定履歴' as section;
SELECT * FROM get_weekly_rates_with_groups();

-- 5. バックアップ履歴
SELECT '📦 バックアップ履歴' as section;
SELECT * FROM get_backup_list();

-- 6. 利用可能グループ
SELECT '🔗 利用可能グループ' as section;
SELECT * FROM show_available_groups();

-- 7. 削除テスト（テスト用データで）
SELECT '🧪 削除機能テスト' as section;
SELECT * FROM admin_delete_weekly_rates('2025-02-10');

-- 8. 復元テスト
SELECT '🔄 復元機能テスト' as section;
SELECT * FROM admin_restore_from_backup('2025-02-10');

-- 9. 最終確認
SELECT '✅ 最終システム確認' as section;
SELECT * FROM get_weekly_rates_with_groups() WHERE week_start_date = '2025-02-10';

SELECT 'Complete system verification finished!' as status;
