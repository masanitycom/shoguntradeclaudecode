-- ユーザーの合計データを更新

-- 1. user_nftsテーブルのtotal_earnedを更新
UPDATE user_nfts 
SET total_earned = total_earned + dr.reward_amount,
    updated_at = NOW()
FROM daily_rewards dr
WHERE user_nfts.id = dr.user_nft_id
AND dr.reward_date = '2025-02-10';

-- 2. usersテーブルの統計を更新
UPDATE users 
SET total_earned = COALESCE((
    SELECT SUM(total_earned) 
    FROM user_nfts 
    WHERE user_id = users.id 
    AND is_active = true
), 0),
total_investment = COALESCE((
    SELECT SUM(purchase_price) 
    FROM user_nfts 
    WHERE user_id = users.id 
    AND is_active = true
), 0),
active_nft_count = COALESCE((
    SELECT COUNT(*) 
    FROM user_nfts 
    WHERE user_id = users.id 
    AND is_active = true
), 0),
updated_at = NOW();

-- 3. 更新結果の確認
SELECT 
    '=== ユーザー統計更新結果 ===' as section,
    u.name as user_name,
    u.active_nft_count,
    u.total_investment,
    u.total_earned,
    (u.total_earned / NULLIF(u.total_investment, 0) * 100)::numeric(5,2) as return_percent
FROM users u
WHERE u.total_earned > 0
ORDER BY u.total_earned DESC
LIMIT 15;

-- 4. システム全体の統計
SELECT 
    '=== システム全体統計 ===' as section,
    COUNT(DISTINCT u.id) as total_users_with_rewards,
    SUM(u.active_nft_count) as total_active_nfts,
    SUM(u.total_investment) as total_investment,
    SUM(u.total_earned) as total_earned,
    (SUM(u.total_earned) / NULLIF(SUM(u.total_investment), 0) * 100)::numeric(5,2) as overall_return_percent
FROM users u
WHERE u.active_nft_count > 0;

SELECT '✅ ユーザー統計更新完了' as status;
