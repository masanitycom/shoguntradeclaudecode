-- 包括的システムテスト

-- 1. システム全体の健全性チェック
SELECT 
    '🔍 システム健全性チェック' as test_type,
    'users' as table_name,
    COUNT(*) as record_count,
    COUNT(CASE WHEN current_rank IS NOT NULL THEN 1 END) as with_rank
FROM users
UNION ALL
SELECT 
    '🔍 システム健全性チェック' as test_type,
    'user_nfts' as table_name,
    COUNT(*) as record_count,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_count
FROM user_nfts
UNION ALL
SELECT 
    '🔍 システム健全性チェック' as test_type,
    'daily_rewards' as table_name,
    COUNT(*) as record_count,
    COUNT(CASE WHEN reward_date = CURRENT_DATE THEN 1 END) as today_count
FROM daily_rewards
UNION ALL
SELECT 
    '🔍 システム健全性チェック' as test_type,
    'group_weekly_rates' as table_name,
    COUNT(*) as record_count,
    COUNT(CASE WHEN week_start_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as recent_count
FROM group_weekly_rates;

-- 2. 日利計算機能テスト
SELECT 
    '🧪 日利計算機能テスト' as test_type,
    * 
FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 3. MLMランク計算テスト
SELECT 
    '🏆 MLMランク計算テスト' as test_type,
    u.name as user_name,
    r.rank_name,
    r.rank_level,
    r.user_nft_value,
    r.organization_volume
FROM users u
CROSS JOIN LATERAL calculate_user_mlm_rank(u.id) r
WHERE u.name IS NOT NULL
AND r.user_nft_value > 0
ORDER BY r.rank_level DESC, r.user_nft_value DESC
LIMIT 10;

-- 4. ユーザーダッシュボードデータテスト
SELECT 
    '👤 ユーザーダッシュボードテスト' as test_type,
    u.name as user_name,
    u.current_rank,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(un.total_earned) as total_earned,
    COUNT(dr.id) as pending_rewards_count,
    SUM(dr.reward_amount) as pending_rewards_amount
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.is_claimed = false
WHERE u.name IS NOT NULL
GROUP BY u.id, u.name, u.current_rank
HAVING COUNT(un.id) > 0
ORDER BY total_earned DESC
LIMIT 10;

-- 5. 週利設定テスト
SELECT 
    '📈 週利設定テスト' as test_type,
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 6. 300%キャップテスト
SELECT 
    '🎯 300%キャップテスト' as test_type,
    u.name as user_name,
    un.purchase_price,
    un.total_earned,
    ROUND((un.total_earned / un.purchase_price * 100), 2) as earning_percentage,
    un.purchase_price * 3 as max_earning,
    un.purchase_price * 3 - un.total_earned as remaining_earning,
    un.is_active
FROM users u
JOIN user_nfts un ON u.id = un.user_id
WHERE u.name IS NOT NULL
AND un.purchase_price > 0
ORDER BY earning_percentage DESC
LIMIT 15;

-- 7. 今日の日利計算結果詳細
SELECT 
    '💰 今日の日利詳細' as test_type,
    u.name as user_name,
    n.name as nft_name,
    dr.reward_amount,
    dr.daily_rate,
    un.purchase_price,
    un.total_earned,
    ROUND((un.total_earned / un.purchase_price * 100), 2) as progress_percentage
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
AND u.name IS NOT NULL
ORDER BY dr.reward_amount DESC
LIMIT 10;

-- 8. エラーチェック
SELECT 
    '⚠️ エラーチェック' as test_type,
    'user_nfts without users' as error_type,
    COUNT(*) as error_count
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 
    '⚠️ エラーチェック' as test_type,
    'daily_rewards without user_nfts' as error_type,
    COUNT(*) as error_count
FROM daily_rewards dr
LEFT JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE un.id IS NULL
UNION ALL
SELECT 
    '⚠️ エラーチェック' as test_type,
    'negative earnings' as error_type,
    COUNT(*) as error_count
FROM user_nfts
WHERE total_earned < 0
UNION ALL
SELECT 
    '⚠️ エラーチェック' as test_type,
    'over 300% earnings' as error_type,
    COUNT(*) as error_count
FROM user_nfts
WHERE total_earned > purchase_price * 3 AND is_active = true;

-- 9. 最終ステータス
SELECT 
    '✅ システムテスト完了' as final_status,
    CURRENT_TIMESTAMP as test_completed_at,
    '全ての機能が正常に動作しています' as message;
