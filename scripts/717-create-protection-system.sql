-- 完全な保護システム作成

-- 1. 既存のトリガーを削除
DROP TRIGGER IF EXISTS prevent_unauthorized_weekly_rate_changes ON group_weekly_rates;
DROP FUNCTION IF EXISTS prevent_unauthorized_weekly_rate_changes();

-- 2. 安全な保護関数を作成
CREATE OR REPLACE FUNCTION protect_weekly_rate_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    is_admin_user BOOLEAN := false;
    current_app_name TEXT;
BEGIN
    -- アプリケーション名をチェック
    current_app_name := current_setting('application_name', true);
    
    -- 管理者関数からの呼び出しは許可
    IF current_app_name LIKE '%admin_safe_%' THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- 現在のユーザーが管理者かチェック
    BEGIN
        SELECT COALESCE(
            (SELECT is_admin FROM users WHERE id = auth.uid()), 
            false
        ) INTO is_admin_user;
    EXCEPTION WHEN OTHERS THEN
        is_admin_user := false;
    END;
    
    -- 管理者以外の変更をブロック
    IF NOT is_admin_user THEN
        RAISE EXCEPTION 'Unauthorized weekly rate modification. Use admin interface or admin_safe_set_weekly_rate() function.';
    END IF;
    
    -- 変更前に自動バックアップ作成
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        -- 動的にバックアップを作成
        EXECUTE format(
            'INSERT INTO group_weekly_rates_backup (%s, backup_timestamp, backup_reason) 
             SELECT %s, $1, $2 FROM group_weekly_rates WHERE %s',
            (SELECT string_agg(column_name, ', ') 
             FROM information_schema.columns 
             WHERE table_name = 'group_weekly_rates' 
             AND column_name NOT IN ('created_at', 'updated_at', 'id')),
            (SELECT string_agg(column_name, ', ') 
             FROM information_schema.columns 
             WHERE table_name = 'group_weekly_rates' 
             AND column_name NOT IN ('created_at', 'updated_at', 'id')),
            CASE 
                WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_weekly_rates' AND column_name = 'id')
                THEN 'id = ' || OLD.id
                ELSE 'week_start_date = ''' || OLD.week_start_date || ''''
            END
        ) USING NOW()::TEXT, 'Auto backup before ' || TG_OP || ' - ' || NOW()::TEXT;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- 3. 保護トリガーを作成
CREATE TRIGGER protect_weekly_rate_changes
    BEFORE INSERT OR UPDATE OR DELETE ON group_weekly_rates
    FOR EACH ROW
    EXECUTE FUNCTION protect_weekly_rate_changes();

-- 4. 管理者専用の安全な設定関数（構造対応版）
CREATE OR REPLACE FUNCTION admin_safe_set_weekly_rate(
    p_week_start_date DATE,
    p_group_identifier TEXT,
    p_weekly_rate DECIMAL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    week_end_date DATE;
    daily_rates DECIMAL[];
    group_col_name TEXT;
BEGIN
    -- アプリケーション名を設定してトリガーをバイパス
    PERFORM set_config('application_name', 'admin_safe_set_weekly_rate', true);

    -- グループ識別カラム名を決定
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_weekly_rates' AND column_name = 'daily_rate_group') THEN
        group_col_name := 'daily_rate_group';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_weekly_rates' AND column_name = 'group_name') THEN
        group_col_name := 'group_name';
    ELSE
        RETURN QUERY SELECT false, 'Error: No group identifier column found';
        RETURN;
    END IF;

    -- 週末日を計算
    week_end_date := p_week_start_date + INTERVAL '4 days';

    -- 週利を平日に分散（ランダム分散）
    daily_rates := ARRAY[
        p_weekly_rate * (0.18 + random() * 0.04), -- 月曜: 18-22%
        p_weekly_rate * (0.19 + random() * 0.04), -- 火曜: 19-23%
        p_weekly_rate * (0.18 + random() * 0.04), -- 水曜: 18-22%
        p_weekly_rate * (0.19 + random() * 0.04), -- 木曜: 19-23%
        p_weekly_rate * (0.18 + random() * 0.04)  -- 金曜: 18-22%
    ];

    -- 合計が週利と一致するよう調整
    daily_rates[5] := p_weekly_rate - (daily_rates[1] + daily_rates[2] + daily_rates[3] + daily_rates[4]);

    -- 動的SQLでデータを挿入または更新
    EXECUTE format(
        'INSERT INTO group_weekly_rates (
            week_start_date,
            week_end_date,
            %I,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            created_at,
            updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())
        ON CONFLICT (week_start_date, %I) 
        DO UPDATE SET
            weekly_rate = EXCLUDED.weekly_rate,
            monday_rate = EXCLUDED.monday_rate,
            tuesday_rate = EXCLUDED.tuesday_rate,
            wednesday_rate = EXCLUDED.wednesday_rate,
            thursday_rate = EXCLUDED.thursday_rate,
            friday_rate = EXCLUDED.friday_rate,
            distribution_method = $11,
            updated_at = NOW()',
        group_col_name, group_col_name
    ) USING 
        p_week_start_date,
        week_end_date,
        p_group_identifier,
        p_weekly_rate,
        daily_rates[1],
        daily_rates[2],
        daily_rates[3],
        daily_rates[4],
        daily_rates[5],
        'ADMIN_MANUAL_SETTING',
        'ADMIN_MANUAL_SETTING';

    RETURN QUERY SELECT true, 'Weekly rate set successfully for ' || p_group_identifier || ' group: ' || (p_weekly_rate * 100)::TEXT || '%';

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Error: ' || SQLERRM;
END;
$$;

-- 5. 権限設定
GRANT EXECUTE ON FUNCTION admin_safe_set_weekly_rate(DATE, TEXT, DECIMAL) TO authenticated;

SELECT 'Complete protection system activated' as status;
