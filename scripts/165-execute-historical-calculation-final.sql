-- 最終的な過去分計算の実行

-- 1. 既存の履歴計算データをクリア（必要に応じて）
-- DELETE FROM daily_rewards WHERE calculation_type = 'HISTORICAL_CALCULATION';

-- 2. 過去分計算を実行
SELECT * FROM calculate_nft_historical_rewards_correct(2, 19);

-- 3. 計算結果の確認
SELECT 
    'Historical calculation completed successfully' as status,
    COUNT(*) as total_daily_rewards,
    COUNT(DISTINCT user_nft_id) as unique_user_nfts,
    COUNT(DISTINCT user_id) as unique_users,
    SUM(reward_amount) as total_rewards_amount,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date
FROM daily_rewards 
WHERE calculation_type = 'HISTORICAL_CALCULATION';

-- 4. NFT別の計算結果サマリー
SELECT 
    n.name as nft_name,
    COUNT(DISTINCT dr.reward_date) as calculation_days,
    COUNT(dr.id) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    AVG(dr.reward_amount) as avg_daily_reward
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.calculation_type = 'HISTORICAL_CALCULATION'
GROUP BY n.id, n.name
ORDER BY total_amount DESC;

-- 5. SHOGUN NFT 100000の特別確認（週2-9は0%のはず）
SELECT 
    'SHOGUN NFT 100000 verification' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN dr.reward_amount = 0 THEN 1 END) as zero_rewards,
    COUNT(CASE WHEN dr.reward_amount > 0 THEN 1 END) as positive_rewards,
    MIN(dr.reward_date) as first_date,
    MAX(dr.reward_date) as last_date
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE n.name = 'SHOGUN NFT 100000'
AND dr.calculation_type = 'HISTORICAL_CALCULATION'
AND dr.reward_date BETWEEN '2025-01-13' AND '2025-03-07';  -- 週2-9の期間

SELECT 'All historical calculations completed successfully' as final_status;
