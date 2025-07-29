-- 不足している関数を作成し、週利入力システムを修正

-- 1. 整合性チェック関数を作成
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
    WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + 1;
    
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
    
    -- バックアップ状況チェック
    RETURN QUERY
    SELECT 
        'バックアップ状況'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN '✅ 利用可能' ELSE '⚠️ なし' END::TEXT,
        COUNT(*),
        CASE WHEN COUNT(*) > 0 
             THEN COUNT(*) || '件のバックアップが利用可能'
             ELSE 'バックアップがありません' END::TEXT
    FROM group_weekly_rates_backup;
END;
$$ LANGUAGE plpgsql;

-- 2. 管理画面用週利履歴取得関数を修正
DROP FUNCTION IF EXISTS get_weekly_rates_for_admin_ui();

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

-- 3. 管理者入力週利をランダム分配する関数（カラム参照の曖昧性を修正）
CREATE OR REPLACE FUNCTION set_custom_weekly_rate_with_random_distribution(
    p_week_start_date DATE,
    p_weekly_rate_percent NUMERIC  -- 例: 2.6 (2.6%の意味)
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
    weekly_rate_decimal NUMERIC := p_weekly_rate_percent / 100.0;  -- パーセントを小数に変換
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC;
    zero_days INTEGER;
    active_days INTEGER;
    i INTEGER;
    day_index INTEGER;
    allocated_rate NUMERIC;
    backup_count INTEGER;
BEGIN
    -- 事前バックアップ作成
    SELECT create_manual_backup('BEFORE_CUSTOM_WEEKLY_RATE_SETTING') INTO backup_count;
    
    -- 既存の週利設定を削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- 各グループに対してランダム分配を適用（カラム参照の曖昧性を解決）
    FOR group_rec IN
        SELECT 
            drg.id as group_id, 
            drg.group_name as group_name_val, 
            drg.daily_rate_limit as daily_rate_limit_val
        FROM daily_rate_groups drg
        ORDER BY drg.daily_rate_limit
    LOOP
        -- ランダム分配を生成
        remaining_rate := weekly_rate_decimal;
        rates := ARRAY[0, 0, 0, 0, 0];
        
        -- ランダムに0-2日を0%にする
        zero_days := floor(random() * 3)::INTEGER; -- 0, 1, 2日
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
                EXIT WHEN rates[day_index] = 0; -- まだ0%に設定されていない日
            END LOOP;
        END LOOP;
        
        -- 残りの日に配分（グループの日利上限を考慮）
        FOR i IN 1..5 LOOP
            IF rates[i] = 0 AND remaining_rate > 0 THEN
                -- この日が活動日の場合
                IF active_days = 1 THEN
                    -- 最後の活動日なら残り全部（ただし上限チェック）
                    allocated_rate := LEAST(remaining_rate, group_rec.daily_rate_limit_val);
                    rates[i] := allocated_rate;
                    remaining_rate := remaining_rate - allocated_rate;
                ELSE
                    -- ランダムに配分（残りの20%-80%、ただし上限チェック）
                    allocated_rate := remaining_rate * (0.2 + random() * 0.6);
                    allocated_rate := LEAST(allocated_rate, group_rec.daily_rate_limit_val);
                    rates[i] := allocated_rate;
                    remaining_rate := remaining_rate - allocated_rate;
                    active_days := active_days - 1;
                END IF;
            END IF;
        END LOOP;
        
        -- 端数調整（まだ上限に達していない日に追加）
        IF remaining_rate > 0.0001 THEN
            FOR i IN 1..5 LOOP
                IF rates[i] > 0 AND rates[i] < group_rec.daily_rate_limit_val THEN
                    allocated_rate := LEAST(remaining_rate, group_rec.daily_rate_limit_val - rates[i]);
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
            group_rec.group_id,
            p_week_start_date,
            p_week_start_date + 6,
            EXTRACT(week FROM p_week_start_date),
            rates[1] + rates[2] + rates[3] + rates[4] + rates[5], -- 実際の週利合計
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
            group_rec.group_name_val::TEXT,
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

-- 4. 権限設定
GRANT EXECUTE ON FUNCTION check_weekly_rates_integrity() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_for_admin_ui() TO authenticated;
GRANT EXECUTE ON FUNCTION set_custom_weekly_rate_with_random_distribution(DATE, NUMERIC) TO authenticated;

-- 5. 現在の間違った週利設定をクリア
DELETE FROM group_weekly_rates WHERE weekly_rate = 0.026; -- 2.6%固定のものを削除

-- 6. 確認
SELECT 
    '🎯 週利入力システム準備完了' as status,
    '管理者が週利を入力→月～金にランダム分配' as description,
    '既存の間違った設定をクリア済み' as cleanup_status;
