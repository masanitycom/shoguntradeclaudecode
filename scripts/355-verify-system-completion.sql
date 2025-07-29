-- システム完成度確認

-- 1. NFTグループ分布の最終確認
SELECT 
    '✅ NFTグループ分布（最終確認）' as status,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE 'その他'
    END as group_name,
    ROUND(daily_rate_limit * 100, 2) || '%' as daily_rate_limit,
    COUNT(*) as nft_count,
    ROUND(AVG(price), 0) as avg_price,
    MIN(price) || '～' || MAX(price) as price_range
FROM nfts 
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 2. 週利システムの動作確認
SELECT 
    '🎯 週利システム動作確認' as status,
    group_name,
    ROUND(weekly_rate * 100, 2) || '%' as weekly_rate,
    CASE WHEN monday_rate = 0 THEN '休' ELSE ROUND(monday_rate * 100, 2) || '%' END as mon,
    CASE WHEN tuesday_rate = 0 THEN '休' ELSE ROUND(tuesday_rate * 100, 2) || '%' END as tue,
    CASE WHEN wednesday_rate = 0 THEN '休' ELSE ROUND(wednesday_rate * 100, 2) || '%' END as wed,
    CASE WHEN thursday_rate = 0 THEN '休' ELSE ROUND(thursday_rate * 100, 2) || '%' END as thu,
    CASE WHEN friday_rate = 0 THEN '休' ELSE ROUND(friday_rate * 100, 2) || '%' END as fri
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY group_name;

-- 3. ユーザーNFT保有状況確認
SELECT 
    '👥 ユーザーNFT保有状況' as status,
    COUNT(DISTINCT user_id) as total_users,
    COUNT(*) as total_user_nfts,
    ROUND(AVG(investment_amount), 2) as avg_investment,
    SUM(CASE WHEN total_received >= investment_amount * 3 THEN 1 ELSE 0 END) as completed_nfts,
    ROUND(SUM(total_received), 2) as total_rewards_paid
FROM user_nfts
WHERE is_active = true;

-- 4. 日利計算システム準備状況
SELECT 
    '⚙️ 日利計算システム準備状況' as status,
    'calculate_daily_rewards_batch' as function_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'calculate_daily_rewards_batch'
        ) THEN '✅ 準備完了'
        ELSE '❌ 未準備'
    END as status_detail;

-- 5. 管理画面アクセス確認
SELECT 
    '🔐 管理者アカウント確認' as status,
    username,
    email,
    CASE WHEN is_admin THEN '✅ 管理者' ELSE '❌ 一般' END as role,
    created_at::date as created_date
FROM users
WHERE is_admin = true
ORDER BY created_at;

-- 6. システム全体の健全性チェック
SELECT 
    '🏥 システム健全性チェック' as status,
    'テーブル整合性' as check_type,
    CASE 
        WHEN (SELECT COUNT(*) FROM users WHERE auth_id IS NULL) = 0 
        AND (SELECT COUNT(*) FROM user_nfts WHERE user_id NOT IN (SELECT id FROM users)) = 0
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit IS NULL) = 0
        THEN '✅ 正常'
        ELSE '⚠️ 要確認'
    END as result;

-- 7. Phase 1 完成度サマリー
SELECT 
    '🎊 Phase 1 完成度サマリー' as status,
    '基盤システム' as phase,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE is_active = true) >= 20
        AND (SELECT COUNT(*) FROM users WHERE is_admin = true) >= 1
        AND (SELECT COUNT(*) FROM daily_rate_groups) = 6
        AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'calculate_daily_rewards_batch')
        THEN '✅ 完成'
        ELSE '🔄 進行中'
    END as completion_status,
    '週利管理システム、NFT管理、ユーザー管理、日利計算' as implemented_features;
