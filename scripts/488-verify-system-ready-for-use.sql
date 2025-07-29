-- システムが使用準備完了かを確認

-- 1. 現在の週利設定状況
SELECT 
    '📅 現在の週利設定' as section,
    drg.group_name,
    (gwr.weekly_rate * 100)::NUMERIC(5,2) as weekly_percent,
    gwr.week_start_date,
    '再設定可能' as status
FROM daily_rate_groups drg
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
ORDER BY drg.daily_rate_limit;

-- 2. バックアップシステムの動作確認
SELECT 
    '🛡️ バックアップシステム状況' as section,
    COUNT(*) as total_backups,
    MAX(backup_created_at) as latest_backup,
    STRING_AGG(DISTINCT backup_reason, ', ') as backup_reasons
FROM group_weekly_rates_backup;

-- 3. 管理画面で使用する関数の動作確認
SELECT 
    '🔧 管理機能確認' as section,
    'overwrite_specific_week_rates' as function_name,
    '利用可能' as status
WHERE EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'overwrite_specific_week_rates'
);

-- 4. 今週の設定可能日付を表示
SELECT 
    '📆 設定推奨日付' as section,
    CURRENT_DATE as today,
    DATE_TRUNC('week', CURRENT_DATE)::DATE as this_monday,
    (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days')::DATE as next_monday,
    '管理画面で設定してください' as instruction;

-- 5. NFTグループ別の現在の投資状況
SELECT 
    '💰 投資状況確認' as section,
    drg.group_name,
    COUNT(un.id) as active_investments,
    SUM(un.current_investment) as total_investment,
    AVG(un.current_investment) as avg_investment
FROM daily_rate_groups drg
JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
JOIN user_nfts un ON un.nft_id = n.id
WHERE un.is_active = true AND un.current_investment > 0
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
