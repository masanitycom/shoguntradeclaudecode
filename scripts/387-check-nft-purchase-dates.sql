-- NFT購入日と運用開始日の詳細調査

-- 1. 主要ユーザーのNFT購入・運用開始日確認
SELECT 
    '📅 NFT購入・運用開始日確認' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    un.created_at as NFT取得日,
    un.is_active as アクティブ状態,
    CASE 
        WHEN un.created_at::date <= '2025-02-14' THEN '✅ 2/10週対象'
        ELSE '❌ 2/10週対象外'
    END as 週利対象,
    un.created_at::date as 取得日付のみ
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id, un.created_at;

-- 2. 2025-02-10週の詳細設定確認
SELECT 
    '📊 2025-02-10週の設定詳細' as info,
    drg.group_name,
    drg.daily_rate_limit as 日利上限,
    gwr.weekly_rate as 週利設定,
    gwr.monday_rate as 月曜,
    gwr.tuesday_rate as 火曜,
    gwr.wednesday_rate as 水曜,
    gwr.thursday_rate as 木曜,
    gwr.friday_rate as 金曜,
    gwr.week_start_date as 週開始日,
    gwr.week_end_date as 週終了日
FROM daily_rate_groups drg
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 3. 2025-02-10週に対象となるユーザーNFTの確認
SELECT 
    '🎯 2025-02-10週対象ユーザー確認' as info,
    COUNT(*) as 対象NFT数,
    COUNT(DISTINCT u.id) as 対象ユーザー数,
    drg.group_name,
    drg.daily_rate_limit as 日利上限
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE un.is_active = true
AND un.created_at::date <= '2025-02-14'  -- 2/10週の金曜日まで
GROUP BY drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 4. 主要ユーザーの詳細な日利報酬履歴確認
SELECT 
    '💰 主要ユーザーの報酬履歴' as info,
    u.user_id,
    u.name as ユーザー名,
    dr.reward_date as 報酬日,
    dr.reward_amount as 報酬額,
    dr.daily_rate as 適用日利,
    dr.investment_amount as 投資額,
    EXTRACT(DOW FROM dr.reward_date) as 曜日番号,
    CASE EXTRACT(DOW FROM dr.reward_date)
        WHEN 1 THEN '月曜'
        WHEN 2 THEN '火曜'
        WHEN 3 THEN '水曜'
        WHEN 4 THEN '木曜'
        WHEN 5 THEN '金曜'
    END as 曜日
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id, dr.reward_date;

-- 5. 2025-02-10週の実際の計算実行状況確認
SELECT 
    '📈 2025-02-10週の計算実行状況' as info,
    dr.reward_date as 計算日,
    COUNT(*) as 処理件数,
    SUM(dr.reward_amount) as 総報酬額,
    AVG(dr.reward_amount) as 平均報酬,
    EXTRACT(DOW FROM dr.reward_date) as 曜日番号,
    CASE EXTRACT(DOW FROM dr.reward_date)
        WHEN 1 THEN '月曜'
        WHEN 2 THEN '火曜'
        WHEN 3 THEN '水曜'
        WHEN 4 THEN '木曜'
        WHEN 5 THEN '金曜'
    END as 曜日
FROM daily_rewards dr
WHERE dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14'
GROUP BY dr.reward_date
ORDER BY dr.reward_date;

-- 6. NFT購入申請の状況確認
SELECT 
    '📝 NFT購入申請状況' as info,
    u.user_id,
    u.name as ユーザー名,
    npa.nft_id,
    n.name as NFT名,
    npa.status as 申請状態,
    npa.created_at as 申請日,
    npa.approved_at as 承認日
FROM nft_purchase_applications npa
JOIN users u ON npa.user_id = u.id
JOIN nfts n ON npa.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id, npa.created_at;
