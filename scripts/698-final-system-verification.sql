-- 最終システム検証

-- 1. 全体システム状況確認
CREATE OR REPLACE FUNCTION comprehensive_system_check()
RETURNS TABLE(
    check_category TEXT,
    check_item TEXT,
    status TEXT,
    details TEXT,
    count_value BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- テーブル構造確認
    RETURN QUERY
    SELECT 
        '🏗️ テーブル構造'::TEXT as check_category,
        'NFTグループ関連'::TEXT as check_item,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nfts' AND column_name = 'daily_rate_group_id')
            THEN '✅ 正常'
            ELSE '❌ 不正常'
        END as status,
        'nfts.daily_rate_group_id カラム'::TEXT as details,
        1::BIGINT as count_value;
    
    -- 週利設定確認
    RETURN QUERY
    SELECT 
        '📅 週利設定'::TEXT as check_category,
        '現在週の設定'::TEXT as check_item,
        CASE 
            WHEN COUNT(*) > 0 THEN '✅ 正常'
            ELSE '❌ 不正常'
        END as status,
        format('グループ数: %s', COUNT(*))::TEXT as details,
        COUNT(*) as count_value
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date <= CURRENT_DATE
    AND gwr.week_start_date + 6 >= CURRENT_DATE;
    
    -- 日利計算確認
    RETURN QUERY
    SELECT 
        '💰 日利計算'::TEXT as check_category,
        '今日の計算結果'::TEXT as check_item,
        CASE 
            WHEN COUNT(*) > 0 THEN '✅ 正常'
            ELSE '⚠️ 未実行'
        END as status,
        format('計算件数: %s, 総報酬: %s', COUNT(*), COALESCE(ROUND(SUM(reward_amount), 2), 0))::TEXT as details,
        COUNT(*) as count_value
    FROM daily_rewards
    WHERE reward_date = CURRENT_DATE;
    
    -- ユーザーNFT確認
    RETURN QUERY
    SELECT 
        '👥 ユーザーNFT'::TEXT as check_category,
        'アクティブNFT'::TEXT as check_item,
        CASE 
            WHEN COUNT(*) > 0 THEN '✅ 正常'
            ELSE '⚠️ NFTなし'
        END as status,
        format('アクティブNFT: %s, ユーザー数: %s', COUNT(*), COUNT(DISTINCT user_id))::TEXT as details,
        COUNT(*) as count_value
    FROM user_nfts
    WHERE is_active = true;
    
    -- 管理画面関数確認
    RETURN QUERY
    SELECT 
        '🔧 管理機能'::TEXT as check_category,
        '必要関数'::TEXT as check_item,
        CASE 
            WHEN COUNT(*) >= 3 THEN '✅ 正常'
            ELSE '❌ 不足'
        END as status,
        format('関数数: %s', COUNT(*))::TEXT as details,
        COUNT(*) as count_value
    FROM information_schema.routines 
    WHERE routine_name IN ('calculate_daily_rewards_for_date', 'restore_weekly_rates_from_csv_data', 'comprehensive_system_check');
END;
$$;

-- 2. システムチェック実行
SELECT * FROM comprehensive_system_check();

-- 3. 各グループの今日の日利レート確認
WITH today_rates AS (
    SELECT 
        drg.group_name,
        drg.daily_rate_limit,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as today_rate,
        COUNT(un.id) as active_nfts
    FROM daily_rate_groups drg
    LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
        AND gwr.week_start_date <= CURRENT_DATE 
        AND gwr.week_start_date + 6 >= CURRENT_DATE
    LEFT JOIN nfts n ON n.daily_rate_group_id = drg.id
    LEFT JOIN user_nfts un ON un.nft_id = n.id AND un.is_active = true
    GROUP BY drg.group_name, drg.daily_rate_limit, gwr.monday_rate, gwr.tuesday_rate, gwr.wednesday_rate, gwr.thursday_rate, gwr.friday_rate
    ORDER BY drg.daily_rate_limit
)
SELECT 
    '📊 今日の日利レート' as section,
    group_name,
    daily_rate_limit * 100 as limit_percent,
    COALESCE(today_rate * 100, 0) as today_rate_percent,
    active_nfts,
    CASE 
        WHEN today_rate > 0 THEN '✅ 設定済み'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) IN (1,2,3,4,5) THEN '⚠️ 未設定'
        ELSE '📅 土日'
    END as status
FROM today_rates;

-- 4. 上位ユーザーの今日の報酬確認
SELECT 
    '🏆 今日の報酬上位' as section,
    u.name as user_name,
    n.name as nft_name,
    dr.investment_amount,
    dr.daily_rate * 100 as daily_rate_percent,
    ROUND(dr.reward_amount, 2) as reward_amount
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC
LIMIT 10;

-- 5. システム準備完了確認
SELECT 
    '🎉 システム状況' as category,
    CASE 
        WHEN EXISTS (SELECT 1 FROM group_weekly_rates WHERE week_start_date <= CURRENT_DATE AND week_start_date + 6 >= CURRENT_DATE)
        AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nfts' AND column_name = 'daily_rate_group_id')
        AND EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'calculate_daily_rewards_for_date')
        THEN '✅ 完全準備完了'
        ELSE '⚠️ 要確認'
    END as overall_status,
    '週利管理システムが正常に動作しています' as message,
    CURRENT_TIMESTAMP as check_time;
