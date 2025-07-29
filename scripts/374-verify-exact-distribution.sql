-- 配分結果を確認

-- 1. 全グループの配分結果確認
SELECT 
    '🎯 週利1.8%正確配分結果' as status,
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as 設定週利,
    ROUND(gwr.monday_rate * 100, 2) || '%' as 月曜,
    ROUND(gwr.tuesday_rate * 100, 2) || '%' as 火曜,
    ROUND(gwr.wednesday_rate * 100, 2) || '%' as 水曜,
    ROUND(gwr.thursday_rate * 100, 2) || '%' as 木曜,
    ROUND(gwr.friday_rate * 100, 2) || '%' as 金曜,
    ROUND((gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + 
           gwr.thursday_rate + gwr.friday_rate) * 100, 2) || '%' as 実際合計,
    CASE 
        WHEN ABS((gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + 
                  gwr.thursday_rate + gwr.friday_rate) - gwr.weekly_rate) < 0.0001 
        THEN '✅ 正確'
        ELSE '❌ 誤差あり'
    END as 検証結果
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day'
ORDER BY drg.group_name;

-- 2. SHOGUN NFT 100グループの詳細確認
SELECT 
    '📊 SHOGUN NFT 100グループ詳細' as info,
    drg.group_name,
    drg.daily_rate_limit || '%' as 日利上限,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as 週利設定,
    '月' || ROUND(gwr.monday_rate * 100, 2) || '% 火' || ROUND(gwr.tuesday_rate * 100, 2) || 
    '% 水' || ROUND(gwr.wednesday_rate * 100, 2) || '% 木' || ROUND(gwr.thursday_rate * 100, 2) || 
    '% 金' || ROUND(gwr.friday_rate * 100, 2) || '%' as 日別配分,
    '$100投資での週収益: $' || ROUND(100 * gwr.weekly_rate, 2) as 収益例
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day'
AND drg.daily_rate_limit = 0.5
ORDER BY drg.group_name;

-- 3. OHTAKIYOユーザーの計算確認
SELECT 
    '👤 OHTAKIYOユーザー計算確認' as info,
    u.display_name,
    n.name as nft_name,
    '$' || un.investment_amount as 投資額,
    drg.daily_rate_limit || '%' as nft日利上限,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as 今週設定週利,
    '$' || ROUND(un.investment_amount * gwr.weekly_rate, 2) as 今週予定収益
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE u.user_id = 'OHTAKIYO'
AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day'
AND un.is_active = true;
