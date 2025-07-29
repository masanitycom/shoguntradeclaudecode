-- 全ての週利履歴をクリアするスクリプト
-- 手動で正確なデータを入力し直すため

BEGIN;

-- 削除前の件数を確認
SELECT 
    'daily_rewards' as table_name, 
    COUNT(*) as record_count 
FROM daily_rewards
UNION ALL
SELECT 
    'nft_weekly_rates' as table_name, 
    COUNT(*) as record_count 
FROM nft_weekly_rates
UNION ALL
SELECT 
    'group_weekly_rates' as table_name, 
    COUNT(*) as record_count 
FROM group_weekly_rates
UNION ALL
SELECT 
    'reward_applications' as table_name, 
    COUNT(*) as record_count 
FROM reward_applications
UNION ALL
SELECT 
    'tenka_bonus_distributions' as table_name, 
    COUNT(*) as record_count 
FROM tenka_bonus_distributions
UNION ALL
SELECT 
    'user_rank_history' as table_name, 
    COUNT(*) as record_count 
FROM user_rank_history;

-- 全ての履歴テーブルをクリア
DELETE FROM daily_rewards;
DELETE FROM nft_weekly_rates;
DELETE FROM group_weekly_rates;
DELETE FROM reward_applications;
DELETE FROM tenka_bonus_distributions;
DELETE FROM user_rank_history;

-- 削除後の確認
SELECT 
    'daily_rewards' as table_name, 
    COUNT(*) as record_count 
FROM daily_rewards
UNION ALL
SELECT 
    'nft_weekly_rates' as table_name, 
    COUNT(*) as record_count 
FROM nft_weekly_rates
UNION ALL
SELECT 
    'group_weekly_rates' as table_name, 
    COUNT(*) as record_count 
FROM group_weekly_rates
UNION ALL
SELECT 
    'reward_applications' as table_name, 
    COUNT(*) as record_count 
FROM reward_applications
UNION ALL
SELECT 
    'tenka_bonus_distributions' as table_name, 
    COUNT(*) as record_count 
FROM tenka_bonus_distributions
UNION ALL
SELECT 
    'user_rank_history' as table_name, 
    COUNT(*) as record_count 
FROM user_rank_history;

COMMIT;

-- 全ての週利履歴をクリア完了
