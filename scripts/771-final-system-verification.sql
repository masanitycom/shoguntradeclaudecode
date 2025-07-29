-- 最終システム検証

-- 1. システム全体の状態確認
SELECT 
    '=== システム状態確認 ===' as section,
    'ユーザー数: ' || (SELECT COUNT(*) FROM users) as user_count,
    'アクティブNFT数: ' || (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nft_count,
    'グループ数: ' || (SELECT COUNT(*) FROM daily_rate_groups) as group_count,
    '週利設定数: ' || (SELECT COUNT(*) FROM group_weekly_rates) as weekly_rate_count,
    '日利報酬数: ' || (SELECT COUNT(*) FROM daily_rewards) as daily_reward_count;

-- 2. 各ユーザーの日利報酬詳細
SELECT 
    '=== ユーザー別日利報酬 ===' as section,
    u.name as user_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_daily_reward,
    AVG(dr.reward_amount) as avg_reward,
    u.total_earned as user_total_earned
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = '2025-02-10'
GROUP BY u.id, u.name, u.total_earned
ORDER BY total_daily_reward DESC NULLS LAST;

-- 3. NFT別の報酬詳細
SELECT 
    '=== NFT別報酬詳細 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    drg.group_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.reward_amount) as avg_reward
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id AND dr.reward_date = '2025-02-10'
WHERE n.is_active = true
GROUP BY n.id, n.name, n.daily_rate_limit, drg.group_name
ORDER BY n.daily_rate_limit, total_rewards DESC NULLS LAST;

-- 4. 週利設定と実際の計算結果の比較
SELECT 
    '=== 週利設定vs実際の計算 ===' as section,
    gwr.group_name,
    (gwr.monday_rate * 100)::numeric(5,3) as expected_monday_rate_percent,
    COALESCE((dr_summary.avg_rate * 100)::numeric(5,3), 0) as actual_avg_rate_percent,
    COALESCE(dr_summary.reward_count, 0) as actual_reward_count,
    COALESCE(dr_summary.total_amount, 0) as actual_total_amount
FROM group_weekly_rates gwr
LEFT JOIN (
    SELECT 
        drg.group_name,
        AVG(dr.daily_rate) as avg_rate,
        COUNT(dr.id) as reward_count,
        SUM(dr.reward_amount) as total_amount
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    WHERE dr.reward_date = '2025-02-10'
    GROUP BY drg.group_name
) dr_summary ON gwr.group_name = dr_summary.group_name
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY gwr.group_name;

-- 5. 管理画面用の統計データ
SELECT 
    '=== 管理画面統計 ===' as section,
    '総ユーザー数' as metric,
    COUNT(*)::text as value
FROM users
UNION ALL
SELECT 
    '=== 管理画面統計 ===' as section,
    'アクティブユーザー数' as metric,
    COUNT(DISTINCT dr.user_id)::text as value
FROM daily_rewards dr
WHERE dr.reward_date = '2025-02-10'
UNION ALL
SELECT 
    '=== 管理画面統計 ===' as section,
    '本日の総報酬額' as metric,
    COALESCE(SUM(dr.reward_amount), 0)::text || '円' as value
FROM daily_rewards dr
WHERE dr.reward_date = '2025-02-10'
UNION ALL
SELECT 
    '=== 管理画面統計 ===' as section,
    '平均報酬額' as metric,
    COALESCE(AVG(dr.reward_amount), 0)::numeric(10,2)::text || '円' as value
FROM daily_rewards dr
WHERE dr.reward_date = '2025-02-10';

-- 6. エラーチェック
SELECT 
    '=== エラーチェック ===' as section,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ 日利報酬が0件です'
        WHEN COUNT(*) > 0 THEN '✅ 日利報酬が正常に計算されています (' || COUNT(*) || '件)'
    END as status
FROM daily_rewards
WHERE reward_date = '2025-02-10';

SELECT 
    '=== エラーチェック ===' as section,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ 週利設定がありません'
        WHEN COUNT(*) > 0 THEN '✅ 週利設定が存在します (' || COUNT(*) || '件)'
    END as status
FROM group_weekly_rates
WHERE week_start_date = '2025-02-10';

SELECT 
    '=== エラーチェック ===' as section,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ アクティブNFTがありません'
        WHEN COUNT(*) > 0 THEN '✅ アクティブNFTが存在します (' || COUNT(*) || '件)'
    END as status
FROM user_nfts
WHERE is_active = true;

SELECT '✅ 最終システム検証完了' as status;
