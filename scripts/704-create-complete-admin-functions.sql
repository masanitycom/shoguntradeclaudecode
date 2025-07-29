-- 完全な管理画面用関数の作成

-- 1. システム状況取得関数（修正版）
DROP FUNCTION IF EXISTS get_system_status();

CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates INTEGER,
    total_backups INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    result_record RECORD;
BEGIN
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as active_nfts,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as pending_rewards,
        (SELECT COALESCE(MAX(reward_date)::TEXT, '未実行') FROM daily_rewards) as last_calculation,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates WHERE week_start_date <= CURRENT_DATE AND week_start_date + 6 >= CURRENT_DATE) as current_week_rates,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates_backup) as total_backups
    INTO result_record;
    
    RETURN QUERY SELECT 
        result_record.total_users,
        result_record.active_nfts,
        result_record.pending_rewards,
        result_record.last_calculation,
        result_record.current_week_rates,
        result_record.total_backups;
END;
$$;

-- 2. 週利設定取得関数（修正版）
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();

CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    id UUID,
    week_start_date DATE,
    week_end_date DATE,
    group_name TEXT,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    distribution_method TEXT,
    has_backup BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.group_name,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date 
            AND gwrb.group_id = gwr.group_id
        ) as has_backup
    FROM group_weekly_rates gwr
    ORDER BY gwr.week_start_date DESC, gwr.group_name;
END;
$$;

-- 3. バックアップ一覧取得関数（修正版）
DROP FUNCTION IF EXISTS get_backup_list();

CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP,
    backup_reason TEXT,
    group_count INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.week_start_date,
        gwrb.created_at as backup_timestamp,
        COALESCE(gwrb.backup_reason, 'システムバックアップ')::TEXT as backup_reason,
        COUNT(*)::INTEGER as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.created_at, gwrb.backup_reason
    ORDER BY gwrb.created_at DESC
    LIMIT 50;
END;
$$;

-- 4. バックアップ作成関数
DROP FUNCTION IF EXISTS admin_create_backup(DATE, TEXT);

CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual backup'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    backup_count INTEGER;
BEGIN
    -- 指定された週の設定をバックアップ
    INSERT INTO group_weekly_rates_backup (
        id, week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, backup_reason, created_at
    )
    SELECT 
        gen_random_uuid(), gwr.week_start_date, gwr.week_end_date, gwr.weekly_rate,
        gwr.monday_rate, gwr.tuesday_rate, gwr.wednesday_rate, gwr.thursday_rate, gwr.friday_rate,
        gwr.group_id, gwr.group_name, gwr.distribution_method, 
        p_reason, NOW()
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true as success,
        format('✅ %s件の週利設定をバックアップしました（%s）', backup_count, p_week_start_date) as message;
END;
$$;

-- 5. 週利設定削除関数
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE);

CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(
    p_week_start_date DATE
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- バックアップを作成
    PERFORM admin_create_backup(p_week_start_date, format('削除前のバックアップ (%s)', NOW()::DATE));
    
    -- 削除実行
    DELETE FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true as success,
        format('✅ %s件の週利設定を削除しました（%s）', deleted_count, p_week_start_date) as message;
END;
$$;

-- 6. バックアップから復元関数
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP);

CREATE OR REPLACE FUNCTION admin_restore_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    restored_count INTEGER;
    backup_time TIMESTAMP;
BEGIN
    -- バックアップ時刻を決定
    IF p_backup_timestamp IS NULL THEN
        SELECT MAX(created_at) INTO backup_time
        FROM group_weekly_rates_backup
        WHERE week_start_date = p_week_start_date;
    ELSE
        backup_time := p_backup_timestamp;
    END IF;
    
    IF backup_time IS NULL THEN
        RETURN QUERY SELECT 
            false as success,
            format('❌ %s のバックアップが見つかりません', p_week_start_date) as message;
        RETURN;
    END IF;
    
    -- 現在の設定をバックアップ
    PERFORM admin_create_backup(p_week_start_date, format('復元前のバックアップ (%s)', NOW()::DATE));
    
    -- 既存の設定を削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- バックアップから復元
    INSERT INTO group_weekly_rates (
        id, week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, created_at, updated_at
    )
    SELECT 
        gen_random_uuid(), gwrb.week_start_date, gwrb.week_end_date, gwrb.weekly_rate,
        gwrb.monday_rate, gwrb.tuesday_rate, gwrb.wednesday_rate, gwrb.thursday_rate, gwrb.friday_rate,
        gwrb.group_id, gwrb.group_name, gwrb.distribution_method, NOW(), NOW()
    FROM group_weekly_rates_backup gwrb
    WHERE gwrb.week_start_date = p_week_start_date
    AND gwrb.created_at = backup_time;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true as success,
        format('✅ %s件の週利設定を復元しました（%s）', restored_count, p_week_start_date) as message;
END;
$$;

-- 7. グループ別週利設定関数
DROP FUNCTION IF EXISTS set_group_weekly_rate(DATE, TEXT, NUMERIC);

CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    group_id_var UUID;
    monday_rate NUMERIC;
    tuesday_rate NUMERIC;
    wednesday_rate NUMERIC;
    thursday_rate NUMERIC;
    friday_rate NUMERIC;
BEGIN
    -- グループIDを取得
    SELECT id INTO group_id_var
    FROM daily_rate_groups
    WHERE group_name = p_group_name;
    
    IF group_id_var IS NULL THEN
        RETURN QUERY SELECT 
            false as success,
            format('❌ グループ "%s" が見つかりません', p_group_name) as message;
        RETURN;
    END IF;
    
    -- 週利を平日に分配（月20%, 火25%, 水20%, 木20%, 金15%）
    monday_rate := p_weekly_rate * 0.20;
    tuesday_rate := p_weekly_rate * 0.25;
    wednesday_rate := p_weekly_rate * 0.20;
    thursday_rate := p_weekly_rate * 0.20;
    friday_rate := p_weekly_rate * 0.15;
    
    -- バックアップを作成
    PERFORM admin_create_backup(p_week_start_date, format('グループ別設定前のバックアップ (%s)', NOW()::DATE));
    
    -- 設定を挿入または更新
    INSERT INTO group_weekly_rates (
        id, week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        p_week_start_date,
        p_week_start_date + 6,
        p_weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        group_id_var,
        p_group_name,
        'MANUAL_INPUT',
        NOW(),
        NOW()
    )
    ON CONFLICT (week_start_date, group_id) 
    DO UPDATE SET
        weekly_rate = p_weekly_rate,
        monday_rate = monday_rate,
        tuesday_rate = tuesday_rate,
        wednesday_rate = wednesday_rate,
        thursday_rate = thursday_rate,
        friday_rate = friday_rate,
        distribution_method = 'MANUAL_INPUT',
        updated_at = NOW();
    
    RETURN QUERY SELECT 
        true as success,
        format('✅ %s グループの週利設定を更新しました（%s週、週利%s%%）', p_group_name, p_week_start_date, (p_weekly_rate * 100)::NUMERIC(5,3)) as message;
END;
$$;

-- 8. 関数作成完了確認
SELECT 
    '🔧 完全な管理画面関数作成完了' as status,
    COUNT(*) as created_functions,
    array_agg(routine_name ORDER BY routine_name) as function_names
FROM information_schema.routines 
WHERE routine_name IN (
    'get_system_status',
    'get_weekly_rates_with_groups', 
    'get_backup_list',
    'admin_create_backup',
    'admin_delete_weekly_rates',
    'admin_restore_from_backup',
    'set_group_weekly_rate'
);
