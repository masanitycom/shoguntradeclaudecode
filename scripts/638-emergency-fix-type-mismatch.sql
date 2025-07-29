-- 緊急型不一致修正

-- 1. 問題のある関数をすべて削除
DROP FUNCTION IF EXISTS show_available_groups();
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS get_backup_list();

-- 2. daily_rate_groupsテーブルの実際の型を確認
SELECT 
    '📋 テーブル構造確認' as section,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups'
ORDER BY ordinal_position;

-- 3. show_available_groups関数を正しい型で再作成
CREATE OR REPLACE FUNCTION show_available_groups()
RETURNS TABLE(
    group_id UUID,
    group_name TEXT,  -- TEXTに統一
    nft_count BIGINT,
    total_investment NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.id as group_id,
        drg.group_name::TEXT,  -- 明示的にTEXTにキャスト
        COUNT(n.id) as nft_count,
        COALESCE(SUM(n.price), 0) as total_investment
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    GROUP BY drg.id, drg.group_name
    ORDER BY drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 4. get_weekly_rates_with_groups関数を正しい型で再作成
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    id TEXT,  -- UUIDをTEXTに変換
    week_start_date TEXT,  -- DATEをTEXTに変換
    week_end_date TEXT,    -- DATEをTEXTに変換
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    group_name TEXT,
    distribution_method TEXT,
    has_backup BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id::TEXT,
        gwr.week_start_date::TEXT,
        gwr.week_end_date::TEXT,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        drg.group_name::TEXT,
        COALESCE(gwr.distribution_method, 'random')::TEXT,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date
        ) as has_backup
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 5. get_system_status関数を再作成
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    total_users BIGINT,
    active_nfts BIGINT,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates BIGINT,
    total_backups BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users WHERE is_active = true) as total_users,
        (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nfts,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days') as pending_rewards,
        (SELECT COALESCE(MAX(created_at)::TEXT, '未実行') FROM daily_rewards) as last_calculation,
        (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates) as current_week_rates,
        (SELECT COUNT(*) FROM group_weekly_rates_backup) as total_backups;
END;
$$ LANGUAGE plpgsql;

-- 6. get_backup_list関数を再作成
CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.week_start_date,
        gwrb.backup_timestamp,
        COALESCE(gwrb.backup_reason, 'Unknown')::TEXT,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.backup_timestamp, gwrb.backup_reason
    ORDER BY gwrb.backup_timestamp DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. 権限設定
GRANT EXECUTE ON FUNCTION show_available_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_with_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION get_backup_list() TO authenticated;

-- 8. 関数テスト
SELECT '🧪 show_available_groups テスト' as test_name;
SELECT * FROM show_available_groups();

SELECT '🧪 get_system_status テスト' as test_name;
SELECT * FROM get_system_status();

SELECT '🧪 get_backup_list テスト' as test_name;
SELECT * FROM get_backup_list() LIMIT 3;

SELECT '✅ 型不一致エラー修正完了!' as status;
