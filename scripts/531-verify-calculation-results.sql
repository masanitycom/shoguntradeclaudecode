-- 日利計算結果の確認

-- 1. 今日の日利計算結果
SELECT 
    '📊 今日の日利計算結果' as info,
    COUNT(*) as total_records,
    SUM(reward_amount) as total_rewards,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 2. ユーザー別の今日の報酬
SELECT 
    '👤 ユーザー別今日の報酬' as info,
    u.id,
    COALESCE(u.name, u.email, u.id::text) as user_name,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as total_reward
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = CURRENT_DATE
GROUP BY u.id, u.name, u.email
HAVING COUNT(dr.id) > 0
ORDER BY total_reward DESC
LIMIT 10;

-- 3. 過去1週間の日利推移
SELECT 
    '📈 過去1週間の日利推移' as info,
    reward_date,
    COUNT(*) as record_count,
    SUM(reward_amount) as daily_total,
    AVG(reward_amount) as daily_average
FROM daily_rewards 
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY reward_date
ORDER BY reward_date DESC;

-- 4. NFT別の報酬状況（nft_idカラムが存在する場合）
SELECT 
    '🎯 NFT別報酬状況' as info,
    n.name as nft_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.reward_amount) as avg_reward
FROM nfts n
LEFT JOIN daily_rewards dr ON n.id = dr.nft_id AND dr.reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY n.id, n.name
HAVING COUNT(dr.id) > 0
ORDER BY total_rewards DESC;

-- 5. user_nftsの更新状況確認
SELECT 
    '💰 user_nfts更新状況' as info,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN total_earned > 0 THEN 1 END) as nfts_with_earnings,
    SUM(total_earned) as total_all_earnings,
    AVG(total_earned) as avg_earnings,
    COUNT(CASE WHEN total_earned >= purchase_price * 3 THEN 1 END) as completed_nfts
FROM user_nfts 
WHERE is_active = true;

-- 6. エラーチェック
SELECT 
    '⚠️ エラーチェック' as info,
    'daily_rewards テーブル存在確認' as check_type,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_rewards') 
         THEN '✅ 存在' 
         ELSE '❌ 存在しない' 
    END as result;

SELECT 
    '⚠️ エラーチェック' as info,
    'group_weekly_rates テーブル存在確認' as check_type,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates') 
         THEN '✅ 存在' 
         ELSE '❌ 存在しない' 
    END as result;

SELECT 
    '⚠️ エラーチェック' as info,
    'daily_rate_groups テーブル存在確認' as check_type,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_rate_groups') 
         THEN '✅ 存在' 
         ELSE '❌ 存在しない' 
    END as result;
