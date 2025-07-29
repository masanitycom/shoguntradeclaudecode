-- 🔍 根本原因分析

-- 1. 関数履歴確認
SELECT 
    '🔍 関数確認' as section,
    routine_name,
    routine_type,
    created as created_date
FROM information_schema.routines 
WHERE routine_name LIKE '%daily%' OR routine_name LIKE '%reward%'
ORDER BY created DESC;

-- 2. テーブル作成履歴
SELECT 
    '🔍 テーブル履歴' as section,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('daily_rewards', 'group_weekly_rates', 'user_nfts')
ORDER BY table_name;

-- 3. 週利設定の履歴確認
SELECT 
    '🔍 週利設定履歴' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM group_weekly_rates) THEN '存在する'
        ELSE '❌ 存在しない'
    END as weekly_rates_status,
    (SELECT COUNT(*) FROM group_weekly_rates) as total_weekly_rates;

-- 4. 不正計算の可能性分析
SELECT 
    '🔍 不正計算分析' as section,
    'バックアップから分析' as analysis_source,
    backup_type,
    COUNT(*) as record_count,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date,
    SUM(amount) as total_amount
FROM emergency_cleanup_backup_20250704
WHERE backup_type = 'daily_rewards'
GROUP BY backup_type;

-- 5. 推定原因
SELECT 
    '🔍 推定原因' as section,
    '1. テスト関数が本番実行された' as cause_1,
    '2. デフォルト値で計算が実行された' as cause_2,
    '3. 週利設定チェックが不十分だった' as cause_3,
    '4. 手動実行時の安全チェック不備' as cause_4;

-- 6. 今後の対策
SELECT 
    '✅ 対策完了' as section,
    '緊急停止フラグ実装' as measure_1,
    '週利設定必須チェック' as measure_2,
    '管理者認証システム' as measure_3,
    'バックアップ自動作成' as measure_4;
