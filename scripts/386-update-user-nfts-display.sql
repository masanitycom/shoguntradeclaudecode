-- user_nftsテーブルのtotal_earnedを正しい値に更新

-- 1. 現在のuser_nftsの状態確認
SELECT 
    '📊 現在のuser_nfts状態' as info,
    COUNT(*) as 総NFT数,
    COUNT(CASE WHEN total_earned > 0 THEN 1 END) as 報酬ありNFT数,
    SUM(total_earned) as 総報酬額,
    AVG(total_earned) as 平均報酬
FROM user_nfts 
WHERE is_active = true;

-- 2. daily_rewardsとuser_nftsの整合性チェック
SELECT 
    '🔍 整合性チェック' as info,
    un.id as user_nft_id,
    u.name as ユーザー名,
    n.name as NFT名,
    un.total_earned as 表示報酬,
    COALESCE(SUM(dr.reward_amount), 0) as 実際報酬,
    CASE 
        WHEN ABS(un.total_earned - COALESCE(SUM(dr.reward_amount), 0)) < 0.01 THEN '✅ 一致'
        ELSE '❌ 不一致'
    END as 状態
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE un.is_active = true
GROUP BY un.id, u.name, n.name, un.total_earned
HAVING ABS(un.total_earned - COALESCE(SUM(dr.reward_amount), 0)) > 0.01
ORDER BY u.name
LIMIT 20;

-- 3. user_nftsのtotal_earnedを正しい値に更新
UPDATE user_nfts 
SET total_earned = (
    SELECT COALESCE(SUM(dr.reward_amount), 0)
    FROM daily_rewards dr
    WHERE dr.user_nft_id = user_nfts.id
),
updated_at = NOW()
WHERE is_active = true;

-- 4. 更新結果の確認
SELECT 
    '✅ 更新完了' as info,
    COUNT(*) as 更新件数,
    SUM(total_earned) as 新しい総報酬額,
    AVG(total_earned) as 新しい平均報酬
FROM user_nfts 
WHERE is_active = true;

-- 5. 問題のあったユーザーの確認
SELECT 
    '👥 主要ユーザーの更新結果' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    un.total_earned as 累積報酬,
    (un.total_earned / n.price * 100) as 収益率パーセント
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
AND u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id;
