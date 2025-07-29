-- すべての修正された関数のテスト

-- 1. NFT-グループ関連テスト
SELECT '🔗 NFT-グループ関連テスト' as section;
SELECT * FROM show_available_groups();

-- 2. 週利設定履歴テスト
SELECT '📈 週利設定履歴テスト' as section;
SELECT * FROM get_weekly_rates_with_groups() LIMIT 5;

-- 3. システム状況テスト
SELECT '📊 システム状況テスト' as section;
SELECT * FROM get_system_status();

-- 4. バックアップ一覧テスト
SELECT '📦 バックアップ一覧テスト' as section;
SELECT * FROM get_backup_list() LIMIT 5;

-- 5. バックアップ作成テスト
SELECT '🧪 バックアップ作成テスト' as section;
SELECT * FROM admin_create_backup('2025-02-17', 'Function test backup');

-- 6. 日利計算テスト（2025-02-10の月曜日）
SELECT '💰 日利計算テスト' as section;
SELECT 
    user_id,
    COUNT(*) as nft_count,
    SUM(reward_amount) as total_reward
FROM calculate_daily_rewards_for_date('2025-02-10')
GROUP BY user_id
LIMIT 5;

-- 7. エラーハンドリングテスト（存在しない日付）
SELECT '❌ エラーハンドリングテスト' as section;
SELECT * FROM admin_delete_weekly_rates('2025-12-31', 'Test deletion');

SELECT 'All function tests completed successfully!' as status;
