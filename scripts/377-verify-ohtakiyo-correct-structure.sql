-- OHTAKIYOユーザーの正しい構造で検証

-- 1. OHTAKIYOユーザーの基本情報確認
SELECT 
    '👤 OHTAKIYOユーザー基本情報' as info,
    u.user_id,
    u.name,
    u.email,
    u.phone
FROM users u
WHERE u.user_id = 'OHTAKIYO';

-- 2. OHTAKIYOユーザーのuser_nfts詳細確認
SELECT 
    '💎 OHTAKIYOユーザーuser_nfts詳細' as info,
    u.user_id,
    u.name as ユーザー名,
    un.*
FROM users u
JOIN user_nfts un ON u.id = un.user_id
WHERE u.user_id = 'OHTAKIYO';

-- 3. OHTAKIYOユーザーのNFT情報確認
SELECT 
    '🎯 OHTAKIYOユーザーNFT情報' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as NFT価格,
    n.daily_rate_limit as NFT日利上限,
    un.is_active as アクティブ状態
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id = 'OHTAKIYO';

-- 4. 現在の週利設定確認
SELECT 
    '📊 現在の週利設定' as info,
    drg.group_name,
    drg.daily_rate_limit as 日利上限,
    gwr.weekly_rate as 週利設定,
    gwr.monday_rate as 月曜,
    gwr.tuesday_rate as 火曜,
    gwr.wednesday_rate as 水曜,
    gwr.thursday_rate as 木曜,
    gwr.friday_rate as 金曜,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + 
     gwr.thursday_rate + gwr.friday_rate) as 実際合計
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day'
OR gwr.week_start_date IS NULL
ORDER BY drg.daily_rate_limit;

-- 5. OHTAKIYOユーザーの累積収益確認
SELECT 
    '📈 OHTAKIYOユーザー累積収益' as info,
    u.user_id,
    u.name as ユーザー名,
    COUNT(dr.id) as 報酬記録数,
    COALESCE(SUM(dr.reward_amount), 0) as 累積収益
FROM users u
JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id = 'OHTAKIYO'
GROUP BY u.user_id, u.name;

-- 6. 今日の曜日と対応する日利確認
SELECT 
    '📅 今日の日利計算' as info,
    CURRENT_DATE as 今日の日付,
    CASE EXTRACT(dow FROM CURRENT_DATE)
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日（計算対象外）'
        WHEN 0 THEN '日曜日（計算対象外）'
    END as 今日の曜日,
    EXTRACT(dow FROM CURRENT_DATE) as 曜日番号;
