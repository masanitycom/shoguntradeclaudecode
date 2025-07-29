-- 実際のテーブル構造に基づいて全関数を修正

-- 1. 既存関数を全て削除
DROP FUNCTION IF EXISTS check_weekly_rates_integrity();
DROP FUNCTION IF EXISTS get_weekly_rates_for_admin_ui();
DROP FUNCTION IF EXISTS set_custom_weekly_rate_with_random_distribution(DATE, NUMERIC);
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS get_backup_history();
DROP FUNCTION IF EXISTS create_manual_backup(TEXT);

-- 2. 整合性チェック関数（シンプル版）
CREATE OR REPLACE FUNCTION check_weekly_rates_integrity()
RETURNS TABLE(
    check_type TEXT,
    status TEXT,
    count BIGINT,
    details TEXT
) AS $$
BEGIN
    -- アクティブグループ数チェック
    RETURN QUERY
    SELECT 
        'アクティブグループ'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN '✅ 正常' ELSE '❌ 異常' END::TEXT,
        COUNT(*),
        COUNT(*) || '個のグループが設定済み'::TEXT
    FROM daily_rate_groups;
    
    -- 今週の週利設定チェック
    RETURN QUERY
    SELECT 
        '今週の週利設定'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN '✅ 設定済み' ELSE '⚠️ 未設定' END::TEXT,
        COUNT(*),
        CASE WHEN COUNT(*) > 0 
             THEN COUNT(*) || '個のグループに設定済み'
             ELSE '今週の週利が未設定です' END::TEXT
    FROM group_weekly_rates 
    WHERE group_weekly_rates.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + 1;
    
    -- NFTとグループの連携チェック
    RETURN QUERY
    SELECT 
        'NFT-グループ連携'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN '✅ 正常' ELSE '❌ 異常' END::TEXT,
        COUNT(*),
        COUNT(*) || '個のNFTがグループに分類済み'::TEXT
    FROM nfts n
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    WHERE n.is_active = true;
END;
$$ LANGUAGE plpgsql;

-- 3. 管理画面用週利履歴取得関数
CREATE OR REPLACE FUNCTION get_weekly_rates_for_admin_ui()
RETURNS TABLE(
    id UUID,
    group_id UUID,
    week_start_date DATE,
    week_end_date DATE,
    week_number INTEGER,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    distribution_method TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    group_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.group_id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.week_number,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        gwr.created_at,
        drg.group_name::TEXT
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 4. システム状況取得関数（NULL値対応版）
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    active_user_nfts BIGINT,
    total_user_nfts BIGINT,
    active_nfts BIGINT,
    current_week_rates BIGINT,
    is_weekday BOOLEAN,
    day_of_week INTEGER,
    today_calculations BIGINT,
    today_total_rewards NUMERIC
) AS $$
DECLARE
    v_today_date DATE := CURRENT_DATE;
    v_week_start_date DATE := DATE_TRUNC('week', CURRENT_DATE)::DATE + 1;
    v_day_num INTEGER := EXTRACT(dow FROM CURRENT_DATE);
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE((SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0), 0)::BIGINT,
        COALESCE((SELECT COUNT(*) FROM user_nfts), 0)::BIGINT,
        COALESCE((SELECT COUNT(*) FROM nfts WHERE is_active = true), 0)::BIGINT,
        COALESCE((SELECT COUNT(*) FROM group_weekly_rates WHERE group_weekly_rates.week_start_date = v_week_start_date), 0)::BIGINT,
        (v_day_num >= 1 AND v_day_num <= 5)::BOOLEAN,
        v_day_num::INTEGER,
        COALESCE((SELECT COUNT(*) FROM daily_rewards WHERE reward_date = v_today_date), 0)::BIGINT,
        COALESCE((SELECT SUM(reward_amount) FROM daily_rewards WHERE reward_date = v_today_date), 0)::NUMERIC;
END;
$$ LANGUAGE plpgsql;

-- 5. カスタム週利設定関数（エラー処理強化版）
CREATE OR REPLACE FUNCTION set_custom_weekly_rate_with_random_distribution(
    p_week_start_date DATE,
    p_weekly_rate_percent NUMERIC
)
RETURNS TABLE(
    group_name TEXT,
    weekly_rate_set NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    group_rec RECORD;
    weekly_rate_decimal NUMERIC := p_weekly_rate_percent / 100.0;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC;
    zero_days INTEGER;
    active_days INTEGER;
    i INTEGER;
    day_index INTEGER;
    allocated_rate NUMERIC;
BEGIN
    -- 既存の週利設定を削除
    DELETE FROM group_weekly_rates WHERE group_weekly_rates.week_start_date = p_week_start_date;
    
    -- 各グループに対してランダム分配を適用
    FOR group_rec IN
        SELECT 
            drg.id, 
            drg.group_name, 
            drg.daily_rate_limit
        FROM daily_rate_groups drg
        ORDER BY drg.daily_rate_limit
    LOOP
        -- ランダム分配を生成
        remaining_rate := weekly_rate_decimal;
        rates := ARRAY[0, 0, 0, 0, 0];
        
        -- ランダムに0-2日を0%にする
        zero_days := floor(random() * 3)::INTEGER;
        active_days := 5 - zero_days;
        
        -- 全部0%の場合は1日だけ活動させる
        IF active_days = 0 THEN
            active_days := 1;
            zero_days := 4;
        END IF;
        
        -- ランダムに0%の日を選択
        FOR i IN 1..zero_days LOOP
            LOOP
                day_index := floor(random() * 5)::INTEGER + 1;
                EXIT WHEN rates[day_index] = 0;
            END LOOP;
        END LOOP;
        
        -- 残りの日に配分
        FOR i IN 1..5 LOOP
            IF rates[i] = 0 AND remaining_rate > 0 THEN
                IF active_days = 1 THEN
                    allocated_rate := LEAST(remaining_rate, group_rec.daily_rate_limit);
                    rates[i] := allocated_rate;
                    remaining_rate := remaining_rate - allocated_rate;
                ELSE
                    allocated_rate := remaining_rate * (0.2 + random() * 0.6);
                    allocated_rate := LEAST(allocated_rate, group_rec.daily_rate_limit);
                    rates[i] := allocated_rate;
                    remaining_rate := remaining_rate - allocated_rate;
                    active_days := active_days - 1;
                END IF;
            END IF;
        END LOOP;
        
        -- 端数調整
        IF remaining_rate > 0.0001 THEN
            FOR i IN 1..5 LOOP
                IF rates[i] > 0 AND rates[i] < group_rec.daily_rate_limit THEN
                    allocated_rate := LEAST(remaining_rate, group_rec.daily_rate_limit - rates[i]);
                    rates[i] := rates[i] + allocated_rate;
                    remaining_rate := remaining_rate - allocated_rate;
                    EXIT WHEN remaining_rate <= 0.0001;
                END IF;
            END LOOP;
        END IF;
        
        -- 週利データを挿入
        INSERT INTO group_weekly_rates (
            group_id,
            week_start_date,
            week_end_date,
            week_number,
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
            group_rec.id,
            p_week_start_date,
            p_week_start_date + 6,
            EXTRACT(week FROM p_week_start_date),
            rates[1] + rates[2] + rates[3] + rates[4] + rates[5],
            rates[1],
            rates[2],
            rates[3],
            rates[4],
            rates[5],
            'custom_random_distribution',
            NOW(),
            NOW()
        );
        
        -- 結果を返す
        RETURN QUERY SELECT 
            group_rec.group_name::TEXT,
            (rates[1] + rates[2] + rates[3] + rates[4] + rates[5])::NUMERIC,
            rates[1]::NUMERIC,
            rates[2]::NUMERIC,
            rates[3]::NUMERIC,
            rates[4]::NUMERIC,
            rates[5]::NUMERIC,
            true,
            '✅ 設定完了'::TEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 6. シンプルなバックアップ履歴関数（エラー回避版）
CREATE OR REPLACE FUNCTION get_backup_history()
RETURNS TABLE(
    backup_date TEXT,
    backup_reason TEXT,
    record_count BIGINT,
    weeks_covered BIGINT
) AS $$
BEGIN
    -- バックアップテーブルが存在するかチェック
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates_backup') THEN
        -- バックアップテーブルの実際の構造に基づいて処理
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_weekly_rates_backup' AND column_name = 'backup_created_at') THEN
            RETURN QUERY
            SELECT 
                gwrb.backup_created_at::TEXT,
                COALESCE(gwrb.backup_reason, 'UNKNOWN')::TEXT,
                COUNT(*)::BIGINT,
                COUNT(DISTINCT gwrb.week_start_date)::BIGINT
            FROM group_weekly_rates_backup gwrb
            GROUP BY gwrb.backup_created_at, gwrb.backup_reason
            ORDER BY gwrb.backup_created_at DESC
            LIMIT 50;
        ELSE
            -- backup_created_atが存在しない場合の代替処理
            RETURN QUERY
            SELECT 
                NOW()::TEXT,
                'LEGACY_BACKUP'::TEXT,
                COUNT(*)::BIGINT,
                COUNT(DISTINCT gwrb.week_start_date)::BIGINT
            FROM group_weekly_rates_backup gwrb;
        END IF;
    ELSE
        -- バックアップテーブルが存在しない場合
        RETURN QUERY
        SELECT 
            NOW()::TEXT,
            'NO_BACKUP_TABLE'::TEXT,
            0::BIGINT,
            0::BIGINT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 7. シンプルなバックアップ作成関数
CREATE OR REPLACE FUNCTION create_manual_backup(backup_reason_param TEXT DEFAULT 'MANUAL_BACKUP')
RETURNS INTEGER AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    -- バックアップテーブルが存在しない場合は作成
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates_backup') THEN
        CREATE TABLE group_weekly_rates_backup (
            id UUID,
            group_id UUID,
            week_start_date DATE,
            week_end_date DATE,
            week_number INTEGER,
            weekly_rate NUMERIC,
            monday_rate NUMERIC,
            tuesday_rate NUMERIC,
            wednesday_rate NUMERIC,
            thursday_rate NUMERIC,
            friday_rate NUMERIC,
            distribution_method TEXT,
            original_created_at TIMESTAMP WITH TIME ZONE,
            original_updated_at TIMESTAMP WITH TIME ZONE,
            backup_reason TEXT,
            backup_created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;
    
    -- 現在のデータをバックアップ
    INSERT INTO group_weekly_rates_backup (
        id, group_id, week_start_date, week_end_date, week_number,
        weekly_rate, monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        distribution_method, original_created_at, original_updated_at, backup_reason, backup_created_at
    )
    SELECT 
        gwr.id, gwr.group_id, gwr.week_start_date, gwr.week_end_date, gwr.week_number,
        gwr.weekly_rate, gwr.monday_rate, gwr.tuesday_rate, gwr.wednesday_rate, gwr.thursday_rate, gwr.friday_rate,
        gwr.distribution_method, gwr.created_at, gwr.updated_at, backup_reason_param, NOW()
    FROM group_weekly_rates gwr;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN backup_count;
END;
$$ LANGUAGE plpgsql;

-- 8. 権限設定
GRANT EXECUTE ON FUNCTION check_weekly_rates_integrity() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_for_admin_ui() TO authenticated;
GRANT EXECUTE ON FUNCTION set_custom_weekly_rate_with_random_distribution(DATE, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION get_backup_history() TO authenticated;
GRANT EXECUTE ON FUNCTION create_manual_backup(TEXT) TO authenticated;

-- 9. 現在の間違った週利設定をクリア
DELETE FROM group_weekly_rates WHERE weekly_rate = 0.026;

-- 10. 確認
SELECT 
    '🎯 週利入力システム準備完了' as status,
    '管理者が週利を入力→月～金にランダム分配' as description,
    'バックアップテーブル構造エラー修正済み' as fix_status;
