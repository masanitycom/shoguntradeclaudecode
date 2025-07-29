-- 管理画面用関数の更新

-- 1. システム状況取得関数の更新
DROP FUNCTION IF EXISTS get_system_status();

CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_rewards DECIMAL(10,2),
    last_calculation TEXT,
    current_week_rates INTEGER,
    total_backups INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users WHERE is_active = true) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as active_nfts,
        (SELECT COALESCE(SUM(reward_amount), 0)::DECIMAL(10,2) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as pending_rewards,
        (SELECT COALESCE(MAX(created_at)::TEXT, '未実行') FROM daily_rewards) as last_calculation,
        (SELECT COUNT(DISTINCT week_start_date)::INTEGER FROM group_weekly_rates) as current_week_rates,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates_backup) as total_backups;
END;
$$;

-- 2. 週利設定取得関数の更新
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();

CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    id UUID,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate DECIMAL(10,6),
    monday_rate DECIMAL(10,6),
    tuesday_rate DECIMAL(10,6),
    wednesday_rate DECIMAL(10,6),
    thursday_rate DECIMAL(10,6),
    friday_rate DECIMAL(10,6),
    group_name TEXT,
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
        COALESCE(gwr.week_end_date, gwr.week_start_date + 6) as week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        COALESCE(gwr.group_name, drg.group_name, '不明') as group_name,
        COALESCE(gwr.distribution_method, 'manual') as distribution_method,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date
        ) as has_backup
    FROM group_weekly_rates gwr
    LEFT JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$;

-- 3. 週利削除関数
CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual deletion from admin UI'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    deleted_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- まずバックアップを作成
    PERFORM admin_create_backup(p_week_start_date, 'Before deletion: ' || p_reason);
    
    -- データを削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('✅ %sの週利設定を%s件削除しました（バックアップ済み）', p_week_start_date::TEXT, deleted_count),
        deleted_count;
END;
$$;

-- 4. グループ別週利設定関数
CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate DECIMAL(10,6)
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    group_id_var UUID;
    week_end_date DATE;
BEGIN
    -- グループIDを取得
    SELECT id INTO group_id_var
    FROM daily_rate_groups
    WHERE group_name = p_group_name;
    
    IF group_id_var IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('❌ グループ "%s" が見つかりません', p_group_name);
        RETURN;
    END IF;
    
    week_end_date := p_week_start_date + 6;
    
    -- 週利設定を挿入または更新
    INSERT INTO group_weekly_rates (
        id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        group_id,
        group_name,
        distribution_method,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        p_week_start_date,
        week_end_date,
        p_weekly_rate / 100.0, -- パーセントから小数に変換
        (p_weekly_rate / 100.0) * 0.20, -- 月曜日 20%
        (p_weekly_rate / 100.0) * 0.25, -- 火曜日 25%
        (p_weekly_rate / 100.0) * 0.20, -- 水曜日 20%
        (p_weekly_rate / 100.0) * 0.20, -- 木曜日 20%
        (p_weekly_rate / 100.0) * 0.15, -- 金曜日 15%
        group_id_var,
        p_group_name,
        'ADMIN_UI_SETTING',
        NOW(),
        NOW()
    )
    ON CONFLICT (week_start_date, group_id) 
    DO UPDATE SET
        weekly_rate = EXCLUDED.weekly_rate,
        monday_rate = EXCLUDED.monday_rate,
        tuesday_rate = EXCLUDED.tuesday_rate,
        wednesday_rate = EXCLUDED.wednesday_rate,
        thursday_rate = EXCLUDED.thursday_rate,
        friday_rate = EXCLUDED.friday_rate,
        distribution_method = EXCLUDED.distribution_method,
        updated_at = NOW();
    
    RETURN QUERY SELECT 
        true,
        format('✅ %s の %s に週利 %s%% を設定しました', p_group_name, p_week_start_date::TEXT, p_weekly_rate);
END;
$$;

-- 権限設定
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_with_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_delete_weekly_rates(DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION set_group_weekly_rate(DATE, TEXT, DECIMAL) TO authenticated;
