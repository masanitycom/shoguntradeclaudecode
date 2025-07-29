-- 2025年2月10日週の設定準備

-- 1. 日付検証（2025-02-10は月曜日か？）
SELECT 
    '📅 日付検証' as section,
    '2025-02-10'::DATE as target_date,
    EXTRACT(DOW FROM '2025-02-10'::DATE) as day_of_week,
    CASE WHEN EXTRACT(DOW FROM '2025-02-10'::DATE) = 1 
         THEN '✅ 月曜日です' 
         ELSE '❌ 月曜日ではありません' 
    END as validation;

-- 2. 利用可能グループと推奨設定
SELECT 
    '📊 グループ別推奨設定' as section,
    group_name,
    daily_rate_limit,
    nft_count,
    total_investment,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN 1.5
        WHEN daily_rate_limit = 0.010 THEN 2.0
        WHEN daily_rate_limit = 0.0125 THEN 2.3
        WHEN daily_rate_limit = 0.015 THEN 2.6
        WHEN daily_rate_limit = 0.0175 THEN 2.9
        WHEN daily_rate_limit = 0.020 THEN 3.2
        ELSE 2.0
    END as recommended_weekly_rate
FROM show_available_groups()
ORDER BY daily_rate_limit;

-- 3. 影響分析
SELECT 
    '💰 影響分析' as section,
    COUNT(DISTINCT un.user_id) as affected_users,
    COUNT(un.id) as total_nfts,
    SUM(un.purchase_price) as total_investment,
    AVG(un.purchase_price) as avg_nft_price
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
AND un.purchase_date <= '2025-02-10';

-- 4. 既存設定確認
SELECT 
    '🔍 既存設定確認' as section,
    CASE WHEN COUNT(*) > 0 
         THEN '⚠️ 既に設定済みです'
         ELSE '✅ 新規設定可能です'
    END as existing_status,
    COUNT(*) as existing_count
FROM group_weekly_rates
WHERE week_start_date = '2025-02-10';

-- 5. バックアップ状況確認
SELECT 
    '📦 バックアップ状況' as section,
    COUNT(*) as backup_count,
    CASE WHEN COUNT(*) > 0 
         THEN '✅ バックアップ済み'
         ELSE '📝 バックアップなし'
    END as backup_status
FROM group_weekly_rates_backup
WHERE week_start_date = '2025-02-10';

SELECT 'February 10 setup preparation completed!' as status;
