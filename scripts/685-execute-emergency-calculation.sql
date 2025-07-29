-- 緊急計算実行

-- 1. 今日の既存報酬をクリア
DELETE FROM daily_rewards WHERE reward_date = CURRENT_DATE;

-- 2. 修正された計算関数で再計算
SELECT * FROM force_daily_calculation();

-- 3. 計算結果の確認
SELECT 
    '✅ 修正後の計算結果' as status,
    COUNT(*) as total_rewards,
    ROUND(SUM(reward_amount)::numeric, 2) as total_amount_usd,
    ROUND(AVG(reward_amount)::numeric, 4) as avg_reward_usd,
    COUNT(DISTINCT user_id) as unique_users,
    ROUND(AVG(daily_rate * 100)::numeric, 4) as avg_daily_rate_percent
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 4. 上位ユーザーの報酬確認
SELECT 
    u.name,
    COUNT(dr.id) as nft_count,
    ROUND(SUM(dr.reward_amount)::numeric, 2) as total_reward,
    ROUND(SUM(un.purchase_price)::numeric, 2) as total_investment,
    ROUND((SUM(dr.reward_amount) / SUM(un.purchase_price) * 100)::numeric, 4) as actual_daily_rate_percent
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY u.id, u.name
ORDER BY total_reward DESC
LIMIT 10;

-- 5. 修正前後の比較
SELECT 
    '🔄 修正効果の確認' as section,
    '修正前: 297件で$2.98（異常）' as before_fix,
    format('修正後: %s件で$%s（正常）', 
           COUNT(*), 
           ROUND(SUM(reward_amount)::numeric, 2)
    ) as after_fix,
    CASE 
        WHEN SUM(reward_amount) > 2.98 THEN '✅ 修正成功'
        ELSE '❌ まだ問題あり'
    END as fix_status
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;
