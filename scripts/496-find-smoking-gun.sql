-- 🔍 決定的証拠の捜索 - 不正実行の痕跡を特定

-- 1. バックアップデータの構造確認
SELECT 
    '🔍 バックアップデータ構造' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'emergency_cleanup_backup_20250704'
ORDER BY ordinal_position;

-- 2. 最初と最後の不正実行を特定
WITH first_last_execution AS (
    SELECT 
        MIN(created_at) as first_execution,
        MAX(created_at) as last_execution,
        MIN(reward_date) as first_reward_date,
        MAX(reward_date) as last_reward_date
    FROM emergency_cleanup_backup_20250704
    WHERE backup_type = 'daily_rewards'
)
SELECT 
    '🚨 不正実行の時系列' as section,
    first_execution,
    last_execution,
    first_reward_date,
    last_reward_date,
    (last_execution - first_execution) as execution_duration,
    (last_reward_date - first_reward_date) as reward_period
FROM first_last_execution;

-- 3. 同一時刻に大量実行された疑わしいパターン
SELECT 
    '⚠️ 疑わしい大量実行' as section,
    created_at,
    COUNT(*) as simultaneous_records,
    SUM(amount) as simultaneous_amount,
    COUNT(DISTINCT user_id) as affected_users,
    COUNT(DISTINCT reward_date) as reward_dates,
    STRING_AGG(DISTINCT reward_date::TEXT, ', ' ORDER BY reward_date::TEXT) as reward_dates_list
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY created_at
HAVING COUNT(*) > 100  -- 同時に100件以上作成された場合
ORDER BY simultaneous_records DESC;

-- 4. 異常な報酬額パターンの検出
SELECT 
    '💰 異常な報酬額パターン' as section,
    amount,
    COUNT(*) as occurrence_count,
    COUNT(DISTINCT user_id) as user_count,
    COUNT(DISTINCT nft_id) as nft_count,
    MIN(reward_date) as first_occurrence,
    MAX(reward_date) as last_occurrence
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY amount
HAVING COUNT(*) > 50  -- 同じ金額が50回以上出現
ORDER BY occurrence_count DESC;

-- 5. 週末に実行された異常なパターン（本来は平日のみ）
SELECT 
    '📅 週末実行の異常パターン' as section,
    reward_date,
    EXTRACT(DOW FROM reward_date) as day_of_week,
    CASE EXTRACT(DOW FROM reward_date)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name,
    COUNT(*) as weekend_records,
    SUM(amount) as weekend_amount
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
AND EXTRACT(DOW FROM reward_date) IN (0, 6)  -- 日曜日(0)と土曜日(6)
GROUP BY reward_date, EXTRACT(DOW FROM reward_date)
ORDER BY reward_date;

-- 6. 現在存在する計算関数の詳細調査
SELECT 
    '🔧 現在の計算関数詳細' as section,
    routine_name,
    routine_type,
    external_language,
    security_type,
    is_deterministic,
    routine_body,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%calculate%'
ORDER BY routine_name;

-- 7. トリガー関数の確認（自動実行の可能性）
SELECT 
    '🎯 トリガー関数確認' as section,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND (action_statement LIKE '%calculate%' OR action_statement LIKE '%reward%')
ORDER BY event_object_table, trigger_name;

-- 8. 過去の週利設定の痕跡を探す
SELECT 
    '🔍 過去の週利設定痕跡' as section,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND (table_name LIKE '%weekly%' OR table_name LIKE '%rate%' OR column_name LIKE '%rate%')
ORDER BY table_name, column_name;

-- 9. 管理画面実行ログの確認（もしあれば）
SELECT 
    '👤 管理画面実行ログ' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_action_logs')
        THEN 'ログテーブル存在'
        ELSE 'ログテーブル不存在'
    END as log_table_status;

-- 10. 決定的証拠のまとめ
SELECT 
    '🚨 決定的証拠まとめ' as section,
    '証拠1: ' || COUNT(*) || '件の不正報酬レコード' as evidence_1,
    '証拠2: 総額$' || SUM(amount) || 'の不正利益' as evidence_2,
    '証拠3: ' || COUNT(DISTINCT user_id) || '人のユーザーが影響' as evidence_3,
    '証拠4: ' || COUNT(DISTINCT reward_date) || '日間にわたる不正実行' as evidence_4,
    '証拠5: 週利設定なしでの計算実行' as evidence_5
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards';
