-- 自動変更の防止

-- 1. 危険な自動復元関数を無効化
DROP FUNCTION IF EXISTS restore_weekly_rates_from_csv_data();

-- 2. 自動変更を防ぐ保護関数を作成
CREATE OR REPLACE FUNCTION protect_manual_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- 手動設定を保護
    IF OLD.distribution_method LIKE '%MANUAL%' 
       AND NEW.distribution_method NOT LIKE '%MANUAL%' THEN
        RAISE EXCEPTION '🚨 手動設定の自動変更は禁止されています';
    END IF;
    
    RETURN NEW;
END;
$$;

-- 3. 保護トリガーを作成
DROP TRIGGER IF EXISTS protect_manual_settings_trigger ON group_weekly_rates;
CREATE TRIGGER protect_manual_settings_trigger
    BEFORE UPDATE ON group_weekly_rates
    FOR EACH ROW
    EXECUTE FUNCTION protect_manual_settings();

-- 4. 管理者専用の安全な設定関数を作成
CREATE OR REPLACE FUNCTION admin_safe_set_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC,
    p_admin_confirmation TEXT DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 管理者確認チェック
    IF p_admin_confirmation != 'ADMIN_CONFIRMED_MANUAL_CHANGE' THEN
        RETURN QUERY SELECT 
            false,
            '❌ 管理者確認が必要です';
        RETURN;
    END IF;
    
    -- バックアップ作成
    INSERT INTO group_weekly_rates_backup (
        original_id,
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
        backup_reason,
        backup_type
    )
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
        gwr.group_id,
        gwr.group_name,
        gwr.distribution_method,
        format('Before manual change by admin at %s', NOW()),
        'manual_protection'
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date
    AND gwr.group_name = p_group_name;
    
    -- 安全な更新
    UPDATE group_weekly_rates
    SET weekly_rate = p_weekly_rate,
        distribution_method = 'ADMIN_MANUAL_SETTING',
        updated_at = NOW()
    WHERE week_start_date = p_week_start_date
    AND group_name = p_group_name;
    
    RETURN QUERY SELECT 
        true,
        format('✅ %sの週利を%s%%に安全に設定しました', p_group_name, p_weekly_rate * 100);
END;
$$;

-- 権限設定
GRANT EXECUTE ON FUNCTION admin_safe_set_weekly_rate(DATE, TEXT, NUMERIC, TEXT) TO authenticated;
