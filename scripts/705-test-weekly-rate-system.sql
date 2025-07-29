-- 週利管理システムの動作テスト

-- 1. 現在の週の開始日を取得
WITH current_week AS (
    SELECT 
        CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE)::INTEGER - 1) as week_start,
        CURRENT_DATE as today,
        EXTRACT(DOW FROM CURRENT_DATE) as day_of_week
)
SELECT 
    '📅 現在の週情報' as section,
    week_start,
    today,
    CASE day_of_week
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name,
    CASE 
        WHEN day_of_week IN (1,2,3,4,5) THEN '✅ 平日（計算対象）'
        ELSE '📅 土日（計算対象外）'
    END as calculation_status
FROM current_week;

-- 2. 今週の週利設定状況を確認
SELECT 
    '📊 今週の週利設定状況' as section,
    drg.group_name,
    (drg.daily_rate_limit * 100)::NUMERIC(5,3) as daily_limit_percent,
    CASE 
        WHEN gwr.id IS NOT NULL THEN '✅ 設定済み'
        ELSE '❌ 未設定'
    END as setting_status,
    CASE 
        WHEN gwr.id IS NOT NULL THEN (gwr.weekly_rate * 100)::NUMERIC(5,3)
        ELSE NULL
    END as weekly_rate_percent,
    CASE 
        WHEN gwr.id IS NOT NULL THEN (
            CASE EXTRACT(DOW FROM CURRENT_DATE)
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END * 100
        )::NUMERIC(5,3)
        ELSE NULL
    END as today_rate_percent
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    AND gwr.week_start_date = CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE)::INTEGER - 1)
ORDER BY drg.daily_rate_limit;

-- 3. アクティブなユーザーNFTの状況確認
SELECT 
    '👥 アクティブNFT状況' as section,
    drg.group_name,
    COUNT(un.id) as active_nfts,
    SUM(COALESCE(un.current_investment, un.purchase_price, 0)) as total_investment,
    AVG(COALESCE(un.current_investment, un.purchase_price, 0)) as avg_investment,
    SUM(COALESCE(un.total_earned, 0)) as total_earned,
    COUNT(CASE WHEN COALESCE(un.total_earned, 0) >= COALESCE(un.max_earning, un.purchase_price * 3, 0) THEN 1 END) as completed_nfts
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE un.is_active = true
GROUP BY drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 4. 今日の日利計算結果確認
SELECT 
    '💰 今日の日利計算結果' as section,
    COUNT(*) as calculated_rewards,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.reward_amount) as avg_reward,
    MIN(dr.reward_amount) as min_reward,
    MAX(dr.reward_amount) as max_reward,
    COUNT(DISTINCT dr.user_id) as benefited_users
FROM daily_rewards dr
WHERE dr.reward_date = CURRENT_DATE;

-- 5. 上位報酬ユーザー（今日）
SELECT 
    '🏆 今日の報酬上位ユーザー' as section,
    COALESCE(u.name, u.email, 'ユーザー' || ROW_NUMBER() OVER()) as user_name,
    n.name as nft_name,
    dr.investment_amount,
    (dr.daily_rate * 100)::NUMERIC(5,3) as daily_rate_percent,
    ROUND(dr.reward_amount, 2) as reward_amount,
    ROUND(COALESCE(un.total_earned, 0), 2) as total_earned,
    ROUND(COALESCE(un.max_earning, un.purchase_price * 3, 0), 2) as max_earning,
    ROUND((COALESCE(un.total_earned, 0) / COALESCE(un.max_earning, un.purchase_price * 3, 1)) * 100, 1) as completion_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC
LIMIT 10;

-- 6. システム健全性最終確認
SELECT 
    '🔍 システム健全性確認' as section,
    'テーブル構造' as check_item,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_nfts' AND column_name = 'investment_amount')
        AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_nfts' AND column_name = 'current_investment')
        AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_nfts' AND column_name = 'total_earned')
        AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_nfts' AND column_name = 'max_earning')
        AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nfts' AND column_name = 'daily_rate_group_id')
        THEN '✅ 正常'
        ELSE '❌ 異常'
    END as status,
    '必要なカラムが全て存在' as details

UNION ALL

SELECT 
    '🔍 システム健全性確認' as section,
    '管理関数' as check_item,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name IN (
            'calculate_daily_rewards_for_date', 'force_daily_calculation', 'get_system_status',
            'get_weekly_rates_with_groups', 'admin_create_backup', 'set_group_weekly_rate'
        )) >= 6
        THEN '✅ 正常'
        ELSE '❌ 不足'
    END as status,
    '管理画面用関数が利用可能' as details

UNION ALL

SELECT 
    '🔍 システム健全性確認' as section,
    'データ整合性' as check_item,
    CASE 
        WHEN (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) > 0
        AND (SELECT COUNT(*) FROM daily_rate_groups) > 0
        AND (SELECT COUNT(*) FROM nfts WHERE daily_rate_group_id IS NOT NULL) > 0
        THEN '✅ 正常'
        ELSE '⚠️ 要確認'
    END as status,
    'アクティブNFTとグループ関連付けが正常' as details;

-- 7. 管理画面機能テスト
SELECT 
    '🎛️ 管理画面機能テスト' as section,
    'システム状況取得' as function_name,
    CASE 
        WHEN (SELECT get_system_status()) IS NOT NULL
        THEN '✅ 動作正常'
        ELSE '❌ エラー'
    END as test_result,
    'get_system_status()関数のテスト' as description

UNION ALL

SELECT 
    '🎛️ 管理画面機能テスト' as section,
    '週利設定取得' as function_name,
    CASE 
        WHEN (SELECT COUNT(*) FROM get_weekly_rates_with_groups()) >= 0
        THEN '✅ 動作正常'
        ELSE '❌ エラー'
    END as test_result,
    'get_weekly_rates_with_groups()関数のテスト' as description;

-- 8. 最終ステータス表示
SELECT 
    '🎉 システム最終ステータス' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM group_weekly_rates WHERE week_start_date <= CURRENT_DATE AND week_start_date + 6 >= CURRENT_DATE)
        AND EXISTS (SELECT 1 FROM user_nfts WHERE is_active = true)
        AND EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'calculate_daily_rewards_for_date')
        AND EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_system_status')
        THEN '🚀 完全稼働中'
        ELSE '⚠️ 要調整'
    END as overall_status,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) IN (1,2,3,4,5) THEN '平日 - 日利計算実行可能'
        ELSE '土日 - 日利計算は月曜日から'
    END as calculation_availability,
    format('管理画面: /admin/weekly-rates でアクセス可能') as admin_access,
    CURRENT_TIMESTAMP as check_timestamp;
