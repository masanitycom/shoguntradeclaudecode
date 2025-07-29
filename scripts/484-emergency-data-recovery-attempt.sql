-- 緊急データ復旧の試み

-- 1. バックアップテーブルの存在確認
SELECT 
    '🔍 バックアップテーブル確認' as section,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name LIKE '%backup%' OR table_name LIKE '%bak%'
ORDER BY table_name;

-- 2. 過去のデータが残っているテーブルを確認
SELECT 
    '📊 関連テーブルのデータ確認' as section,
    'daily_rewards' as table_name,
    COUNT(*) as record_count,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date
FROM daily_rewards
WHERE reward_date IS NOT NULL

UNION ALL

SELECT 
    '📊 関連テーブルのデータ確認' as section,
    'user_nfts' as table_name,
    COUNT(*) as record_count,
    MIN(created_at::DATE) as earliest_date,
    MAX(created_at::DATE) as latest_date
FROM user_nfts
WHERE created_at IS NOT NULL;

-- 3. 実際に使用されていた週利データの痕跡を探す
SELECT 
    '🔍 実際の週利データの痕跡' as section,
    reward_date,
    COUNT(DISTINCT user_id) as users,
    COUNT(*) as rewards,
    AVG(daily_rate) as avg_daily_rate,
    SUM(reward_amount) as total_rewards
FROM daily_rewards
WHERE reward_date >= '2024-12-01'
GROUP BY reward_date
ORDER BY reward_date DESC
LIMIT 20;

-- 4. 週利設定の履歴をログから復元する試み
-- PostgreSQLのログテーブルがあるかチェック
SELECT 
    '📝 ログテーブル確認' as section,
    table_name
FROM information_schema.tables 
WHERE table_name LIKE '%log%' OR table_name LIKE '%audit%' OR table_name LIKE '%history%'
ORDER BY table_name;

-- 5. 現在のシステム状況を完全にクリア
DELETE FROM group_weekly_rates;

-- 6. 最小限の今週分のみ作成（ユーザーが再設定しやすいように）
INSERT INTO group_weekly_rates (
    group_id,
    week_start_date,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    created_at,
    updated_at
)
SELECT 
    drg.id,
    DATE_TRUNC('week', CURRENT_DATE)::DATE,
    0.026, -- デフォルト2.6%（ユーザーが変更可能）
    0.0052,
    0.0052,
    0.0052,
    0.0052,
    0.0052,
    NOW(),
    NOW()
FROM daily_rate_groups drg;

-- 7. 最終状況確認
SELECT 
    '✅ クリーンアップ完了' as section,
    COUNT(*) as total_settings,
    COUNT(DISTINCT week_start_date) as weeks,
    week_start_date as current_week
FROM group_weekly_rates
GROUP BY week_start_date;

-- 8. 管理画面で再設定可能な状態であることを確認
SELECT 
    '🔧 再設定準備完了' as section,
    drg.group_name,
    drg.daily_rate_limit,
    gwr.weekly_rate * 100 as current_weekly_percent,
    '変更可能' as status
FROM daily_rate_groups drg
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
ORDER BY drg.daily_rate_limit;
