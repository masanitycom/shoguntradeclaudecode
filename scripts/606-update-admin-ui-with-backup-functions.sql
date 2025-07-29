-- 管理UI用のバックアップ・復元関数を作成

-- 1. 利用可能なグループ表示関数
CREATE OR REPLACE FUNCTION show_available_groups()
RETURNS TABLE(
    group_name TEXT,
    daily_rate_limit_percent NUMERIC,
    nft_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.group_name::TEXT,
        ROUND(drg.daily_rate_limit * 100, 2) as daily_rate_limit_percent,
        COUNT(n.id) as nft_count
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 2. 設定済み週一覧表示関数
CREATE OR REPLACE FUNCTION list_configured_weeks()
RETURNS TABLE(
    week_start_date DATE,
    week_end_date DATE,
    group_count BIGINT,
    has_backup BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.week_end_date,
        COUNT(*) as group_count,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date
        ) as has_backup
    FROM group_weekly_rates gwr
    GROUP BY gwr.week_start_date, gwr.week_end_date
    ORDER BY gwr.week_start_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 3. 管理UI用バックアップ作成関数
CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    backup_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM create_weekly_rates_backup(
        p_week_start_date, 
        '管理画面からの手動バックアップ'
    );
END;
$$ LANGUAGE plpgsql;

-- 4. 管理UI用削除関数
CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    deleted_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM delete_weekly_rates_with_backup(
        p_week_start_date, 
        '管理画面からの削除'
    );
END;
$$ LANGUAGE plpgsql;

-- 5. 管理UI用復元関数
CREATE OR REPLACE FUNCTION admin_restore_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    restored_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM restore_weekly_rates_from_backup(
        p_week_start_date, 
        p_backup_timestamp
    );
END;
$$ LANGUAGE plpgsql;

-- 6. バックアップ一覧取得関数
CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM list_weekly_rates_backups();
END;
$$ LANGUAGE plpgsql;

-- 7. システム状況取得関数（バックアップ数追加）
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
        (SELECT COUNT(*) FROM users WHERE is_admin = false) as total_users,
        (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nfts,
        COALESCE((SELECT SUM(amount) FROM daily_rewards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'), 0) as pending_rewards,
        COALESCE((SELECT MAX(created_at)::TEXT FROM daily_rewards), '未実行') as last_calculation,
        (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates) as current_week_rates,
        (SELECT COUNT(*) FROM group_weekly_rates_backup) as total_backups;
END;
$$ LANGUAGE plpgsql;

-- 8. 週利確認関数
CREATE OR REPLACE FUNCTION check_weekly_rate(
    p_week_start_date DATE
) RETURNS TABLE(
    group_name TEXT,
    weekly_rate_percent NUMERIC,
    monday_percent NUMERIC,
    tuesday_percent NUMERIC,
    wednesday_percent NUMERIC,
    thursday_percent NUMERIC,
    friday_percent NUMERIC,
    distribution_method TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.group_name::TEXT,
        ROUND(gwr.weekly_rate * 100, 2),
        ROUND(gwr.monday_rate * 100, 2),
        ROUND(gwr.tuesday_rate * 100, 2),
        ROUND(gwr.wednesday_rate * 100, 2),
        ROUND(gwr.thursday_rate * 100, 2),
        ROUND(gwr.friday_rate * 100, 2),
        gwr.distribution_method::TEXT
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date = p_week_start_date
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 9. 週利設定とグループ情報取得関数（改良版）
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    id UUID,
    week_start_date DATE,
    week_end_date DATE,
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
        gwr.id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        drg.group_name::TEXT,
        gwr.distribution_method::TEXT,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date
            AND gwrb.group_id = gwr.group_id
        ) as has_backup
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 完了メッセージ
SELECT 'Created admin UI backup and restore functions' as status;
