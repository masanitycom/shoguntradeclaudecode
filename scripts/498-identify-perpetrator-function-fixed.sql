-- 🕵️ 犯人関数の特定 - どの関数が不正実行を行ったか（修正版）

-- 1. 現在存在する全ての計算関数の詳細調査
SELECT 
    '🔍 現在の計算関数詳細調査' as section,
    routine_name,
    routine_type,
    external_language,
    security_type,
    is_deterministic,
    CASE 
        WHEN routine_definition LIKE '%daily_rewards%' THEN '🚨 daily_rewards操作あり'
        WHEN routine_definition LIKE '%user_nfts%' THEN '🚨 user_nfts操作あり'
        WHEN routine_definition LIKE '%INSERT%' THEN '🚨 INSERT文あり'
        WHEN routine_definition LIKE '%UPDATE%' THEN '🚨 UPDATE文あり'
        ELSE '通常関数'
    END as risk_assessment,
    LENGTH(routine_definition) as function_size
FROM information_schema.routines
WHERE routine_schema = 'public'
AND (
    routine_name LIKE '%calculate%' OR 
    routine_name LIKE '%reward%' OR 
    routine_name LIKE '%daily%'
)
ORDER BY risk_assessment DESC, routine_name;

-- 2. 関数の実行統計（修正版）
SELECT 
    '📊 関数実行統計' as section,
    schemaname,
    funcname,
    calls,
    total_time,
    self_time,
    CASE 
        WHEN calls > 1000 THEN '🚨 大量実行'
        WHEN calls > 100 THEN '⚠️ 多数実行'
        WHEN calls > 0 THEN '✅ 実行あり'
        ELSE '実行なし'
    END as execution_level
FROM pg_stat_user_functions
WHERE funcname LIKE '%calculate%' OR funcname LIKE '%reward%' OR funcname LIKE '%daily%'
ORDER BY calls DESC;

-- 3. テーブルへの操作統計
SELECT 
    '📈 テーブル操作統計' as section,
    schemaname,
    relname as table_name,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_tup_hot_upd as hot_updates,
    CASE 
        WHEN relname = 'daily_rewards' AND n_tup_ins > 7000 THEN '🚨 大量INSERT検出'
        WHEN relname = 'user_nfts' AND n_tup_upd > 300 THEN '🚨 大量UPDATE検出'
        ELSE '通常'
    END as anomaly_detection
FROM pg_stat_user_tables
WHERE relname IN ('daily_rewards', 'user_nfts', 'group_weekly_rates')
ORDER BY n_tup_ins DESC;

-- 4. 疑わしい関数の定義内容を詳細確認
SELECT 
    '🔍 疑わしい関数定義詳細' as section,
    routine_name,
    routine_type,
    LEFT(routine_definition, 500) as function_preview
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    SELECT routine_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public'
    AND routine_definition LIKE '%daily_rewards%'
    AND routine_definition LIKE '%INSERT%'
)
ORDER BY routine_name;

-- 5. トリガーによる自動実行の可能性調査
SELECT 
    '🎯 トリガー自動実行調査' as section,
    trigger_name,
    event_manipulation,
    event_object_table,
    LEFT(action_statement, 200) as action_preview,
    action_timing,
    action_orientation,
    CASE 
        WHEN action_statement LIKE '%calculate%' THEN '🚨 計算関数呼び出し'
        WHEN action_statement LIKE '%reward%' THEN '🚨 報酬関数呼び出し'
        ELSE '通常トリガー'
    END as trigger_risk
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY trigger_risk DESC, event_object_table;

-- 6. 犯人関数の推定
WITH suspicious_functions AS (
    SELECT 
        routine_name,
        routine_definition,
        CASE 
            WHEN routine_definition LIKE '%daily_rewards%' AND routine_definition LIKE '%INSERT%' THEN 10
            WHEN routine_definition LIKE '%user_nfts%' AND routine_definition LIKE '%UPDATE%' THEN 8
            WHEN routine_name LIKE '%calculate%daily%' THEN 9
            WHEN routine_name LIKE '%batch%' THEN 7
            WHEN routine_definition LIKE '%30835%' THEN 10  -- 不正金額が含まれている
            WHEN routine_definition LIKE '%7307%' THEN 10   -- 不正レコード数が含まれている
            ELSE 1
        END as suspicion_score
    FROM information_schema.routines
    WHERE routine_schema = 'public'
    AND (
        routine_name LIKE '%calculate%' OR 
        routine_name LIKE '%reward%' OR 
        routine_name LIKE '%daily%' OR
        routine_name LIKE '%batch%'
    )
)
SELECT 
    '🚨 犯人関数推定ランキング' as section,
    routine_name,
    suspicion_score,
    CASE 
        WHEN suspicion_score >= 9 THEN '🚨 最重要容疑者'
        WHEN suspicion_score >= 7 THEN '⚠️ 重要容疑者'
        WHEN suspicion_score >= 5 THEN '🔍 容疑者'
        ELSE '低リスク'
    END as suspect_level,
    LEFT(routine_definition, 200) as function_preview
FROM suspicious_functions
ORDER BY suspicion_score DESC;

-- 7. 実行環境の確認
SELECT 
    '🖥️ 実行環境確認' as section,
    version() as postgresql_version,
    current_database() as database_name,
    current_user as current_user,
    session_user as session_user;

-- 8. 最も疑わしい関数の完全な定義を表示
SELECT 
    '🚨 最重要容疑者関数の完全定義' as section,
    routine_name,
    routine_type,
    routine_definition as complete_function_code
FROM information_schema.routines
WHERE routine_schema = 'public'
AND (
    (routine_definition LIKE '%daily_rewards%' AND routine_definition LIKE '%INSERT%') OR
    (routine_definition LIKE '%30835%') OR
    (routine_definition LIKE '%7307%') OR
    (routine_name LIKE '%calculate%daily%')
)
ORDER BY 
    CASE 
        WHEN routine_definition LIKE '%30835%' THEN 1
        WHEN routine_definition LIKE '%7307%' THEN 2
        WHEN routine_definition LIKE '%daily_rewards%' AND routine_definition LIKE '%INSERT%' THEN 3
        ELSE 4
    END;

-- 9. 最終結論
SELECT 
    '📋 犯人特定結論' as section,
    '🚨 2025年7月3日に不正実行された' as execution_date,
    '💰 総被害額: $30,835.52' as total_damage,
    '👥 被害者数: 297人' as victim_count,
    '📊 不正レコード: 7,307件' as fraud_records,
    '⏰ 実行期間: 2025-02-10 〜 2025-07-03' as fraud_period,
    '🎯 次のステップ: 犯人関数の無効化' as next_action;
