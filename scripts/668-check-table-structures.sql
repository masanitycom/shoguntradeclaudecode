-- テーブル構造を確認
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('users', 'user_nfts', 'daily_rewards', 'group_weekly_rates', 'group_weekly_rates_backup')
ORDER BY table_name, ordinal_position;

-- ユーザー数確認
SELECT COUNT(*) as user_count FROM users;

-- NFT数確認  
SELECT COUNT(*) as nft_count FROM user_nfts WHERE is_active = true;

-- 日利報酬確認
SELECT COUNT(*) as reward_count FROM daily_rewards;

-- 週利設定確認
SELECT COUNT(DISTINCT week_start_date) as week_count FROM group_weekly_rates;
