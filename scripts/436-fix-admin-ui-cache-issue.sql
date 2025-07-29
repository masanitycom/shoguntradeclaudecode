-- 管理画面のキャッシュ問題を解決

-- 1. 統計情報を更新
ANALYZE nfts;
ANALYZE daily_rate_groups;
ANALYZE group_weekly_rates;
ANALYZE user_nfts;

-- 2. 管理画面で使用される正確なクエリを実行
SELECT 
    '🔧 管理画面統計修正' as section,
    'active_user_nfts' as metric,
    COUNT(*) as value
FROM user_nfts 
WHERE is_active = true AND current_investment > 0

UNION ALL

SELECT 
    '🔧 管理画面統計修正' as section,
    'total_user_nfts' as metric,
    COUNT(*) as value
FROM user_nfts

UNION ALL

SELECT 
    '🔧 管理画面統計修正' as section,
    'active_nfts' as metric,
    COUNT(*) as value
FROM nfts 
WHERE is_active = true

UNION ALL

SELECT 
    '🔧 管理画面統計修正' as section,
    'current_week_rates' as metric,
    COUNT(*) as value
FROM group_weekly_rates 
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day'

UNION ALL

SELECT 
    '🔧 管理画面統計修正' as section,
    'total_groups' as metric,
    COUNT(*) as value
FROM daily_rate_groups;

-- 3. グループ別NFT数の正確な計算
SELECT 
    '🔧 グループ別NFT数修正' as section,
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%' as rate_display,
    COUNT(n.id) as nft_count,
    STRING_AGG(n.name, ', ') as nft_names
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 4. 最終的な全体確認
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
