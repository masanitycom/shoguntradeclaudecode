-- 計算ロジックの修正

-- 1. 現在の日利計算関数を確認
SELECT 
    '🔍 現在の計算関数確認' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%daily%reward%' 
OR routine_name LIKE '%calculate%'
ORDER BY routine_name;

-- 2. 正しい日利計算の実行テスト
DO $$
DECLARE
    test_user_id UUID;
    test_nft_id UUID;
    test_investment NUMERIC := 1000;
    test_daily_rate NUMERIC := 0.005; -- 0.5%
    expected_reward NUMERIC;
    actual_calculation NUMERIC;
BEGIN
    -- テスト用データ取得
    SELECT u.id INTO test_user_id 
    FROM users u 
    WHERE u.user_id = 'imaima3137' 
    LIMIT 1;
    
    SELECT un.nft_id INTO test_nft_id
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    WHERE u.user_id = 'imaima3137'
    LIMIT 1;
    
    -- 期待値計算
    expected_reward := test_investment * test_daily_rate;
    
    -- 実際の計算
    actual_calculation := test_investment * test_daily_rate;
    
    RAISE NOTICE '📊 計算テスト結果:';
    RAISE NOTICE '投資額: $%', test_investment;
    RAISE NOTICE '日利: %％', test_daily_rate * 100;
    RAISE NOTICE '期待報酬: $%', expected_reward;
    RAISE NOTICE '実際計算: $%', actual_calculation;
    
    IF expected_reward = actual_calculation THEN
        RAISE NOTICE '✅ 計算ロジックは正常';
    ELSE
        RAISE NOTICE '❌ 計算ロジックに問題あり';
    END IF;
END $$;

-- 3. 各ユーザーの正しい報酬を再計算
WITH correct_calculations AS (
    SELECT 
        u.user_id,
        u.name,
        un.current_investment,
        n.daily_rate_limit / 100.0 as nft_daily_limit,
        gwr.wednesday_rate as todays_rate,
        LEAST(gwr.wednesday_rate, n.daily_rate_limit / 100.0) as applied_rate,
        un.current_investment * LEAST(gwr.wednesday_rate, n.daily_rate_limit / 100.0) as correct_reward
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE gwr.week_start_date = '2025-02-10'
    AND u.user_id IN ('OHTAKIYO', 'pigret10', 'momochan', 'kimikimi0204', 'imaima3137', 'pbcshop1', 'zenjizenjisan')
)
SELECT 
    '🎯 正しい報酬計算' as info,
    user_id,
    name as ユーザー名,
    '$' || current_investment as 投資額,
    ROUND(nft_daily_limit * 100, 2) || '%' as NFT上限,
    ROUND(todays_rate * 100, 2) || '%' as 今日設定,
    ROUND(applied_rate * 100, 2) || '%' as 適用日利,
    '$' || ROUND(correct_reward, 2) as 正しい報酬,
    CASE 
        WHEN current_investment = 100 AND correct_reward != 1.00 THEN '❌ $100で$1.00以外'
        WHEN current_investment = 1000 AND correct_reward = 1.00 THEN '❌ $1000で$1.00は異常'
        ELSE '✅ 計算確認必要'
    END as 判定
FROM correct_calculations
ORDER BY user_id;
