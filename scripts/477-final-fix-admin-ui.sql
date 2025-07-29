-- 管理画面UI表示の最終修正

-- 1. 不要な関数を削除
DROP FUNCTION IF EXISTS get_weekly_rates_for_admin();
DROP FUNCTION IF EXISTS get_daily_rate_groups_for_admin();

-- 2. 管理画面表示用のビューを再作成
CREATE OR REPLACE VIEW admin_weekly_rates_nft_groups AS
SELECT 
    drg.id,
    drg.group_name,
    drg.daily_rate_limit,
    drg.description,
    COALESCE(nft_counts.nft_count, 0) as nft_count
FROM daily_rate_groups drg
LEFT JOIN (
    SELECT 
        daily_rate_limit,
        COUNT(*) as nft_count
    FROM nfts 
    WHERE is_active = true
    GROUP BY daily_rate_limit
) nft_counts ON ABS(drg.daily_rate_limit - nft_counts.daily_rate_limit) < 0.0001
ORDER BY drg.daily_rate_limit;

-- 3. システム状況取得関数を修正
CREATE OR REPLACE FUNCTION get_system_status_for_admin()
RETURNS TABLE(
    active_nft_investments INTEGER,
    available_nfts INTEGER,
    current_week_rates INTEGER,
    is_weekday BOOLEAN,
    day_of_week INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    today_dow INTEGER;
    week_start_date DATE;
BEGIN
    today_dow := EXTRACT(DOW FROM CURRENT_DATE);
    week_start_date := DATE_TRUNC('week', CURRENT_DATE)::DATE;
    
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true AND current_investment > 0),
        (SELECT COUNT(*)::INTEGER FROM nfts WHERE is_active = true),
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates WHERE week_start_date = week_start_date),
        (today_dow BETWEEN 1 AND 5),
        today_dow;
END $$;

-- 4. 管理画面表示テスト
SELECT 
    '📊 システム状況' as section,
    active_nft_investments || ' アクティブNFT投資' as stat1,
    available_nfts || ' 利用可能NFT' as stat2,
    current_week_rates || ' 今週の週利設定' as stat3,
    is_weekday || ' 平日判定' as stat4,
    day_of_week || ' 曜日' as stat5
FROM get_system_status_for_admin();

-- 5. 最終確認
SELECT 
    '✅ 管理画面UI更新完了' as status,
    COUNT(DISTINCT daily_rate_limit) || '個のグループ' as groups,
    COUNT(*) || '個のNFT' as nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) || '個の週利設定' as weekly_settings;

-- 6. 管理画面コンポーネント用のクエリテスト
SELECT 
    '🔧 管理画面コンポーネント用データ' as test_section,
    id,
    group_name,
    daily_rate_limit,
    description,
    nft_count
FROM admin_weekly_rates_nft_groups;
