-- OHTAKIYOユーザーの正しい列名で計算確認

-- 1. OHTAKIYOユーザーの基本情報確認
SELECT 
    '👤 OHTAKIYOユーザー基本情報' as info,
    u.user_id,
    u.name,
    u.email,
    u.phone
FROM users u
WHERE u.user_id = 'OHTAKIYO';

-- 2. OHTAKIYOユーザーのNFT保有状況
SELECT 
    '💎 OHTAKIYOユーザーNFT保有状況' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    '$' || un.investment_amount as 投資額,
    n.daily_rate_limit || '%' as NFT日利上限,
    un.is_active as アクティブ状態
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id = 'OHTAKIYO'
AND un.is_active = true;

-- 3. OHTAKIYOユーザーの今週収益計算
SELECT 
    '💰 OHTAKIYOユーザー今週収益計算' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    '$' || un.investment_amount as 投資額,
    n.daily_rate_limit || '%' as NFT日利上限,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as 今週設定週利,
    '$' || ROUND(un.investment_amount * gwr.weekly_rate, 2) as 今週予定収益,
    '月$' || ROUND(un.investment_amount * gwr.monday_rate, 2) || 
    ' 火$' || ROUND(un.investment_amount * gwr.tuesday_rate, 2) ||
    ' 水$' || ROUND(un.investment_amount * gwr.wednesday_rate, 2) ||
    ' 木$' || ROUND(un.investment_amount * gwr.thursday_rate, 2) ||
    ' 金$' || ROUND(un.investment_amount * gwr.friday_rate, 2) as 日別収益
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE u.user_id = 'OHTAKIYO'
AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day'
AND un.is_active = true;

-- 4. 計算検証
SELECT 
    '🔍 計算検証' as info,
    'SHOGUN NFT 100の日利上限: 0.5%' as 確認1,
    '週利1.8%設定時の理論上限: 0.5% × 5日 = 2.5%' as 確認2,
    '1.8% < 2.5%なので設定可能' as 確認3,
    '$100投資 × 1.8% = $1.80週収益' as 確認4;

-- 5. OHTAKIYOユーザーの累積収益確認
SELECT 
    '📈 OHTAKIYOユーザー累積収益状況' as info,
    u.user_id,
    u.name as ユーザー名,
    COALESCE(SUM(dr.reward_amount), 0) as 累積収益,
    un.investment_amount as 投資額,
    ROUND((un.investment_amount * 3), 2) as 収益上限_300パーセント,
    ROUND(COALESCE(SUM(dr.reward_amount), 0) / (un.investment_amount * 3) * 100, 2) || '%' as 進捗率
FROM users u
JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id = 'OHTAKIYO'
AND un.is_active = true
GROUP BY u.user_id, u.name, un.investment_amount;

-- 6. 今日の日利計算（今日が何曜日かによる）
SELECT 
    '📅 今日の日利計算' as info,
    CASE EXTRACT(dow FROM CURRENT_DATE)
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        ELSE '土日（計算対象外）'
    END as 今日,
    CASE EXTRACT(dow FROM CURRENT_DATE)
        WHEN 1 THEN ROUND(gwr.monday_rate * 100, 2) || '%'
        WHEN 2 THEN ROUND(gwr.tuesday_rate * 100, 2) || '%'
        WHEN 3 THEN ROUND(gwr.wednesday_rate * 100, 2) || '%'
        WHEN 4 THEN ROUND(gwr.thursday_rate * 100, 2) || '%'
        WHEN 5 THEN ROUND(gwr.friday_rate * 100, 2) || '%'
        ELSE '0%'
    END as 今日の日利,
    CASE EXTRACT(dow FROM CURRENT_DATE)
        WHEN 1 THEN '$' || ROUND(100 * gwr.monday_rate, 2)
        WHEN 2 THEN '$' || ROUND(100 * gwr.tuesday_rate, 2)
        WHEN 3 THEN '$' || ROUND(100 * gwr.wednesday_rate, 2)
        WHEN 4 THEN '$' || ROUND(100 * gwr.thursday_rate, 2)
        WHEN 5 THEN '$' || ROUND(100 * gwr.friday_rate, 2)
        ELSE '$0'
    END as OHTAKIYO今日の収益
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day'
AND drg.daily_rate_limit = 0.5;
