-- 全ての問題を特定して強制修正

-- 1. 現在のNFT状況を詳細確認
SELECT 
    '🔍 現在のNFT詳細状況' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN name LIKE '%1000%' AND is_special = true THEN 
            CASE WHEN daily_rate_limit = 0.0125 THEN '✅ 正しい' ELSE '❌ 要修正: ' || daily_rate_limit END
        ELSE 'その他'
    END as status
FROM nfts
WHERE is_active = true
ORDER BY price, is_special;

-- 2. 週利設定の詳細確認
SELECT 
    '🔍 週利設定詳細確認' as section,
    gwr.id,
    drg.group_name,
    gwr.week_start_date,
    gwr.weekly_rate,
    gwr.created_at
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY gwr.week_start_date DESC, drg.group_name;

-- 3. 管理画面のクエリを模擬実行
SELECT 
    '🔍 管理画面クエリ模擬' as section,
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%' as rate_display,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 4. 今週の週利設定数を確認
SELECT 
    '🔍 今週の週利設定数確認' as section,
    DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day' as expected_week_start,
    COUNT(*) as actual_count
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
