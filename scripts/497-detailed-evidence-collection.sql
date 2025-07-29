-- 🔍 詳細証拠収集 - 完全な不正実行の解明

-- 1. 時系列での不正実行パターン詳細
SELECT 
    '⏰ 時系列不正実行パターン' as section,
    DATE_TRUNC('day', created_at) as execution_date,
    COUNT(*) as records_created,
    SUM(amount) as daily_fraud_amount,
    COUNT(DISTINCT user_id) as users_affected,
    COUNT(DISTINCT reward_date) as reward_dates_created,
    MIN(created_at) as first_execution_time,
    MAX(created_at) as last_execution_time,
    EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at))) / 60 as execution_duration_minutes
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY execution_date;

-- 2. 最も疑わしい大量実行の詳細
SELECT 
    '🚨 大量実行の詳細' as section,
    created_at as exact_execution_time,
    COUNT(*) as batch_size,
    SUM(amount) as batch_total,
    COUNT(DISTINCT user_id) as batch_users,
    COUNT(DISTINCT nft_id) as batch_nfts,
    COUNT(DISTINCT reward_date) as batch_reward_dates,
    MIN(amount) as min_reward,
    MAX(amount) as max_reward,
    AVG(amount) as avg_reward
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY created_at
HAVING COUNT(*) > 200  -- 200件以上の大量実行
ORDER BY batch_size DESC;

-- 3. 不正に使用されたNFTの詳細分析
SELECT 
    '🎯 不正使用NFT詳細' as section,
    nft_name,
    nft_id,
    COUNT(*) as total_usage,
    SUM(amount) as total_fraud_amount,
    COUNT(DISTINCT user_id) as affected_users,
    COUNT(DISTINCT reward_date) as reward_dates,
    AVG(amount) as avg_reward_per_use,
    MIN(amount) as min_reward,
    MAX(amount) as max_reward,
    STDDEV(amount) as reward_variation
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY nft_id, nft_name
ORDER BY total_fraud_amount DESC;

-- 4. 被害ユーザーの詳細分析
SELECT 
    '👥 被害ユーザー詳細分析' as section,
    user_name,
    user_id,
    COUNT(*) as fraud_records,
    SUM(amount) as total_fraud_earnings,
    COUNT(DISTINCT nft_id) as nfts_used,
    COUNT(DISTINCT reward_date) as reward_days,
    MIN(reward_date) as first_fraud_date,
    MAX(reward_date) as last_fraud_date,
    AVG(amount) as avg_daily_fraud,
    MAX(amount) as max_single_fraud
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY user_id, user_name
ORDER BY total_fraud_earnings DESC
LIMIT 20;

-- 5. 報酬日付パターンの異常検出
SELECT 
    '📅 報酬日付異常パターン' as section,
    reward_date,
    EXTRACT(DOW FROM reward_date) as day_of_week,
    CASE EXTRACT(DOW FROM reward_date)
        WHEN 0 THEN '日曜日 ❌'
        WHEN 1 THEN '月曜日 ✅'
        WHEN 2 THEN '火曜日 ✅'
        WHEN 3 THEN '水曜日 ✅'
        WHEN 4 THEN '木曜日 ✅'
        WHEN 5 THEN '金曜日 ✅'
        WHEN 6 THEN '土曜日 ❌'
    END as day_status,
    COUNT(*) as records_count,
    SUM(amount) as daily_fraud_total,
    COUNT(DISTINCT user_id) as users_count
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY reward_date, EXTRACT(DOW FROM reward_date)
ORDER BY reward_date;

-- 6. 同一金額の異常な重複パターン
SELECT 
    '💰 同一金額重複パターン' as section,
    amount,
    COUNT(*) as occurrence_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT nft_id) as unique_nfts,
    COUNT(DISTINCT reward_date) as unique_dates,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM emergency_cleanup_backup_20250704 WHERE backup_type = 'daily_rewards')), 2) as percentage_of_total
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY amount
HAVING COUNT(*) > 10  -- 10回以上出現する金額
ORDER BY occurrence_count DESC;

-- 7. 現在のシステム関数の完全リスト
SELECT 
    '🔧 現在のシステム関数完全リスト' as section,
    routine_name,
    routine_type,
    external_language,
    security_type,
    is_deterministic,
    CASE 
        WHEN routine_name LIKE '%calculate%' THEN '🚨 計算関数'
        WHEN routine_name LIKE '%reward%' THEN '🚨 報酬関数'
        WHEN routine_name LIKE '%daily%' THEN '🚨 日利関数'
        ELSE '通常関数'
    END as function_risk_level
FROM information_schema.routines
WHERE routine_schema = 'public'
AND (
    routine_name LIKE '%calculate%' OR 
    routine_name LIKE '%reward%' OR 
    routine_name LIKE '%daily%' OR
    routine_name LIKE '%batch%'
)
ORDER BY function_risk_level DESC, routine_name;

-- 8. 週利設定テーブルの完全状況
SELECT 
    '📊 週利設定完全状況' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates') 
        THEN '✅ group_weekly_rates テーブル存在'
        ELSE '❌ group_weekly_rates テーブル不存在'
    END as table_status,
    COALESCE((SELECT COUNT(*) FROM group_weekly_rates), 0) as total_records,
    COALESCE((SELECT MIN(week_start_date) FROM group_weekly_rates), NULL) as earliest_week,
    COALESCE((SELECT MAX(week_start_date) FROM group_weekly_rates), NULL) as latest_week,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM group_weekly_rates 
            WHERE week_start_date >= '2025-02-10' 
            AND week_start_date <= '2025-03-14'
        )
        THEN '❌ 不正期間に週利設定あり'
        ELSE '✅ 不正期間に週利設定なし（正常）'
    END as fraud_period_status;

-- 9. user_nfts テーブルの被害状況
SELECT 
    '💸 user_nfts被害状況' as section,
    backup_type,
    COUNT(*) as affected_records,
    SUM(amount) as total_earnings_reset,
    COUNT(DISTINCT user_id) as users_with_earnings,
    AVG(amount) as avg_earnings_per_user,
    MAX(amount) as max_user_earnings,
    MIN(amount) as min_user_earnings
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'user_nfts_earnings'
GROUP BY backup_type;

-- 10. 最終的な犯罪証拠まとめ
SELECT 
    '🚨 最終犯罪証拠まとめ' as section,
    '不正実行開始日: ' || (
        SELECT MIN(reward_date) FROM emergency_cleanup_backup_20250704 
        WHERE backup_type = 'daily_rewards'
    ) as fraud_start_date,
    '不正実行終了日: ' || (
        SELECT MAX(reward_date) FROM emergency_cleanup_backup_20250704 
        WHERE backup_type = 'daily_rewards'
    ) as fraud_end_date,
    '実際の実行日: ' || (
        SELECT DISTINCT DATE_TRUNC('day', created_at) FROM emergency_cleanup_backup_20250704 
        WHERE backup_type = 'daily_rewards' LIMIT 1
    ) as actual_execution_date,
    '総被害額: $' || (
        SELECT SUM(amount) FROM emergency_cleanup_backup_20250704 
        WHERE backup_type = 'daily_rewards'
    ) as total_damage,
    '被害ユーザー数: ' || (
        SELECT COUNT(DISTINCT user_id) FROM emergency_cleanup_backup_20250704 
        WHERE backup_type = 'daily_rewards'
    ) as total_victims,
    '不正レコード数: ' || (
        SELECT COUNT(*) FROM emergency_cleanup_backup_20250704 
        WHERE backup_type = 'daily_rewards'
    ) as total_fraud_records;
