-- 最終システム検証

-- 1. NFT分布の最終確認
SELECT 
    '🎯 最終NFT分布' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(
        name || CASE WHEN is_special THEN '[特別]' ELSE '[通常]' END, 
        ', ' ORDER BY name
    ) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 2. 特定NFTの詳細確認
SELECT 
    '🔍 重要NFT詳細' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate,
    CASE WHEN is_special THEN '特別' ELSE '通常' END as type,
    updated_at
FROM nfts
WHERE name IN (
    'SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 600',
    'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000', 
    'SHOGUN NFT 30000', 'SHOGUN NFT 50000', 'SHOGUN NFT 100000'
)
AND is_active = true
ORDER BY daily_rate_limit, name;

-- 3. 週利設定の確認
SELECT 
    '📅 週利設定確認' as section,
    daily_rate_limit as group_rate,
    (daily_rate_limit * 100) || '%グループ' as group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY daily_rate_limit;

-- 4. システム状態サマリー
SELECT 
    '📊 システム状態サマリー' as section,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as total_active_nfts,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) as unique_rate_groups,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) as weekly_rate_settings,
    (SELECT COUNT(*) FROM user_nfts) as user_nft_holdings;

-- 5. 成功判定
SELECT 
    '🎉 最終成功判定' as section,
    CASE 
        WHEN (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) >= 5 
        AND (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) >= 5
        THEN '✅ 完全成功：NFT分散 + 週利設定完了！'
        WHEN (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) >= 5
        THEN '⚠️ 部分成功：NFT分散OK、週利設定要確認'
        ELSE '❌ 失敗：NFT分散されていません'
    END as final_result,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) as nft_groups,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) as weekly_settings;
