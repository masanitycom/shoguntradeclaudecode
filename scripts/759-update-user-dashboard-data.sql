-- ユーザーダッシュボードデータの更新と確認

-- 1. ユーザーの総合統計を更新
UPDATE users 
SET 
    total_investment = user_stats.total_investment,
    total_earned = user_stats.total_earned,
    active_nft_count = user_stats.active_nft_count,
    updated_at = NOW()
FROM (
    SELECT 
        un.user_id,
        SUM(un.purchase_price) as total_investment,
        SUM(un.total_earned) as total_earned,
        COUNT(un.id) as active_nft_count
    FROM user_nfts un
    WHERE un.is_active = true
    GROUP BY un.user_id
) user_stats
WHERE users.id = user_stats.user_id;

-- 2. 今日の報酬申請可能ユーザーの確認
SELECT 
    '=== 報酬申請可能ユーザー ===' as section,
    u.name as user_name,
    SUM(dr.reward_amount) as claimable_amount,
    COUNT(dr.id) as reward_count,
    u.total_earned as total_earned_overall
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
WHERE dr.reward_date = '2025-02-10'
AND dr.is_claimed = false
GROUP BY u.id, u.name, u.total_earned
HAVING SUM(dr.reward_amount) >= 50  -- 最低申請額50ドル
ORDER BY claimable_amount DESC;

-- 3. ユーザー別の詳細統計
SELECT 
    '=== ユーザー別詳細統計 ===' as section,
    u.name as user_name,
    u.total_investment,
    u.total_earned,
    u.active_nft_count,
    COALESCE(today_rewards.daily_reward, 0) as today_reward,
    CASE 
        WHEN u.total_investment > 0 THEN 
            ROUND((u.total_earned / u.total_investment * 100)::numeric, 2)
        ELSE 0 
    END as roi_percentage
FROM users u
LEFT JOIN (
    SELECT 
        dr.user_id,
        SUM(dr.reward_amount) as daily_reward
    FROM daily_rewards dr
    WHERE dr.reward_date = '2025-02-10'
    GROUP BY dr.user_id
) today_rewards ON u.id = today_rewards.user_id
WHERE u.total_investment > 0
ORDER BY today_reward DESC
LIMIT 20;

-- 4. NFT別のパフォーマンス確認
SELECT 
    '=== NFT別パフォーマンス ===' as section,
    n.name as nft_name,
    n.price as nft_price,
    n.daily_rate_limit,
    drg.group_name,
    COUNT(un.id) as active_count,
    SUM(un.purchase_price) as total_investment,
    AVG(dr.reward_amount) as avg_daily_reward,
    SUM(dr.reward_amount) as total_daily_rewards
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id AND dr.reward_date = '2025-02-10'
WHERE un.is_active = true
GROUP BY n.id, n.name, n.price, n.daily_rate_limit, drg.group_name
ORDER BY total_daily_rewards DESC;

-- 5. 管理画面用の統計データ作成
CREATE OR REPLACE VIEW admin_dashboard_stats AS
SELECT 
    'system_overview' as stat_type,
    jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM users WHERE total_investment > 0),
        'active_nfts', (SELECT COUNT(*) FROM user_nfts WHERE is_active = true),
        'total_investment', (SELECT SUM(total_investment) FROM users),
        'total_earned', (SELECT SUM(total_earned) FROM users),
        'today_rewards', (
            SELECT COALESCE(SUM(reward_amount), 0) 
            FROM daily_rewards 
            WHERE reward_date = CURRENT_DATE
        ),
        'pending_applications', (
            SELECT COUNT(*) 
            FROM nft_purchase_applications 
            WHERE status = 'pending'
        )
    ) as stats
UNION ALL
SELECT 
    'nft_performance' as stat_type,
    jsonb_agg(
        jsonb_build_object(
            'nft_name', nft_name,
            'active_count', active_count,
            'total_investment', total_investment,
            'daily_rewards', daily_rewards
        )
    ) as stats
FROM (
    SELECT 
        n.name as nft_name,
        COUNT(un.id) as active_count,
        SUM(un.purchase_price) as total_investment,
        COALESCE(SUM(dr.reward_amount), 0) as daily_rewards
    FROM nfts n
    LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
    LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id AND dr.reward_date = CURRENT_DATE
    GROUP BY n.id, n.name
    ORDER BY daily_rewards DESC
) nft_stats;

-- 6. 結果確認
SELECT 
    '=== ダッシュボード更新完了 ===' as section,
    'ユーザーデータ更新完了' as message,
    NOW() as updated_at;

-- 7. 管理画面統計の確認
SELECT 
    '=== 管理画面統計確認 ===' as section,
    stat_type,
    stats
FROM admin_dashboard_stats;
