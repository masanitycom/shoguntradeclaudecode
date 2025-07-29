-- システム全体の包括的テスト（実際のテーブル構造対応版）

-- 1. 全テーブルの基本統計
SELECT '📊 システム全体統計' as section;

SELECT 
    'users' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_records,
    COUNT(CASE WHEN current_rank != 'なし' THEN 1 END) as with_rank
FROM users
UNION ALL
SELECT 
    'user_nfts' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_records,
    COUNT(CASE WHEN COALESCE(total_earned, 0) > 0 THEN 1 END) as with_earnings
FROM user_nfts
UNION ALL
SELECT 
    'nfts' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_records,
    COUNT(CASE WHEN daily_rate_limit > 0 THEN 1 END) as with_rate_limit
FROM nfts
UNION ALL
SELECT 
    'daily_rewards' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_claimed = false THEN 1 END) as unclaimed_records,
    COUNT(CASE WHEN reward_date = CURRENT_DATE THEN 1 END) as today_records
FROM daily_rewards
UNION ALL
SELECT 
    'group_weekly_rates' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE THEN 1 END) as current_week,
    COUNT(DISTINCT group_id) as unique_groups
FROM group_weekly_rates;

-- 2. 今日の日利計算結果詳細
SELECT '💰 今日の日利計算結果' as section;

SELECT 
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT nft_id) as unique_nfts,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 3. ユーザー別今日の報酬トップ10
SELECT '🏆 今日の報酬トップ10ユーザー' as section;

SELECT 
    u.name,
    u.current_rank,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as total_daily_reward,
    AVG(dr.daily_rate) * 100 as avg_daily_rate_percent,
    u.total_earned,
    u.pending_rewards
FROM users u
JOIN daily_rewards dr ON u.id = dr.user_id
WHERE dr.reward_date = CURRENT_DATE
AND u.name IS NOT NULL
GROUP BY u.id, u.name, u.current_rank, u.total_earned, u.pending_rewards
ORDER BY total_daily_reward DESC
LIMIT 10;

-- 4. NFT別今日の報酬
SELECT '🎯 NFT別今日の報酬' as section;

SELECT 
    n.name as nft_name,
    n.price,
    n.daily_rate_limit * 100 as daily_rate_limit_percent,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_reward,
    AVG(dr.daily_rate) * 100 as avg_rate_percent
FROM nfts n
JOIN daily_rewards dr ON n.id = dr.nft_id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY n.id, n.name, n.price, n.daily_rate_limit
ORDER BY total_reward DESC;

-- 5. ランク別統計
SELECT '👑 ランク別統計' as section;

SELECT 
    current_rank,
    current_rank_level,
    COUNT(*) as user_count,
    SUM(COALESCE(total_earned, 0)) as rank_total_earnings,
    AVG(COALESCE(total_earned, 0)) as rank_avg_earnings,
    SUM(COALESCE(pending_rewards, 0)) as rank_pending_rewards
FROM users 
WHERE name IS NOT NULL
GROUP BY current_rank, current_rank_level
ORDER BY current_rank_level DESC;

-- 6. 週利設定の確認
SELECT '📈 今週の週利設定' as section;

SELECT 
    drg.group_name,
    drg.daily_rate_limit * 100 as daily_rate_limit_percent,
    gwr.weekly_rate * 100 as weekly_rate_percent,
    gwr.monday_rate * 100 as monday_percent,
    gwr.tuesday_rate * 100 as tuesday_percent,
    gwr.wednesday_rate * 100 as wednesday_percent,
    gwr.thursday_rate * 100 as thursday_percent,
    gwr.friday_rate * 100 as friday_percent,
    gwr.week_start_date,
    gwr.week_end_date
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE
ORDER BY drg.daily_rate_limit;

-- 7. アクティブNFT投資の統計
SELECT '💎 アクティブNFT投資統計' as section;

SELECT 
    COUNT(*) as active_nft_investments,
    SUM(purchase_price) as total_investment,
    AVG(purchase_price) as avg_investment,
    SUM(COALESCE(total_earned, 0)) as total_earned,
    AVG(COALESCE(total_earned, 0)) as avg_earned,
    AVG(COALESCE(total_earned, 0) / purchase_price * 100) as avg_roi_percent,
    COUNT(CASE WHEN COALESCE(total_earned, 0) >= purchase_price * 3 THEN 1 END) as completed_300_percent
FROM user_nfts 
WHERE is_active = true;

-- 8. 300%達成状況
SELECT '🎯 300%達成状況' as section;

SELECT 
    u.name,
    n.name as nft_name,
    un.purchase_price,
    COALESCE(un.total_earned, 0) as total_earned,
    ROUND(COALESCE(un.total_earned, 0) / un.purchase_price * 100, 2) as roi_percent,
    CASE 
        WHEN COALESCE(un.total_earned, 0) >= un.purchase_price * 3 THEN '達成'
        ELSE '未達成'
    END as status_300_percent
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name IS NOT NULL
AND COALESCE(un.total_earned, 0) > 0
ORDER BY roi_percent DESC
LIMIT 20;

-- 9. 紹介関係の統計
SELECT '🤝 紹介関係統計' as section;

WITH referral_stats AS (
    SELECT 
        referrer_id,
        COUNT(*) as direct_referrals
    FROM users 
    WHERE referrer_id IS NOT NULL
    GROUP BY referrer_id
)
SELECT 
    u.name as referrer_name,
    u.current_rank,
    rs.direct_referrals,
    COALESCE(u.total_earned, 0) as referrer_earnings
FROM referral_stats rs
JOIN users u ON rs.referrer_id = u.id
WHERE u.name IS NOT NULL
ORDER BY rs.direct_referrals DESC, u.total_earned DESC
LIMIT 15;

-- 10. システムヘルスチェック
SELECT '🏥 システムヘルスチェック' as section;

SELECT 
    'データ整合性' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM user_nfts un
            LEFT JOIN users u ON un.user_id = u.id
            WHERE u.id IS NULL
        ) THEN '❌ 孤立したuser_nftsレコードあり'
        ELSE '✅ user_nfts整合性OK'
    END as status
UNION ALL
SELECT 
    '週利設定' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM group_weekly_rates 
            WHERE week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE
        ) THEN '✅ 今週の週利設定あり'
        ELSE '❌ 今週の週利設定なし'
    END as status
UNION ALL
SELECT 
    '今日の日利計算' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM daily_rewards 
            WHERE reward_date = CURRENT_DATE
        ) THEN '✅ 今日の日利計算済み'
        ELSE '❌ 今日の日利計算未実行'
    END as status
UNION ALL
SELECT 
    'ランク設定' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE current_rank IS NOT NULL 
            AND current_rank != 'なし'
        ) THEN '✅ ランク設定済みユーザーあり'
        ELSE '❌ ランク未設定'
    END as status;

-- 11. 最終ステータス
SELECT 
    '✅ システム全体テスト完了' as final_status,
    NOW() as test_completed_at,
    EXTRACT(DOW FROM CURRENT_DATE) as current_day_of_week,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '平日（計算可能）'
        ELSE '土日（計算不可）'
    END as calculation_status;
