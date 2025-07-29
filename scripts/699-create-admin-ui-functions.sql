-- 管理画面用関数の作成

-- 1. システム状況取得関数
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    category TEXT,
    item TEXT,
    value TEXT,
    status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 週利設定状況
    RETURN QUERY
    SELECT 
        '週利設定'::TEXT as category,
        '現在週の設定'::TEXT as item,
        format('%s グループ設定済み', COUNT(*))::TEXT as value,
        CASE WHEN COUNT(*) > 0 THEN '正常' ELSE '要設定' END as status
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date <= CURRENT_DATE
    AND gwr.week_start_date + 6 >= CURRENT_DATE;
    
    -- 日利計算状況
    RETURN QUERY
    SELECT 
        '日利計算'::TEXT as category,
        '今日の計算'::TEXT as item,
        format('%s 件計算済み', COUNT(*))::TEXT as value,
        CASE WHEN COUNT(*) > 0 THEN '完了' ELSE '未実行' END as status
    FROM daily_rewards
    WHERE reward_date = CURRENT_DATE;
    
    -- アクティブNFT数
    RETURN QUERY
    SELECT 
        'NFT状況'::TEXT as category,
        'アクティブNFT'::TEXT as item,
        format('%s 個', COUNT(*))::TEXT as value,
        CASE WHEN COUNT(*) > 0 THEN '正常' ELSE 'NFTなし' END as status
    FROM user_nfts
    WHERE is_active = true;
END;
$$;

-- 2. 週利設定取得関数
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    week_start_date DATE,
    week_end_date DATE,
    group_name TEXT,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    distribution_method TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.group_name,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method
    FROM group_weekly_rates gwr
    ORDER BY gwr.week_start_date DESC, gwr.group_name;
END;
$$;

-- 3. バックアップ一覧取得関数
CREATE OR REPLACE FUNCTION get_backup_history()
RETURNS TABLE(
    backup_date TIMESTAMP,
    week_start_date DATE,
    group_name TEXT,
    weekly_rate NUMERIC,
    backup_reason TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.created_at as backup_date,
        gwrb.week_start_date,
        gwrb.group_name,
        gwrb.weekly_rate,
        COALESCE(gwrb.backup_reason, 'システムバックアップ')::TEXT as backup_reason
    FROM group_weekly_rates_backup gwrb
    ORDER BY gwrb.created_at DESC
    LIMIT 100;
END;
$$;

-- 4. 週利設定関数
CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_id UUID,
    p_weekly_rate NUMERIC,
    p_monday_rate NUMERIC,
    p_tuesday_rate NUMERIC,
    p_wednesday_rate NUMERIC,
    p_thursday_rate NUMERIC,
    p_friday_rate NUMERIC
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    group_name_var TEXT;
BEGIN
    -- グループ名を取得
    SELECT drg.group_name INTO group_name_var
    FROM daily_rate_groups drg
    WHERE drg.id = p_group_id;
    
    IF group_name_var IS NULL THEN
        RETURN '❌ 指定されたグループが見つかりません';
    END IF;
    
    -- 既存の設定をバックアップ
    INSERT INTO group_weekly_rates_backup (
        id, week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, backup_reason, created_at
    )
    SELECT 
        gen_random_uuid(), week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, 
        format('手動設定前のバックアップ (%s)', NOW()::DATE), NOW()
    FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date AND group_id = p_group_id;
    
    -- 新しい設定を挿入または更新
    INSERT INTO group_weekly_rates (
        id, week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        p_week_start_date,
        p_week_start_date + 6,
        p_weekly_rate,
        p_monday_rate,
        p_tuesday_rate,
        p_wednesday_rate,
        p_thursday_rate,
        p_friday_rate,
        p_group_id,
        group_name_var,
        'MANUAL_INPUT',
        NOW(),
        NOW()
    )
    ON CONFLICT (week_start_date, group_id) 
    DO UPDATE SET
        weekly_rate = p_weekly_rate,
        monday_rate = p_monday_rate,
        tuesday_rate = p_tuesday_rate,
        wednesday_rate = p_wednesday_rate,
        thursday_rate = p_thursday_rate,
        friday_rate = p_friday_rate,
        distribution_method = 'MANUAL_INPUT',
        updated_at = NOW();
    
    RETURN format('✅ %s グループの週利設定を更新しました（%s週）', group_name_var, p_week_start_date);
END;
$$;

-- 5. 週利設定削除関数
CREATE OR REPLACE FUNCTION delete_weekly_rates(
    p_week_start_date DATE,
    p_group_id UUID DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- バックアップを作成
    INSERT INTO group_weekly_rates_backup (
        id, week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, backup_reason, created_at
    )
    SELECT 
        gen_random_uuid(), week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        group_id, group_name, distribution_method, 
        format('削除前のバックアップ (%s)', NOW()::DATE), NOW()
    FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date 
    AND (p_group_id IS NULL OR group_id = p_group_id);
    
    -- 削除実行
    DELETE FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date 
    AND (p_group_id IS NULL OR group_id = p_group_id);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN format('✅ %s件の週利設定を削除しました（%s週）', deleted_count, p_week_start_date);
END;
$$;

-- 6. 関数作成完了確認
SELECT 
    '🔧 管理画面関数作成完了' as status,
    COUNT(*) as created_functions
FROM information_schema.routines 
WHERE routine_name IN (
    'get_system_status',
    'get_weekly_rates_with_groups', 
    'get_backup_history',
    'set_group_weekly_rate',
    'delete_weekly_rates'
);
