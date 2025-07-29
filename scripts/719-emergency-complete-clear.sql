-- 緊急完全クリア - 全ての週利データを削除して手動設定環境を構築

-- 1. 全ての週利データを完全削除
DO $$
BEGIN
    -- 保護トリガーを一時的に無効化
    DROP TRIGGER IF EXISTS protect_weekly_rate_changes ON group_weekly_rates;
    
    -- 全ての週利データを削除
    DELETE FROM group_weekly_rates;
    DELETE FROM group_weekly_rates_backup;
    
    RAISE NOTICE 'All weekly rate data cleared completely';
END;
$$;

-- 2. 問題のある関数を削除
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP WITHOUT TIME ZONE);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TEXT);

-- 3. シンプルな管理者専用設定関数のみ作成
CREATE OR REPLACE FUNCTION admin_manual_set_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate DECIMAL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    week_end_date DATE;
    daily_rates DECIMAL[];
    target_group_id UUID;
    week_number INTEGER;
BEGIN
    -- 週末日を計算
    week_end_date := p_week_start_date + INTERVAL '4 days';
    
    -- 週番号を計算
    week_number := EXTRACT(week FROM p_week_start_date);

    -- グループIDを特定
    SELECT id INTO target_group_id
    FROM daily_rate_groups
    WHERE group_name = p_group_name
    LIMIT 1;
    
    IF target_group_id IS NULL THEN
        RETURN QUERY SELECT false, 'Error: Group not found: ' || p_group_name;
        RETURN;
    END IF;

    -- 週利を平日に分散（固定分散）
    daily_rates := ARRAY[
        p_weekly_rate * 0.20, -- 月曜: 20%
        p_weekly_rate * 0.20, -- 火曜: 20%
        p_weekly_rate * 0.20, -- 水曜: 20%
        p_weekly_rate * 0.20, -- 木曜: 20%
        p_weekly_rate * 0.20  -- 金曜: 20%
    ];

    -- 既存データを削除してから挿入（重複回避）
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date AND group_id = target_group_id;

    -- 新規挿入
    INSERT INTO group_weekly_rates (
        week_start_date,
        week_end_date,
        week_number,
        group_id,
        group_name,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        created_at,
        updated_at
    ) VALUES (
        p_week_start_date,
        week_end_date,
        week_number,
        target_group_id,
        p_group_name,
        p_weekly_rate,
        daily_rates[1],
        daily_rates[2],
        daily_rates[3],
        daily_rates[4],
        daily_rates[5],
        'MANUAL_ADMIN_SETTING',
        NOW(),
        NOW()
    );

    RETURN QUERY SELECT true, 'Weekly rate set: ' || p_group_name || ' = ' || (p_weekly_rate * 100)::TEXT || '%';

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Error: ' || SQLERRM;
END;
$$;

-- 4. 現在の設定確認関数
CREATE OR REPLACE FUNCTION get_manual_weekly_rates()
RETURNS TABLE(
    week_start_date DATE,
    group_name TEXT,
    weekly_percent DECIMAL,
    status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.group_name,
        (gwr.weekly_rate * 100) as weekly_percent,
        'MANUAL_SET' as status
    FROM group_weekly_rates gwr
    ORDER BY gwr.week_start_date DESC, gwr.group_name;
END;
$$;

-- 5. 全削除関数
CREATE OR REPLACE FUNCTION admin_clear_all_weekly_rates()
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM group_weekly_rates;
    DELETE FROM group_weekly_rates_backup;
    
    RETURN QUERY SELECT true, 'All weekly rates cleared completely';
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Error: ' || SQLERRM;
END;
$$;

-- 6. 権限設定
GRANT EXECUTE ON FUNCTION admin_manual_set_weekly_rate(DATE, TEXT, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION get_manual_weekly_rates() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_clear_all_weekly_rates() TO authenticated;

SELECT 'Emergency complete clear completed - Ready for manual input' as status;
