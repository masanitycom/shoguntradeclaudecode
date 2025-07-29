-- 5%報酬の詳細調査

-- 1. 5%報酬を受けているユーザーの詳細分析
SELECT 
    '🔍 5%報酬の詳細分析' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as NFT価格,
    n.daily_rate_limit as NFT日利上限,
    dr.reward_amount as 報酬額,
    dr.daily_rate as 適用日利,
    dr.investment_amount as 計算時投資額,
    dr.reward_date as 報酬日,
    (dr.reward_amount / dr.investment_amount * 100) as 実際の日利パーセント,
    dr.created_at as 計算実行時刻
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE dr.reward_amount = 5.00
ORDER BY dr.created_at DESC
LIMIT 20;

-- 2. 全ての報酬パターンを分析
SELECT 
    '📊 全報酬パターン分析' as info,
    dr.reward_amount as 報酬額,
    COUNT(*) as 件数,
    MIN(dr.investment_amount) as 最小投資額,
    MAX(dr.investment_amount) as 最大投資額,
    AVG(dr.investment_amount) as 平均投資額,
    MIN(dr.daily_rate) as 最小日利,
    MAX(dr.daily_rate) as 最大日利,
    AVG(dr.daily_rate) as 平均日利,
    STRING_AGG(DISTINCT n.name, ', ') as NFT種類
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY dr.reward_amount
ORDER BY dr.reward_amount;

-- 3. 計算ロジックの検証
SELECT 
    '🧮 計算ロジック検証' as info,
    dr.investment_amount as 投資額,
    dr.daily_rate as 適用日利,
    dr.reward_amount as 実際報酬,
    (dr.investment_amount * dr.daily_rate) as 期待報酬,
    CASE 
        WHEN ABS(dr.reward_amount - (dr.investment_amount * dr.daily_rate)) < 0.01 THEN '✅ 正常'
        ELSE '❌ 異常'
    END as 計算結果,
    n.name as NFT名,
    n.daily_rate_limit as NFT上限
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
AND dr.reward_amount = 5.00
LIMIT 10;

-- 4. 今日の週利設定確認
SELECT 
    '📅 今日の週利設定確認' as info,
    CURRENT_DATE as 今日,
    EXTRACT(DOW FROM CURRENT_DATE) as 曜日番号,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as 曜日名,
    (CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE) * INTERVAL '1 day' + INTERVAL '1 day') as 今週月曜日;

-- 5. 今週の週利設定があるかチェック
WITH this_week_monday AS (
    SELECT (CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE) * INTERVAL '1 day' + INTERVAL '1 day')::DATE as monday
)
SELECT 
    '📋 今週の週利設定チェック' as info,
    twm.monday as 今週月曜日,
    drg.group_name as グループ名,
    gwr.weekly_rate as 週利設定,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
    END as 今日の日利設定,
    CASE 
        WHEN gwr.id IS NULL THEN '❌ 設定なし'
        ELSE '✅ 設定あり'
    END as 設定状況
FROM this_week_monday twm
CROSS JOIN daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id AND gwr.week_start_date = twm.monday
ORDER BY drg.daily_rate_limit;

-- 6. 固定0.5%計算の証拠を探す
SELECT 
    '🔍 固定0.5%計算の証拠' as info,
    n.name as NFT名,
    n.price as NFT価格,
    dr.reward_amount as 報酬額,
    (dr.reward_amount / n.price * 100) as 実際の日利パーセント,
    CASE 
        WHEN ABS((dr.reward_amount / n.price * 100) - 0.5) < 0.01 THEN '✅ 0.5%固定'
        ELSE '❓ その他'
    END as 判定
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY n.name, n.price, dr.reward_amount
ORDER BY n.price;

-- 7. 実際に使用されている計算関数を確認
SELECT 
    '🔧 現在の計算関数確認' as info,
    routine_name as 関数名,
    routine_definition as 関数定義の一部
FROM information_schema.routines 
WHERE routine_name LIKE '%daily_reward%' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 8. 最新の計算実行ログ
SELECT 
    '📝 最新計算実行ログ' as info,
    dr.created_at as 実行時刻,
    COUNT(*) as 処理件数,
    SUM(dr.reward_amount) as 総報酬額,
    AVG(dr.reward_amount) as 平均報酬,
    MIN(dr.reward_amount) as 最小報酬,
    MAX(dr.reward_amount) as 最大報酬
FROM daily_rewards dr
WHERE dr.reward_date = CURRENT_DATE
GROUP BY dr.created_at
ORDER BY dr.created_at DESC;
