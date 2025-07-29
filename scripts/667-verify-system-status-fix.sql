-- システム状況関数の動作確認

-- 1. 関数が正常に作成されているか確認
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'get_system_status';

-- 2. 実際のデータを確認
SELECT 'ユーザー数' as metric, COUNT(*) as value FROM users WHERE email IS NOT NULL
UNION ALL
SELECT 'アクティブNFT数', COUNT(*) FROM user_nfts WHERE is_active = true
UNION ALL
SELECT '日利報酬数', COUNT(*) FROM daily_rewards
UNION ALL
SELECT '週利設定数', COUNT(DISTINCT week_start_date) FROM group_weekly_rates
UNION ALL
SELECT 'バックアップ数', COUNT(DISTINCT week_start_date) FROM group_weekly_rates_backup;

-- 3. 関数の実行テスト
SELECT * FROM get_system_status();

-- 4. エラーがないか確認
DO $$
BEGIN
    PERFORM get_system_status();
    RAISE NOTICE 'システム状況関数は正常に動作しています';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'エラー: %', SQLERRM;
END;
$$;
