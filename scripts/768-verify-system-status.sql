-- システム状態の最終確認

-- 1. 日利計算結果の確認
SELECT 
    '=== 日利計算結果 ===' as section,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward,
    COUNT(DISTINCT user_id) as unique_users
FROM daily_rewards
WHERE reward_date = '2025-02-10';

-- 2. ユーザーダッシュボード用統計
SELECT 
    '=== ユーザー統計 ===' as section,
    COUNT(DISTINCT u.id) as total_users,
    COUNT(DISTINCT CASE WHEN un.is_active = true THEN u.id END) as active_users,
    SUM(CASE WHEN un.is_active = true THEN un.purchase_price ELSE 0 END) as total_investment,
    SUM(u.total_earned) as total_earned
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id;

-- 3. NFT統計
SELECT 
    '=== NFT統計 ===' as section,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
    SUM(purchase_price) as total_investment
FROM user_nfts;

-- 4. 週利設定状況
SELECT 
    '=== 週利設定状況 ===' as section,
    week_start_date,
    COUNT(*) as group_count,
    AVG(weekly_rate * 100) as avg_weekly_rate_percent
FROM group_weekly_rates
GROUP BY week_start_date
ORDER BY week_start_date DESC
LIMIT 5;

-- 5. システム健全性チェック
SELECT 
    '=== システム健全性 ===' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM daily_rewards WHERE reward_date = '2025-02-10') 
        THEN '✅ 日利計算済み'
        ELSE '❌ 日利未計算'
    END as daily_calculation_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM group_weekly_rates WHERE week_start_date = '2025-02-10')
        THEN '✅ 週利設定済み'
        ELSE '❌ 週利未設定'
    END as weekly_rate_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM user_nfts WHERE is_active = true)
        THEN '✅ アクティブNFTあり'
        ELSE '❌ アクティブNFTなし'
    END as nft_status;

SELECT '✅ システム状態確認完了' as status;
