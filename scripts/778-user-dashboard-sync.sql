-- ユーザーダッシュボードのデータ同期

-- 1. ユーザーの累計データを更新
UPDATE users SET 
    total_nft_value = COALESCE((
        SELECT SUM(un.purchase_price)
        FROM user_nfts un
        WHERE un.user_id = users.id
    ), 0),
    total_rewards = COALESCE((
        SELECT SUM(dr.reward_amount)
        FROM daily_rewards dr
        JOIN user_nfts un ON dr.user_nft_id = un.id
        WHERE un.user_id = users.id
    ), 0),
    updated_at = NOW()
WHERE is_admin = false;

-- 2. 今日の報酬合計を確認
SELECT 
    '今日の報酬合計' as summary_type,
    COUNT(*) as reward_count,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_amount
FROM daily_rewards
WHERE reward_date = CURRENT_DATE;

-- 3. ユーザー別今日の報酬
SELECT 
    u.username,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as today_rewards,
    u.total_rewards as cumulative_rewards
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id AND dr.reward_date = CURRENT_DATE
WHERE u.is_admin = false
GROUP BY u.id, u.username, u.total_rewards
ORDER BY today_rewards DESC NULLS LAST;

-- 完了メッセージ
SELECT 'User dashboard data synchronized' as status;
