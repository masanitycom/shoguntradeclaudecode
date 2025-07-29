-- 日利計算のテスト実行

-- 1. 現在の週の日利計算を実行
CREATE OR REPLACE FUNCTION test_daily_calculation()
RETURNS TABLE(
    test_section TEXT,
    user_name TEXT,
    nft_name TEXT,
    investment_amount NUMERIC,
    daily_rate NUMERIC,
    calculated_reward NUMERIC,
    status TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    calculation_result TEXT;
BEGIN
    -- 今日の日利計算を実行
    SELECT calculate_daily_rewards_for_date(CURRENT_DATE) INTO calculation_result;
    
    -- 計算結果を返す
    RETURN QUERY
    SELECT 
        '📊 日利計算結果'::TEXT as test_section,
        u.name as user_name,
        n.name as nft_name,
        un.investment_amount,
        dr.daily_rate,
        dr.reward_amount as calculated_reward,
        '✅ 計算完了'::TEXT as status
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    WHERE dr.reward_date = CURRENT_DATE
    ORDER BY dr.reward_amount DESC
    LIMIT 10;
    
    -- 計算サマリーも返す
    RETURN QUERY
    SELECT 
        '📈 計算サマリー'::TEXT as test_section,
        format('総ユーザー数: %s', COUNT(DISTINCT un.user_id))::TEXT as user_name,
        format('総NFT数: %s', COUNT(DISTINCT dr.user_nft_id))::TEXT as nft_name,
        SUM(dr.reward_amount) as investment_amount,
        AVG(dr.daily_rate) as daily_rate,
        COUNT(*)::NUMERIC as calculated_reward,
        '✅ 正常'::TEXT as status
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    WHERE dr.reward_date = CURRENT_DATE;
END;
$$;

-- 2. テスト実行
SELECT * FROM test_daily_calculation();

-- 3. 各グループの計算結果確認
WITH group_summary AS (
    SELECT 
        drg.group_name,
        drg.daily_rate_limit,
        COUNT(dr.id) as reward_count,
        SUM(dr.reward_amount) as total_rewards,
        AVG(dr.daily_rate) as avg_daily_rate
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN nfts n ON un.nft_id = n.id
    LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    WHERE dr.reward_date = CURRENT_DATE
    GROUP BY drg.group_name, drg.daily_rate_limit
)
SELECT 
    '📋 グループ別計算結果' as section,
    COALESCE(group_name, '未分類') as group_name,
    daily_rate_limit * 100 as limit_percent,
    reward_count,
    ROUND(total_rewards, 2) as total_rewards,
    ROUND(avg_daily_rate * 100, 4) as avg_rate_percent
FROM group_summary
ORDER BY daily_rate_limit NULLS LAST;

-- 4. システム健全性確認
SELECT 
    '🔍 システム健全性確認' as section,
    'テーブル構造' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nfts' AND column_name = 'daily_rate_group_id')
        THEN '✅ NFTグループ関連OK'
        ELSE '❌ NFTグループ関連NG'
    END as nft_group_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM group_weekly_rates WHERE week_start_date <= CURRENT_DATE AND week_start_date + 6 >= CURRENT_DATE)
        THEN '✅ 今週の週利設定OK'
        ELSE '❌ 今週の週利設定NG'
    END as weekly_rates_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM daily_rewards WHERE reward_date = CURRENT_DATE)
        THEN '✅ 今日の日利計算OK'
        ELSE '❌ 今日の日利計算NG'
    END as daily_calculation_status;
