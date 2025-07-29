-- 🚨 緊急システム診断 - 日利計算システムの状態確認（修正版）

-- 1. 週利設定の確認
SELECT 
    '=== 週利設定確認 ===' as section,
    week_start_date,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM group_weekly_rates 
ORDER BY week_start_date DESC, group_name;

-- 2. ユーザーNFTの確認
SELECT 
    '=== ユーザーNFT確認 ===' as section,
    COUNT(*) as total_user_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts
FROM user_nfts;

-- 3. 日利計算関数の存在確認
SELECT 
    '=== 日利計算関数確認 ===' as section,
    proname as function_name,
    '存在' as function_exists
FROM pg_proc 
WHERE proname LIKE '%daily%' OR proname LIKE '%calculate%'
ORDER BY proname;

-- 4. 日利報酬テーブルの状態確認
SELECT 
    '=== 日利報酬テーブル確認 ===' as section,
    COUNT(*) as total_rewards,
    COUNT(CASE WHEN is_claimed = false THEN 1 END) as pending_rewards,
    COALESCE(MAX(reward_date)::TEXT, 'なし') as latest_reward_date
FROM daily_rewards;

-- 5. NFTグループ分類の確認
SELECT 
    '=== NFTグループ分類確認 ===' as section,
    drg.group_name,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
GROUP BY drg.group_name
ORDER BY drg.group_name;

-- 6. 今日の日付と曜日確認
SELECT 
    '=== 日付・曜日確認 ===' as section,
    CURRENT_DATE as today,
    EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) IN (0, 6) THEN '土日（計算対象外）'
        ELSE '平日（計算対象）'
    END as calculation_target;

-- 7. 現在週の週利設定確認
SELECT 
    '=== 現在週の週利設定 ===' as section,
    COUNT(*) as current_week_rates,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ 現在週の週利が未設定'
        ELSE '✅ 現在週の週利設定済み'
    END as status
FROM group_weekly_rates 
WHERE week_start_date <= CURRENT_DATE 
AND week_start_date + INTERVAL '6 days' >= CURRENT_DATE;

-- 8. 具体的な問題診断
SELECT 
    '=== 問題診断結果 ===' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date <= CURRENT_DATE AND week_start_date + INTERVAL '6 days' >= CURRENT_DATE) = 0 
        THEN '🚨 問題: 現在週の週利が設定されていません'
        WHEN (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) = 0 
        THEN '🚨 問題: アクティブなNFTがありません'
        WHEN NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'force_daily_calculation')
        THEN '🚨 問題: 日利計算関数が存在しません'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) IN (0, 6)
        THEN '⚠️  注意: 今日は土日のため日利計算対象外です'
        ELSE '✅ システム準備完了: 日利計算を実行できます'
    END as diagnosis;

SELECT '🚨 システム診断完了 - 問題を特定中...' as status;
