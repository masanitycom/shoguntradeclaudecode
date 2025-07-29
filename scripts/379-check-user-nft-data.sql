-- 正しい列名でuser_nftデータを確認

-- まず実際の列名を確認してからクエリを実行
SELECT 
    '💎 全ユーザーuser_nfts詳細' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as NFT価格,
    n.daily_rate_limit as NFT日利上限,
    un.id as user_nft_id,
    un.created_at as NFT取得日,
    un.is_active as アクティブ状態
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'pigret10', 'momochan', 'kimikimi0204', 'imaima3137', 'pbcshop1', 'zenjizenjisan')
ORDER BY u.user_id;

-- 各ユーザーの日利報酬履歴確認
SELECT 
    '📈 日利報酬履歴' as info,
    u.user_id,
    u.name as ユーザー名,
    dr.reward_date as 報酬日,
    dr.reward_amount as 報酬額,
    dr.daily_rate as 適用日利,
    dr.investment_amount as 計算時投資額,
    n.name as NFT名,
    dr.created_at as 計算日時
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'pigret10', 'momochan', 'kimikimi0204', 'imaima3137', 'pbcshop1', 'zenjizenjisan')
AND dr.reward_date >= '2025-02-10'
ORDER BY u.user_id, dr.reward_date DESC;

-- NFTグループ分類確認
SELECT 
    '🎯 NFTグループ分類確認' as info,
    n.name as NFT名,
    n.price as 価格,
    n.daily_rate_limit as 日利上限,
    drg.group_name as 所属グループ,
    COUNT(un.id) as 保有ユーザー数
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
WHERE n.name LIKE '%SHOGUN%'
GROUP BY n.id, n.name, n.price, n.daily_rate_limit, drg.group_name
ORDER BY n.price;

-- 今日の日利設定確認（水曜日）
SELECT 
    '📅 今日(水曜日)の日利設定' as info,
    drg.group_name,
    drg.daily_rate_limit as グループ上限,
    gwr.wednesday_rate as 水曜日利,
    gwr.weekly_rate as 週利設定,
    gwr.week_start_date
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 累積報酬の計算（daily_rewardsから集計）
SELECT 
    '💰 累積報酬計算' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as NFT価格,
    COUNT(dr.id) as 報酬回数,
    COALESCE(SUM(dr.reward_amount), 0) as 累積報酬,
    MAX(dr.reward_date) as 最新報酬日
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'pigret10', 'momochan', 'kimikimi0204', 'imaima3137', 'pbcshop1', 'zenjizenjisan')
GROUP BY u.user_id, u.name, n.name, n.price, un.id
ORDER BY u.user_id;
