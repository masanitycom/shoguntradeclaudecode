-- 🚨 緊急システム診断 - 日利計算システムの状態確認

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
    prosrc as function_exists
FROM pg_proc 
WHERE proname LIKE '%daily%' OR proname LIKE '%calculate%'
ORDER BY proname;

-- 4. 日利報酬テーブルの状態確認
SELECT 
    '=== 日利報酬テーブル確認 ===' as section,
    COUNT(*) as total_rewards,
    COUNT(CASE WHEN is_claimed = false THEN 1 END) as pending_rewards,
    COALESCE(MAX(reward_date), 'なし') as latest_reward_date
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

SELECT '🚨 システム診断完了 - 問題を特定中...' as status;
