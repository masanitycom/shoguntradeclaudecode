-- 削除前のデータ復旧のためのヒント収集

-- daily_rewardsテーブルからNFT情報を推測
SELECT 
    dr.user_id,
    u.name,
    u.user_id as user_login_id,
    COUNT(*) as reward_days,
    MIN(dr.business_date) as first_reward_date,
    MAX(dr.business_date) as last_reward_date,
    SUM(dr.daily_amount) as total_rewards
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
GROUP BY dr.user_id, u.name, u.user_id
HAVING COUNT(*) > 0
ORDER BY u.name;