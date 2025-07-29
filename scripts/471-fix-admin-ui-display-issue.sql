-- 管理画面表示問題の修正

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS get_admin_weekly_rates_summary();
DROP FUNCTION IF EXISTS get_weekly_rates_for_admin();
DROP FUNCTION IF EXISTS get_daily_rate_groups_for_admin();
DROP FUNCTION IF EXISTS get_system_status_for_admin();
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch(DATE);

-- 2. テーブル構造を確認
SELECT '🔍 daily_rate_groups構造確認' as section;
SELECT column_name, data_type, character_maximum_length, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
ORDER BY ordinal_position;

SELECT '🔍 group_weekly_rates構造確認' as section;
SELECT column_name, data_type, character_maximum_length, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 3. 現在のデータ確認
SELECT '📊 現在の週利設定データ' as section;
SELECT 
    gwr.id,
    gwr.group_id,
    drg.group_name,
    gwr.weekly_rate,
    gwr.week_start_date
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY drg.daily_rate_limit;

-- 4. 型の問題を特定
SELECT '🔧 型の問題特定' as section;
SELECT 
    pg_typeof(drg.group_name) as group_name_type,
    pg_typeof(drg.description) as description_type,
    pg_typeof(drg.daily_rate_limit) as daily_rate_limit_type
FROM daily_rate_groups drg
LIMIT 1;

-- 5. 管理画面用のビューを作成（必要に応じて）
DROP VIEW IF EXISTS admin_weekly_rates_view;
CREATE VIEW admin_weekly_rates_view AS
SELECT 
    drg.id as group_id,
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%' as rate_display,
    drg.description,
    COUNT(n.id) as nft_count,
    gwr.weekly_rate,
    (gwr.weekly_rate * 100) as weekly_rate_percent,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    gwr.week_start_date,
    gwr.created_at as weekly_rate_created_at
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
LEFT JOIN group_weekly_rates gwr ON gwr.group_id = drg.id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, drg.description, 
         gwr.weekly_rate, gwr.monday_rate, gwr.tuesday_rate, gwr.wednesday_rate, 
         gwr.thursday_rate, gwr.friday_rate, gwr.week_start_date, gwr.created_at
ORDER BY drg.daily_rate_limit;

-- 6. ビューの確認
SELECT 
    '🖥️ 管理画面用ビュー確認' as section,
    *
FROM admin_weekly_rates_view;

-- 7. RLSポリシーの確認と修正
SELECT 
    '🔒 RLSポリシー確認' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('daily_rate_groups', 'group_weekly_rates')
ORDER BY tablename, policyname;

-- 8. 管理画面用の関数を作成
CREATE OR REPLACE FUNCTION get_admin_weekly_rates_summary()
RETURNS TABLE(
    group_id UUID,
    group_name TEXT,
    daily_rate_limit DECIMAL,
    rate_display TEXT,
    nft_count BIGINT,
    weekly_rate DECIMAL,
    weekly_rate_percent DECIMAL,
    week_start_date DATE,
    has_weekly_setting BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.id as group_id,
        drg.group_name,
        drg.daily_rate_limit,
        (drg.daily_rate_limit * 100) || '%' as rate_display,
        COUNT(n.id) as nft_count,
        COALESCE(gwr.weekly_rate, 0) as weekly_rate,
        COALESCE(gwr.weekly_rate * 100, 0) as weekly_rate_percent,
        gwr.week_start_date,
        CASE WHEN gwr.id IS NOT NULL THEN true ELSE false END as has_weekly_setting
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
    LEFT JOIN group_weekly_rates gwr ON gwr.group_id = drg.id
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, 
             gwr.id, gwr.weekly_rate, gwr.week_start_date
    ORDER BY drg.daily_rate_limit;
END $$;

-- 9. 関数のテスト
SELECT 
    '🧪 管理画面用関数テスト' as section,
    *
FROM get_admin_weekly_rates_summary();

-- 10. 今週の週利設定数確認
SELECT 
    '📅 今週の週利設定数' as section,
    COUNT(*) as current_week_settings,
    COUNT(DISTINCT group_id) as unique_groups,
    week_start_date
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
GROUP BY week_start_date;

-- 11. システム状況サマリー
SELECT 
    '📊 システム状況サマリー' as section,
    (SELECT COUNT(*) FROM daily_rate_groups) as total_groups,
    (SELECT COUNT(*) FROM group_weekly_rates) as total_weekly_settings,
    (SELECT COUNT(DISTINCT group_id) FROM group_weekly_rates) as groups_with_settings,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as active_nfts,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_user_nfts;
