-- 現在設定されている週利を確認

SELECT '=== 現在の週利設定確認 ===' as section;

SELECT 
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 3) as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 3) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 3) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 3) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 3) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 3) as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.group_name;

-- NFTとグループの対応確認
SELECT '=== NFTグループ対応 ===' as section;

SELECT 
    n.name,
    n.price,
    n.daily_rate_limit,
    drg.group_name
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
ORDER BY n.name;

-- ユーザーNFT状況
SELECT '=== ユーザーNFT状況 ===' as section;

SELECT 
    u.email,
    u.name,
    n.name as nft_name,
    un.purchase_price,
    un.operation_start_date,
    drg.group_name
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE u.is_admin = false
ORDER BY u.email, n.name;
