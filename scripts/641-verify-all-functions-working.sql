-- すべての関数が正常に動作することを確認

-- 1. 基本関数テスト
SELECT '🧪 基本関数テスト開始' as section;

-- show_available_groups関数
SELECT 'Testing show_available_groups...' as test;
SELECT group_name, nft_count FROM show_available_groups();

-- get_system_status関数
SELECT 'Testing get_system_status...' as test;
SELECT total_users, active_nfts, current_week_rates FROM get_system_status();

-- get_weekly_rates_with_groups関数
SELECT 'Testing get_weekly_rates_with_groups...' as test;
SELECT id, week_start_date, group_name, weekly_rate 
FROM get_weekly_rates_with_groups() 
LIMIT 5;

-- get_backup_list関数
SELECT 'Testing get_backup_list...' as test;
SELECT week_start_date, backup_reason, group_count 
FROM get_backup_list() 
LIMIT 3;

-- 2. 管理機能テスト
SELECT '⚙️ 管理機能テスト' as section;

-- バックアップ作成テスト
SELECT 'Testing admin_create_backup...' as test;
SELECT * FROM admin_create_backup('2025-02-17'::DATE, 'テスト用バックアップ');

-- 週利設定テスト
SELECT 'Testing set_group_weekly_rate...' as test;
SELECT * FROM set_group_weekly_rate('2025-02-17'::DATE, '1.5%グループ', 2.6);

-- 3. データ整合性確認
SELECT '🔍 データ整合性確認' as section;

-- 2月10日週の設定確認
SELECT 
    'February 10 week configuration' as check_type,
    COUNT(*) as configured_groups,
    AVG(weekly_rate * 100) as avg_weekly_rate_percent
FROM group_weekly_rates 
WHERE week_start_date = '2025-02-10'::DATE;

-- グループとNFTの関連確認
SELECT 
    'Group-NFT relationship' as check_type,
    COUNT(DISTINCT drg.id) as total_groups,
    COUNT(DISTINCT n.id) as total_nfts
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit;

-- 4. エラーチェック
SELECT '❌ エラーチェック' as section;

-- 存在しないグループでのテスト
SELECT 'Testing with non-existent group...' as test;
SELECT * FROM set_group_weekly_rate('2025-02-17'::DATE, '存在しないグループ', 2.0);

-- 無効な日付でのテスト
SELECT 'Testing with invalid date (not Monday)...' as test;
SELECT * FROM set_group_weekly_rate('2025-02-11'::DATE, '1.5%グループ', 2.0);

-- 5. 最終確認
SELECT '✅ 全関数動作確認完了' as final_status;

SELECT 
    '📊 システム準備状況' as summary,
    (SELECT COUNT(*) FROM daily_rate_groups) as total_groups,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = '2025-02-10') as feb10_settings,
    (SELECT COUNT(*) FROM group_weekly_rates_backup) as backup_records,
    '管理画面利用可能' as ui_status;
