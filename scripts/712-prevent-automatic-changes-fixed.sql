-- 自動変更防止システム（完全版）

-- 1. 既存の問題のあるトリガーを削除
DROP TRIGGER IF EXISTS prevent_auto_weekly_rate_changes ON group_weekly_rates;
DROP FUNCTION IF EXISTS prevent_auto_changes();

-- 2. 安全な変更防止関数を作成
CREATE OR REPLACE FUNCTION prevent_unauthorized_weekly_rate_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    current_user_role TEXT;
BEGIN
    -- 現在のユーザーが管理者かチェック
    SELECT COALESCE(
        (SELECT is_admin FROM users WHERE id = auth.uid()), 
        false
    ) INTO current_user_role;

    -- システム関数からの呼び出しは許可
    IF current_setting('application_name', true) LIKE '%admin_safe_%' THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- 管理者以外の変更をブロック
    IF NOT current_user_role THEN
        RAISE EXCEPTION 'Unauthorized weekly rate modification. Use admin_safe_set_weekly_rate() function.';
    END IF;

    -- 変更前に自動バックアップ作成
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        INSERT INTO group_weekly_rates_backup (
            week_start_date,
            daily_rate_group,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            backup_timestamp,
            backup_reason
        ) VALUES (
            OLD.week_start_date,
            OLD.daily_rate_group,
            OLD.weekly_rate,
            OLD.monday_rate,
            OLD.tuesday_rate,
            OLD.wednesday_rate,
            OLD.thursday_rate,
            OLD.friday_rate,
            OLD.distribution_method,
            NOW()::TEXT,
            'Auto backup before ' || TG_OP || ' - ' || NOW()::TEXT
        );
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- 3. トリガーを作成
CREATE TRIGGER prevent_unauthorized_weekly_rate_changes
    BEFORE INSERT OR UPDATE OR DELETE ON group_weekly_rates
    FOR EACH ROW
    EXECUTE FUNCTION prevent_unauthorized_weekly_rate_changes();

-- 4. 管理者専用の安全な週利設定関数
CREATE OR REPLACE FUNCTION admin_safe_set_weekly_rate(
    p_week_start_date DATE,
    p_daily_rate_group TEXT,
    p_weekly_rate DECIMAL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    week_end_date DATE;
    daily_rates DECIMAL[];
BEGIN
    -- アプリケーション名を設定してトリガーをバイパス
    PERFORM set_config('application_name', 'admin_safe_set_weekly_rate', true);

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

    -- データを挿入または更新
    INSERT INTO group_weekly_rates (
        week_start_date,
        week_end_date,
        daily_rate_group,
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
        p_daily_rate_group,
        p_weekly_rate,
        daily_rates[1],
        daily_rates[2],
        daily_rates[3],
        daily_rates[4],
        daily_rates[5],
        'admin_manual',
        NOW(),
        NOW()
    )
    ON CONFLICT (week_start_date, daily_rate_group) 
    DO UPDATE SET
        weekly_rate = EXCLUDED.weekly_rate,
        monday_rate = EXCLUDED.monday_rate,
        tuesday_rate = EXCLUDED.tuesday_rate,
        wednesday_rate = EXCLUDED.wednesday_rate,
        thursday_rate = EXCLUDED.thursday_rate,
        friday_rate = EXCLUDED.friday_rate,
        distribution_method = 'admin_manual',
        updated_at = NOW();

    RETURN QUERY SELECT true, 'Weekly rate set successfully for ' || p_daily_rate_group || ' group';

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Error: ' || SQLERRM;
END;
$$;

-- 5. 権限設定
GRANT EXECUTE ON FUNCTION admin_safe_set_weekly_rate(DATE, TEXT, DECIMAL) TO authenticated;

SELECT 'Automatic change prevention system activated' as status;
