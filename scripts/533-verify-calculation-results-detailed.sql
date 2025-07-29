-- 日利計算結果の詳細確認

-- 1. daily_rewardsテーブルの正確な構造を確認
SELECT 
    '📋 daily_rewards テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 最新の日利計算結果を確認
SELECT 
    '📊 最新の日利計算結果' as result_info,
    COUNT(*) as total_records,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date,
    SUM(reward_amount) as total_rewards
FROM daily_rewards
WHERE created_at >= CURRENT_DATE;

-- 3. ユーザー別の日利計算結果
SELECT 
    '👤 ユーザー別日利計算結果' as user_info,
    u.name as user_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.daily_rate) as avg_daily_rate
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
WHERE dr.created_at >= CURRENT_DATE
GROUP BY u.id, u.name
ORDER BY total_rewards DESC
LIMIT 10;

-- 4. NFT別集計
SELECT 
    '🎯 NFT別日利集計' as info,
    n.name as nft_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.daily_rate) as avg_daily_rate
FROM daily_rewards dr
INNER JOIN nfts n ON dr.nft_id = n.id
GROUP BY n.id, n.name
ORDER BY total_rewards DESC;

-- 5. user_nftsの更新状況確認
SELECT 
    '💰 user_nfts更新状況' as info,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN total_earned > 0 THEN 1 END) as nfts_with_earnings,
    SUM(total_earned) as total_all_earnings,
    AVG(total_earned) as avg_earnings,
    COUNT(CASE WHEN total_earned >= purchase_price * 3 THEN 1 END) as completed_nfts,
    COUNT(CASE WHEN total_earned >= purchase_price * 2.5 THEN 1 END) as near_completion_nfts
FROM user_nfts 
WHERE is_active = true;

-- 6. 300%キャップ状況
SELECT 
    '🎯 300%キャップ状況' as info,
    u.id,
    COALESCE(u.name, u.email, u.id::text) as user_name,
    n.name as nft_name,
    un.purchase_price,
    un.total_earned,
    ROUND((un.total_earned / un.purchase_price * 100)::numeric, 2) as completion_percentage,
    (un.purchase_price * 3 - un.total_earned) as remaining_to_cap
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
AND un.total_earned > 0
ORDER BY completion_percentage DESC
LIMIT 20;

-- 7. エラーチェック
SELECT 
    '⚠️ 重複チェック' as info,
    user_nft_id,
    reward_date,
    COUNT(*) as duplicate_count
FROM daily_rewards 
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY user_nft_id, reward_date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 8. トリガー動作確認
SELECT 
    '🔧 トリガー確認' as info,
    'check_300_percent_cap トリガー存在確認' as check_type,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'check_300_percent_cap'
    ) THEN '✅ 存在' ELSE '❌ 存在しない' END as result;
