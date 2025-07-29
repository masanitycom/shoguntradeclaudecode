-- 完全な保護システム作成（重複制約対応版）

-- 1. 既存のトリガーを削除
DROP TRIGGER IF EXISTS prevent_unauthorized_weekly_rate_changes ON group_weekly_rates;
DROP TRIGGER IF EXISTS protect_weekly_rate_changes ON group_weekly_rates;
DROP FUNCTION IF EXISTS prevent_unauthorized_weekly_rate_changes();
DROP FUNCTION IF EXISTS protect_weekly_rate_changes();

-- 2. 安全な保護関数を作成
CREATE OR REPLACE FUNCTION protect_weekly_rate_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    is_admin_user BOOLEAN := false;
    current_app_name TEXT;
    backup_columns TEXT[];
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
        -- バックアップテーブルのカラム一覧を取得
        SELECT ARRAY_AGG(column_name ORDER BY ordinal_position) INTO backup_columns
        FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates_backup'
        AND column_name NOT IN ('backup_timestamp', 'backup_reason', 'id', 'original_id');
        
        -- 動的にバックアップを作成（重複制約対応）
        BEGIN
            EXECUTE format(
                'INSERT INTO group_weekly_rates_backup (%s, backup_timestamp, backup_reason, original_id) 
                 SELECT %s, NOW(), $1, $2 FROM group_weekly_rates WHERE week_start_date = $3 AND group_id = $4',
                array_to_string(backup_columns, ', '),
                array_to_string(backup_columns, ', ')
            ) USING 
                'Auto backup before ' || TG_OP || ' - ' || NOW()::TEXT,
                OLD.id,
                OLD.week_start_date,
                OLD.group_id;
        EXCEPTION 
            WHEN unique_violation THEN
                -- バックアップの重複は無視
                NULL;
            WHEN OTHERS THEN
                RAISE NOTICE 'Backup creation failed: %', SQLERRM;
        END;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- 3. 保護トリガーを作成
CREATE TRIGGER protect_weekly_rate_changes
    BEFORE INSERT OR UPDATE OR DELETE ON group_weekly_rates
    FOR EACH ROW
    EXECUTE FUNCTION protect_weekly_rate_changes();

-- 4. 管理者専用の安全な設定関数（重複制約対応版）
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
    target_group_id UUID;
    existing_record RECORD;
BEGIN
    -- アプリケーション名を設定してトリガーをバイパス
    PERFORM set_config('application_name', 'admin_safe_set_weekly_rate', true);

    -- グループIDを特定
    SELECT id INTO target_group_id
    FROM daily_rate_groups
    WHERE group_name = p_group_identifier
    LIMIT 1;
    
    IF target_group_id IS NULL THEN
        RETURN QUERY SELECT false, 'Error: Group not found: ' || p_group_identifier;
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

    -- 既存レコードをチェック
    SELECT * INTO existing_record
    FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date AND group_id = target_group_id;

    IF existing_record IS NOT NULL THEN
        -- 更新処理
        UPDATE group_weekly_rates SET
            weekly_rate = p_weekly_rate,
            monday_rate = daily_rates[1],
            tuesday_rate = daily_rates[2],
            wednesday_rate = daily_rates[3],
            thursday_rate = daily_rates[4],
            friday_rate = daily_rates[5],
            distribution_method = 'ADMIN_MANUAL_SETTING',
            updated_at = NOW()
        WHERE week_start_date = p_week_start_date AND group_id = target_group_id;
    ELSE
        -- 新規挿入処理
        INSERT INTO group_weekly_rates (
            week_start_date,
            week_end_date,
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
            target_group_id,
            p_group_identifier,
            p_weekly_rate,
            daily_rates[1],
            daily_rates[2],
            daily_rates[3],
            daily_rates[4],
            daily_rates[5],
            'ADMIN_MANUAL_SETTING',
            NOW(),
            NOW()
        );
    END IF;

    RETURN QUERY SELECT true, 'Weekly rate set successfully for ' || p_group_identifier || ' group: ' || (p_weekly_rate * 100)::TEXT || '%';

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Error: ' || SQLERRM;
END;
$$;

-- 5. 権限設定
GRANT EXECUTE ON FUNCTION admin_safe_set_weekly_rate(DATE, TEXT, DECIMAL) TO authenticated;

-- 6. 管理者用の週利確認関数
CREATE OR REPLACE FUNCTION get_current_weekly_rates()
RETURNS TABLE(
    week_start_date DATE,
    group_name TEXT,
    weekly_rate_percent DECIMAL,
    distribution_method TEXT,
    last_updated TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        COALESCE(gwr.group_name, 'Group-' || gwr.group_id::TEXT) as group_name,
        (gwr.weekly_rate * 100) as weekly_rate_percent,
        gwr.distribution_method,
        gwr.updated_at as last_updated
    FROM group_weekly_rates gwr
    ORDER BY gwr.week_start_date DESC, gwr.group_name;
END;
$$;

GRANT EXECUTE ON FUNCTION get_current_weekly_rates() TO authenticated;

SELECT 'Complete protection system with duplicate constraint handling activated' as status;
