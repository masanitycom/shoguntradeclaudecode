-- 管理画面UI完全動作確認

-- 1. システム状況の詳細確認
SELECT 
    '🔍 システム詳細状況' as section,
    'アクティブNFT投資: ' || active_nft_investments as detail1,
    '利用可能NFT: ' || available_nfts as detail2,
    '今週の週利設定: ' || current_week_rates as detail3,
    CASE WHEN is_weekday THEN '平日（計算可能）' ELSE '土日（計算不可）' END as weekday_status,
    '曜日: ' || 
    CASE day_of_week 
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as current_day
FROM get_system_status_for_admin();

-- 2. 各グループの詳細情報
SELECT 
    '📋 グループ詳細情報' as section,
    group_name,
    (daily_rate_limit * 100)::TEXT || '%' as daily_limit_percent,
    nft_count || '種類のNFT' as nft_info,
    description
FROM admin_weekly_rates_nft_groups
ORDER BY daily_rate_limit;

-- 3. 今週の週利設定状況
SELECT 
    '📅 今週の週利設定' as section,
    drg.group_name,
    (gwr.weekly_rate * 100)::NUMERIC(5,2) || '%' as weekly_rate,
    (gwr.monday_rate * 100)::NUMERIC(5,2) || '%' as monday,
    (gwr.tuesday_rate * 100)::NUMERIC(5,2) || '%' as tuesday,
    (gwr.wednesday_rate * 100)::NUMERIC(5,2) || '%' as wednesday,
    (gwr.thursday_rate * 100)::NUMERIC(5,2) || '%' as thursday,
    (gwr.friday_rate * 100)::NUMERIC(5,2) || '%' as friday
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE
ORDER BY drg.daily_rate_limit;

-- 4. 管理画面UI準備完了確認
SELECT 
    '✅ 管理画面UI準備状況' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM daily_rate_groups) > 0 THEN '✅ グループ設定完了'
        ELSE '❌ グループ設定未完了'
    END as groups_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) > 0 THEN '✅ 週利設定完了'
        ELSE '❌ 週利設定未完了'
    END as weekly_rates_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM nfts WHERE is_active = true) > 0 THEN '✅ NFT設定完了'
        ELSE '❌ NFT設定未完了'
    END as nfts_status,
    '🚀 管理画面表示準備完了' as final_status;
