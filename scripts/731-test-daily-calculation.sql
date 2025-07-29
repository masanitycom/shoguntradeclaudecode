-- 🧪 日利計算システムのテスト実行

-- 1. 現在の設定状況を確認
SELECT '=== 現在の週利設定 ===' as section;
SELECT week_start_date, group_name, weekly_rate, monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
FROM group_weekly_rates 
ORDER BY week_start_date DESC, group_name;

-- 2. アクティブなユーザーNFTを確認
SELECT '=== アクティブNFT確認 ===' as section;
SELECT 
    un.id as user_nft_id,
    u.name as user_name,
    n.name as nft_name,
    n.price,
    n.daily_rate_limit,
    drg.group_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE un.is_active = true
ORDER BY u.name, n.name
LIMIT 10;

-- 3. 今日の日利計算をテスト実行
SELECT '=== 日利計算テスト実行 ===' as section;
SELECT * FROM force_daily_calculation();

-- 4. 計算結果を確認
SELECT '=== 計算結果確認 ===' as section;
SELECT 
    dr.reward_date,
    u.name as user_name,
    n.name as nft_name,
    dr.reward_amount,
    dr.is_claimed
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY u.name, n.name
LIMIT 20;

-- 5. ユーザーの合計報酬を確認
SELECT '=== ユーザー合計報酬確認 ===' as section;
SELECT 
    u.name as user_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_pending_rewards
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE dr.is_claimed = false
GROUP BY u.id, u.name
ORDER BY total_pending_rewards DESC
LIMIT 10;

SELECT '🧪 日利計算テスト完了' as status;
