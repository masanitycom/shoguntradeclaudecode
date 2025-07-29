-- 2025-02-10週の報酬対象資格を詳細確認

-- 1. 各ユーザーのNFT取得日と購入申請状況の詳細確認
SELECT 
    '📅 NFT取得日と申請状況の詳細' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    n.daily_rate_limit as 日利上限,
    un.created_at as NFT取得日時,
    un.created_at::date as NFT取得日,
    un.is_active as アクティブ状態,
    CASE 
        WHEN un.created_at::date <= '2025-02-10' THEN '✅ 2/10(月)から対象'
        WHEN un.created_at::date <= '2025-02-11' THEN '✅ 2/11(火)から対象'
        WHEN un.created_at::date <= '2025-02-12' THEN '✅ 2/12(水)から対象'
        WHEN un.created_at::date <= '2025-02-13' THEN '✅ 2/13(木)から対象'
        WHEN un.created_at::date <= '2025-02-14' THEN '✅ 2/14(金)から対象'
        ELSE '❌ 2/10週対象外'
    END as 週利対象期間,
    '2025-02-10'::date - un.created_at::date as 取得から2月10日までの日数
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id;

-- 2. NFT購入申請の詳細履歴
SELECT 
    '📝 NFT購入申請の詳細履歴' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as 申請NFT名,
    npa.status as 申請状態,
    npa.created_at as 申請日時,
    npa.created_at::date as 申請日,
    npa.approved_at as 承認日時,
    npa.approved_at::date as 承認日,
    CASE 
        WHEN npa.approved_at IS NULL THEN '⏳ 未承認'
        WHEN npa.approved_at::date <= '2025-02-10' THEN '✅ 2/10週開始前に承認済み'
        WHEN npa.approved_at::date <= '2025-02-14' THEN '⚠️ 2/10週中に承認'
        ELSE '❌ 2/10週後に承認'
    END as 承認タイミング
FROM nft_purchase_applications npa
JOIN users u ON npa.user_id = u.id
JOIN nfts n ON npa.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id, npa.created_at;

-- 3. 2025-02-10週の各日における対象ユーザーの確認
WITH daily_eligibility AS (
    SELECT 
        u.user_id,
        u.name,
        n.name as nft_name,
        un.created_at::date as nft_date,
        calc_date.reward_date,
        CASE 
            WHEN un.created_at::date <= calc_date.reward_date THEN '✅ 対象'
            ELSE '❌ 対象外'
        END as 対象可否
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    CROSS JOIN (
        SELECT '2025-02-10'::date as reward_date, '月曜' as 曜日 UNION
        SELECT '2025-02-11'::date, '火曜' UNION
        SELECT '2025-02-12'::date, '水曜' UNION
        SELECT '2025-02-13'::date, '木曜' UNION
        SELECT '2025-02-14'::date, '金曜'
    ) calc_date
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
    AND un.is_active = true
)
SELECT 
    '📊 2025-02-10週の日別対象確認' as info,
    user_id,
    name as ユーザー名,
    nft_name as NFT名,
    nft_date as NFT取得日,
    reward_date as 計算日,
    CASE EXTRACT(DOW FROM reward_date)
        WHEN 1 THEN '月曜'
        WHEN 2 THEN '火曜'
        WHEN 3 THEN '水曜'
        WHEN 4 THEN '木曜'
        WHEN 5 THEN '金曜'
    END as 曜日,
    対象可否
FROM daily_eligibility
ORDER BY user_id, reward_date;

-- 4. 実際に計算されるべき報酬の試算
SELECT 
    '💰 計算されるべき報酬の試算' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    drg.group_name,
    calc_date.reward_date as 計算日,
    CASE EXTRACT(DOW FROM calc_date.reward_date)
        WHEN 1 THEN '月曜'
        WHEN 2 THEN '火曜'
        WHEN 3 THEN '水曜'
        WHEN 4 THEN '木曜'
        WHEN 5 THEN '金曜'
    END as 曜日,
    CASE EXTRACT(DOW FROM calc_date.reward_date)
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
    END as 適用日利,
    CASE 
        WHEN un.created_at::date <= calc_date.reward_date THEN
            n.price * CASE EXTRACT(DOW FROM calc_date.reward_date)
                WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
                WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
                WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
                WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
                WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
            END
        ELSE 0
    END as 計算される報酬額,
    CASE 
        WHEN un.created_at::date <= calc_date.reward_date THEN '✅ 対象'
        ELSE '❌ 対象外（NFT取得前）'
    END as 対象判定
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
CROSS JOIN (
    SELECT '2025-02-10'::date as reward_date UNION
    SELECT '2025-02-11'::date UNION
    SELECT '2025-02-12'::date UNION
    SELECT '2025-02-13'::date UNION
    SELECT '2025-02-14'::date
) calc_date
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
AND un.is_active = true
AND gwr.week_start_date = '2025-02-10'
ORDER BY u.user_id, calc_date.reward_date;

-- 5. 現在の報酬計算状況の確認
SELECT 
    '🔍 現在の報酬計算状況' as info,
    u.user_id,
    u.name as ユーザー名,
    dr.reward_date as 報酬日,
    dr.reward_amount as 報酬額,
    dr.daily_rate as 適用日利,
    dr.investment_amount as 投資額,
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
AND dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14'
ORDER BY u.user_id, dr.reward_date;
