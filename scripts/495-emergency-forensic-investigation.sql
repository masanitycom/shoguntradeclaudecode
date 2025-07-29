-- 🔍 緊急フォレンジック調査 - なぜ設定なしで報酬が発生したか

-- 0. 必要なテーブルを先に作成
CREATE TABLE IF NOT EXISTS system_emergency_flags (
    flag_name TEXT PRIMARY KEY,
    is_active BOOLEAN DEFAULT FALSE,
    reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 緊急停止フラグを設定
INSERT INTO system_emergency_flags (flag_name, is_active, reason, created_by)
VALUES 
    ('CALCULATION_EMERGENCY_STOP', TRUE, '週利設定なしで不正計算実行のため緊急停止', 'system_admin')
ON CONFLICT (flag_name) 
DO UPDATE SET 
    is_active = TRUE,
    reason = '週利設定なしで不正計算実行のため緊急停止',
    updated_at = NOW();

-- 1. 削除されたデータの詳細分析
SELECT 
    '🚨 不正データ詳細分析' as section,
    backup_type,
    COUNT(*) as record_count,
    MIN(reward_date) as first_reward_date,
    MAX(reward_date) as last_reward_date,
    MIN(created_at) as first_created,
    MAX(created_at) as last_created,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount,
    COUNT(DISTINCT user_id) as affected_users
FROM emergency_cleanup_backup_20250704
GROUP BY backup_type;

-- 2. 日別の不正報酬発生パターン
SELECT 
    '📅 日別不正報酬パターン' as section,
    reward_date,
    COUNT(*) as daily_records,
    SUM(amount) as daily_total,
    COUNT(DISTINCT user_id) as daily_users,
    COUNT(DISTINCT nft_id) as daily_nfts
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY reward_date
ORDER BY reward_date;

-- 3. 最も被害の大きいユーザー
SELECT 
    '👥 被害ユーザートップ10' as section,
    user_name,
    COUNT(*) as reward_count,
    SUM(amount) as total_earned,
    MIN(reward_date) as first_reward,
    MAX(reward_date) as last_reward,
    COUNT(DISTINCT nft_id) as nft_count
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY user_id, user_name
ORDER BY total_earned DESC
LIMIT 10;

-- 4. 使用されたNFTの分析
SELECT 
    '🎯 使用NFT分析' as section,
    nft_name,
    COUNT(*) as usage_count,
    SUM(amount) as total_rewards,
    COUNT(DISTINCT user_id) as user_count,
    AVG(amount) as avg_reward_per_use
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY nft_id, nft_name
ORDER BY total_rewards DESC
LIMIT 10;

-- 5. 作成日時パターン分析（いつ実行されたか）
SELECT 
    '⏰ 実行時刻パターン分析' as section,
    DATE_TRUNC('hour', created_at) as execution_hour,
    COUNT(*) as records_created,
    SUM(amount) as amount_created,
    COUNT(DISTINCT reward_date) as reward_dates_affected
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY execution_hour;

-- 6. 現在のシステム関数確認
SELECT 
    '🔧 現在のシステム関数' as section,
    routine_name,
    routine_type,
    LEFT(routine_definition, 200) as routine_definition_preview
FROM information_schema.routines
WHERE routine_schema = 'public'
AND (routine_name LIKE '%daily%' OR routine_name LIKE '%reward%' OR routine_name LIKE '%calculate%')
ORDER BY routine_name;

-- 7. 週利設定テーブルの状況確認
SELECT 
    '📊 週利設定状況' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates') 
        THEN 'テーブル存在'
        ELSE 'テーブル不存在'
    END as table_status,
    COALESCE((SELECT COUNT(*) FROM group_weekly_rates), 0) as current_records,
    CASE 
        WHEN EXISTS (SELECT 1 FROM group_weekly_rates WHERE week_start_date >= '2025-02-10' AND week_start_date <= '2025-03-14')
        THEN '該当期間に設定あり'
        ELSE '該当期間に設定なし'
    END as period_status;

-- 8. 疑わしい実行ログ検索
SELECT 
    '🕵️ 疑わしい実行パターン' as section,
    DATE_TRUNC('day', created_at) as execution_date,
    COUNT(*) as total_executions,
    COUNT(DISTINCT reward_date) as reward_dates_created,
    SUM(amount) as total_amount_created,
    MIN(created_at) as first_execution_time,
    MAX(created_at) as last_execution_time
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY execution_date;

-- 9. 推定される不正実行の原因
SELECT 
    '🚨 推定原因' as section,
    '原因1: テスト関数が本番データで実行された' as possible_cause_1,
    '原因2: デフォルト値やハードコード値で計算実行' as possible_cause_2,
    '原因3: 管理画面から誤って実行された' as possible_cause_3,
    '原因4: 自動バッチ処理が暴走した' as possible_cause_4,
    '原因5: 過去の週利設定が残存していた' as possible_cause_5;

-- 10. 緊急対策状況確認
SELECT 
    '✅ 緊急対策状況' as section,
    flag_name,
    is_active,
    reason,
    created_at
FROM system_emergency_flags
WHERE flag_name = 'CALCULATION_EMERGENCY_STOP';
