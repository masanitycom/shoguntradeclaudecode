-- 最終完全検証

-- 1. システム全体状況
SELECT 
    '🎯 システム全体状況' as section,
    (SELECT COUNT(*) FROM nfts) as total_nfts,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) as nft_groups,
    (SELECT COUNT(*) FROM group_weekly_rates) as weekly_settings,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM user_nfts) as user_holdings;

-- 2. NFTグループ詳細
SELECT 
    '📊 NFTグループ詳細' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%グループ' as group_name,
    COUNT(*) as nft_count,
    COUNT(CASE WHEN is_special THEN 1 END) as special_count,
    COUNT(CASE WHEN NOT is_special THEN 1 END) as normal_count,
    STRING_AGG(name, ', ' ORDER BY name) as nft_names
FROM nfts 
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 3. 週利設定詳細
SELECT 
    '📅 週利設定詳細' as section,
    group_id,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    week_start_date
FROM group_weekly_rates
ORDER BY created_at;

-- 4. 仕様書適合性最終確認
SELECT 
    '✅ 仕様書適合性最終確認' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.005) = 5 
        THEN '✅ 0.5%グループ: 5種類（100,200,600特別+300,500通常）'
        ELSE '❌ 0.5%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.005) || '種類'
    END as group_0_5,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.0125) = 2 
        THEN '✅ 1.25%グループ: 2種類（1000特別+10000通常）'
        ELSE '❌ 1.25%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.0125) || '種類'
    END as group_1_25,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.015) = 1 
        THEN '✅ 1.5%グループ: 1種類（30000通常）'
        ELSE '❌ 1.5%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.015) || '種類'
    END as group_1_5,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.02) = 1 
        THEN '✅ 2.0%グループ: 1種類（100000通常）'
        ELSE '❌ 2.0%グループ: ' || (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.02) || '種類'
    END as group_2_0;

-- 5. 最終成功判定
SELECT 
    '🎉 最終成功判定' as section,
    CASE 
        WHEN (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) = 5
        AND (SELECT COUNT(*) FROM group_weekly_rates) = 5
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.005) = 5
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.0125) = 2
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.015) = 1
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = 0.02) = 1
        THEN '🎯 完全成功！全ての要件が満たされました！'
        WHEN (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) = 5
        THEN '✅ NFT分散成功！週利設定も作成されました！'
        ELSE '⚠️ 部分完了'
    END as final_result,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts) as nft_groups_count,
    (SELECT COUNT(*) FROM group_weekly_rates) as weekly_settings_count,
    '🚀 SHOGUN TRADE Phase 1 完了！' as completion_status;

-- 6. 管理画面確認メッセージ
SELECT 
    '🖥️ 管理画面確認' as section,
    '管理画面の週利管理ページで以下が表示されるはずです：' as message,
    '- 5つのグループ全てに週利2.6%設定' as expected_1,
    '- 各グループの日利分散（月〜金：各0.52%）' as expected_2,
    '- NFTが正しく5つのグループに分散' as expected_3;
