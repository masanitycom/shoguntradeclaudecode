-- 完全修正の最終検証

DO $$
DECLARE
    debug_msg TEXT;
    special_1000_count INTEGER;
    total_nfts INTEGER;
    group_count INTEGER;
    week_settings INTEGER;
BEGIN
    debug_msg := '🔍 完全修正の最終検証開始';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 1000 (Special)の確認
    SELECT COUNT(*) INTO special_1000_count
    FROM nfts
    WHERE name = 'SHOGUN NFT 1000 (Special)'
    AND is_special = true
    AND daily_rate_limit = 0.0125
    AND is_active = true;
    
    debug_msg := '🎯 SHOGUN NFT 1000 (Special) 1.25%設定: ' || special_1000_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 全NFT数の確認
    SELECT COUNT(*) INTO total_nfts
    FROM nfts
    WHERE is_active = true;
    
    debug_msg := '📊 アクティブNFT総数: ' || total_nfts || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- グループ数の確認
    SELECT COUNT(*) INTO group_count
    FROM daily_rate_groups;
    
    debug_msg := '📊 日利グループ数: ' || group_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 今週の週利設定確認
    SELECT COUNT(*) INTO week_settings
    FROM group_weekly_rates
    WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
    
    debug_msg := '📊 今週の週利設定: ' || week_settings || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 修正状況のサマリー
    IF special_1000_count > 0 AND group_count >= 6 AND week_settings >= 6 THEN
        debug_msg := '✅ 全ての修正が完了しました！';
    ELSE
        debug_msg := '❌ まだ修正が必要です';
    END IF;
    RAISE NOTICE '%', debug_msg;
END $$;

-- 最終確認レポート
SELECT 
    '🎯 最終確認サマリー' as section,
    'NFT分類' as category,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate,
    COUNT(*) as count
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 重要NFTの個別確認
SELECT 
    '🔍 重要NFT個別確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN name = 'SHOGUN NFT 1000 (Special)' AND daily_rate_limit = 0.0125 THEN '✅ 完璧！'
        WHEN name = 'SHOGUN NFT 1000' AND daily_rate_limit = 0.010 THEN '✅ 正しい'
        WHEN name = 'SHOGUN NFT 10000' AND daily_rate_limit = 0.0125 THEN '✅ 正しい'
        WHEN name = 'SHOGUN NFT 100000' AND daily_rate_limit = 0.020 THEN '✅ 正しい'
        ELSE '❌ 要確認: ' || (daily_rate_limit * 100) || '%'
    END as status
FROM nfts
WHERE name IN ('SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 1000', 'SHOGUN NFT 10000', 'SHOGUN NFT 100000')
AND is_active = true
ORDER BY name;

-- システム全体の健全性チェック
SELECT 
    '📊 システム健全性チェック' as section,
    'アクティブNFT投資' as metric,
    COUNT(*) as value
FROM user_nfts
WHERE is_active = true AND current_investment > 0
UNION ALL
SELECT '📊 システム健全性チェック', '利用可能NFT', COUNT(*)
FROM nfts
WHERE is_active = true
UNION ALL
SELECT '📊 システム健全性チェック', '日利グループ', COUNT(*)
FROM daily_rate_groups
UNION ALL
SELECT '📊 システム健全性チェック', '今週の週利設定', COUNT(*)
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
