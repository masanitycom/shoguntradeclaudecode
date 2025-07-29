-- 最終システム完成確認

-- 1. 全体システム状況
SELECT 
    '🎯 全体システム状況' as section,
    (SELECT COUNT(*) FROM nfts) as total_nfts,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) as nft_rate_groups,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) as weekly_rate_settings,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM user_nfts) as user_nft_holdings;

-- 2. 各グループの詳細分析
WITH group_analysis AS (
    SELECT 
        daily_rate_limit,
        COUNT(*) as nft_count,
        COUNT(CASE WHEN is_special THEN 1 END) as special_count,
        COUNT(CASE WHEN NOT is_special THEN 1 END) as normal_count,
        STRING_AGG(
            CASE WHEN is_special THEN name END, 
            ', ' ORDER BY name
        ) as special_nfts,
        STRING_AGG(
            CASE WHEN NOT is_special THEN name END, 
            ', ' ORDER BY name
        ) as normal_nfts
    FROM nfts 
    GROUP BY daily_rate_limit
)
SELECT 
    '📊 グループ詳細分析' as section,
    (daily_rate_limit * 100) || '%グループ' as group_name,
    nft_count,
    special_count,
    normal_count,
    COALESCE(special_nfts, 'なし') as special_nfts,
    COALESCE(normal_nfts, 'なし') as normal_nfts
FROM group_analysis
ORDER BY daily_rate_limit;

-- 3. 週利設定と対応確認
SELECT 
    '📅 週利設定対応確認' as section,
    gwr.daily_rate_limit,
    (gwr.daily_rate_limit * 100) || '%グループ' as group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    COUNT(n.id) as corresponding_nfts
FROM group_weekly_rates gwr
LEFT JOIN nfts n ON n.daily_rate_limit = gwr.daily_rate_limit
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)
GROUP BY gwr.daily_rate_limit, gwr.weekly_rate, gwr.monday_rate, gwr.tuesday_rate, gwr.wednesday_rate, gwr.thursday_rate, gwr.friday_rate
ORDER BY gwr.daily_rate_limit;

-- 4. 仕様書適合性確認
SELECT 
    '✅ 仕様書適合性確認' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.005) = 5 
        THEN '✅ 0.5%グループ: 5種類（仕様書通り）'
        ELSE '❌ 0.5%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.005) || '種類（要修正）'
    END as group_0_5_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.0125) = 2 
        THEN '✅ 1.25%グループ: 2種類（仕様書通り）'
        ELSE '❌ 1.25%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.0125) || '種類（要修正）'
    END as group_1_25_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.015) = 1 
        THEN '✅ 1.5%グループ: 1種類（仕様書通り）'
        ELSE '❌ 1.5%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.015) || '種類（要修正）'
    END as group_1_5_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.02) = 1 
        THEN '✅ 2.0%グループ: 1種類（仕様書通り）'
        ELSE '❌ 2.0%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.02) || '種類（要修正）'
    END as group_2_0_status;

-- 5. 最終成功判定
SELECT 
    '🎉 最終成功判定' as section,
    CASE 
        WHEN (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) = 5
        AND (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) = 5
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.005) = 5
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.0125) = 2
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.015) = 1
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.02) = 1
        THEN '🎯 完全成功！全ての要件が満たされました！'
        WHEN (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) = 5
        AND (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) = 5
        THEN '✅ 基本成功！NFT分散と週利設定が完了しました！'
        ELSE '⚠️ 部分完了：一部要件が未達成です'
    END as final_result,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) as nft_groups_created,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) as weekly_settings_created,
    '🚀 Phase 2開発準備完了！' as next_phase_status;

-- 6. 管理画面表示用データ確認
SELECT 
    '🖥️ 管理画面表示用データ' as section,
    (SELECT COUNT(*) FROM user_nfts) as active_investments,
    (SELECT COUNT(*) FROM nfts) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) as current_week_settings,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) as total_groups;
