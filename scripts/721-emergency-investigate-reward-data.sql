-- 緊急調査: 既存報酬データの完全調査と削除

-- 1. 現在の報酬データ状況を調査
DO $$
DECLARE
    total_rewards DECIMAL;
    unclaimed_rewards DECIMAL;
    claimed_rewards DECIMAL;
    reward_count INTEGER;
BEGIN
    -- 総報酬額
    SELECT COALESCE(SUM(reward_amount), 0) INTO total_rewards FROM daily_rewards;
    
    -- 未申請報酬
    SELECT COALESCE(SUM(reward_amount), 0) INTO unclaimed_rewards 
    FROM daily_rewards WHERE is_claimed = false;
    
    -- 申請済み報酬
    SELECT COALESCE(SUM(reward_amount), 0) INTO claimed_rewards 
    FROM daily_rewards WHERE is_claimed = true;
    
    -- 報酬レコード数
    SELECT COUNT(*) INTO reward_count FROM daily_rewards;
    
    RAISE NOTICE '=== REWARD DATA INVESTIGATION ===';
    RAISE NOTICE 'Total rewards in system: $%', total_rewards;
    RAISE NOTICE 'Unclaimed rewards: $%', unclaimed_rewards;
    RAISE NOTICE 'Claimed rewards: $%', claimed_rewards;
    RAISE NOTICE 'Total reward records: %', reward_count;
    RAISE NOTICE '================================';
END;
$$;

-- 2. ユーザー別報酬状況を確認
SELECT 
    u.name as user_name,
    u.email,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    SUM(CASE WHEN dr.is_claimed = false THEN dr.reward_amount ELSE 0 END) as unclaimed_rewards,
    SUM(CASE WHEN dr.is_claimed = true THEN dr.reward_amount ELSE 0 END) as claimed_rewards
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id
GROUP BY u.id, u.name, u.email
HAVING COUNT(dr.id) > 0
ORDER BY total_rewards DESC
LIMIT 10;

-- 3. 報酬データの日付分布を確認
SELECT 
    DATE(reward_date) as reward_date,
    COUNT(*) as record_count,
    SUM(reward_amount) as daily_total
FROM daily_rewards
GROUP BY DATE(reward_date)
ORDER BY reward_date DESC
LIMIT 20;

-- 4. NFT別報酬状況を確認
SELECT 
    un.id as user_nft_id,
    n.name as nft_name,
    u.name as user_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN users u ON un.user_id = u.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
GROUP BY un.id, n.name, u.name
HAVING COUNT(dr.id) > 0
ORDER BY total_rewards DESC
LIMIT 10;

SELECT 'Investigation completed - Check the output above' as status;
