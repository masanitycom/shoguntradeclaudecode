-- システム状況の総合確認

SELECT '=== SHOGUN TRADE SYSTEM STATUS SUMMARY ===' as section;

-- 1. ユーザー統計
SELECT 'USER STATISTICS:' as category;
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN email LIKE '%@shogun-trade.com%' THEN 1 END) as shogun_domain_users,
    COUNT(CASE WHEN phone = '000-0000-0000' THEN 1 END) as test_phone_users,
    COUNT(CASE WHEN name LIKE 'ユーザー%' OR name LIKE '%UP' THEN 1 END) as abnormal_name_users
FROM users;

-- 2. NFT保有状況
SELECT 'NFT OWNERSHIP:' as category;
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    COUNT(DISTINCT user_id) as users_with_nft,
    COUNT(*) as total_active_nfts
FROM user_nfts
WHERE is_active = true;

-- 3. 運用開始日の状況
SELECT 'OPERATION START DATES:' as category;
SELECT 
    CASE EXTRACT(DOW FROM operation_start_date)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name,
    COUNT(*) as count
FROM user_nfts
WHERE operation_start_date IS NOT NULL
  AND is_active = true
GROUP BY EXTRACT(DOW FROM operation_start_date)
ORDER BY EXTRACT(DOW FROM operation_start_date);

-- 4. NFT別の日利上限確認
SELECT 'NFT DAILY RATE LIMITS:' as category;
SELECT 
    name,
    daily_rate_limit,
    price,
    is_special
FROM nfts
ORDER BY price;

-- 5. 報酬データ状況
SELECT 'REWARD DATA:' as category;
SELECT 
    COUNT(*) as total_daily_rewards,
    COUNT(DISTINCT user_id) as users_with_rewards,
    MIN(reward_date) as earliest_reward,
    MAX(reward_date) as latest_reward
FROM daily_rewards;

-- 6. 問題のあるデータの確認
SELECT 'POTENTIAL ISSUES:' as category;
SELECT 
    'Users with test patterns' as issue_type,
    COUNT(*) as count
FROM users
WHERE name LIKE 'ユーザー%' 
   OR name LIKE '%UP'
   OR name LIKE 'テストユーザー%'
   OR phone = '000-0000-0000'
UNION ALL
SELECT 
    'NFTs with $0.00 total_earned but should have rewards' as issue_type,
    COUNT(*) as count
FROM user_nfts un
WHERE un.is_active = true
  AND un.total_earned = 0
  AND un.operation_start_date IS NOT NULL
  AND un.operation_start_date < CURRENT_DATE;

SELECT '=== SYSTEM STATUS SUMMARY COMPLETE ===' as status;