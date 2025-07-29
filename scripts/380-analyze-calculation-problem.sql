-- 計算問題の分析

-- 1. 投資額がどこに保存されているか確認
-- NFTの価格 = 投資額の可能性
SELECT 
    '🔍 投資額の特定' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as NFT価格_投資額候補,
    n.daily_rate_limit as 日利上限
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137')  -- $100と$1000の代表例
ORDER BY u.user_id;

-- 2. 正しい日利計算のテスト
WITH calculation_test AS (
    SELECT 
        u.user_id,
        u.name,
        n.name as nft_name,
        n.price as investment_amount,
        n.daily_rate_limit / 100.0 as nft_daily_limit,
        COALESCE(gwr.wednesday_rate, 0) as todays_setting,
        LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0) as applied_rate,
        n.price * LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0) as calculated_reward
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id AND gwr.week_start_date = '2025-02-10'
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137')
)
SELECT 
    '🧮 正しい計算テスト' as info,
    user_id,
    name as ユーザー名,
    nft_name as NFT,
    '$' || investment_amount as 投資額,
    ROUND(nft_daily_limit * 100, 2) || '%' as NFT上限,
    ROUND(todays_setting * 100, 2) || '%' as 今日設定,
    ROUND(applied_rate * 100, 2) || '%' as 適用日利,
    '$' || ROUND(calculated_reward, 2) as 計算結果,
    CASE 
        WHEN user_id = 'OHTAKIYO' AND calculated_reward != 1.00 THEN '❌ OHTAKIYOが$1.00でない'
        WHEN user_id = 'imaima3137' AND calculated_reward = 1.00 THEN '❌ $1000投資で$1.00は異常'
        ELSE '✅ 要確認'
    END as 判定
FROM calculation_test;

-- 3. 実際のdaily_rewardsテーブルの最新データ確認
SELECT 
    '📊 実際の報酬データ' as info,
    u.user_id,
    dr.reward_date,
    dr.reward_amount,
    dr.daily_rate,
    dr.investment_amount,
    dr.created_at
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137')
AND dr.reward_date >= '2025-06-01'  -- 最近のデータ
ORDER BY u.user_id, dr.reward_date DESC
LIMIT 10;

-- 4. 問題の特定
SELECT 
    '⚠️ 問題パターンの特定' as info,
    'すべてのユーザーが$1.00の報酬' as 現象,
    '投資額に関係なく固定値' as 問題,
    '計算関数または設定に問題あり' as 推定原因;
