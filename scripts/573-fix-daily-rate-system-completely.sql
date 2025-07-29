-- 🔧 日利設定システム完全修正
-- バックアップ関数、週利設定、日利計算の全面修正

-- 1. バックアップ関数の修正
DROP FUNCTION IF EXISTS get_backup_history();
DROP FUNCTION IF EXISTS create_manual_backup(text);

-- バックアップ履歴テーブルの作成（存在しない場合）
CREATE TABLE IF NOT EXISTS weekly_rates_backup (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    backup_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    backup_reason TEXT NOT NULL,
    original_data JSONB NOT NULL,
    record_count INTEGER NOT NULL,
    weeks_covered INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- バックアップ履歴取得関数
CREATE OR REPLACE FUNCTION get_backup_history()
RETURNS TABLE(
    backup_date TEXT,
    backup_reason TEXT,
    record_count INTEGER,
    weeks_covered INTEGER
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(wrb.backup_date, 'YYYY-MM-DD HH24:MI:SS') as backup_date,
        wrb.backup_reason,
        wrb.record_count,
        wrb.weeks_covered
    FROM weekly_rates_backup wrb
    ORDER BY wrb.backup_date DESC
    LIMIT 50;
END;
$$;

-- 手動バックアップ作成関数
CREATE OR REPLACE FUNCTION create_manual_backup(backup_reason TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    backup_count INTEGER;
    weeks_count INTEGER;
    backup_data JSONB;
BEGIN
    -- 現在の週利設定をJSONBで取得
    SELECT 
        jsonb_agg(
            jsonb_build_object(
                'id', gwr.id,
                'group_id', gwr.group_id,
                'week_start_date', gwr.week_start_date,
                'week_end_date', gwr.week_end_date,
                'weekly_rate', gwr.weekly_rate,
                'monday_rate', gwr.monday_rate,
                'tuesday_rate', gwr.tuesday_rate,
                'wednesday_rate', gwr.wednesday_rate,
                'thursday_rate', gwr.thursday_rate,
                'friday_rate', gwr.friday_rate,
                'distribution_method', gwr.distribution_method
            )
        ),
        COUNT(*),
        COUNT(DISTINCT week_start_date)
    INTO backup_data, backup_count, weeks_count
    FROM group_weekly_rates gwr;
    
    -- バックアップレコードを挿入
    INSERT INTO weekly_rates_backup (
        backup_reason,
        original_data,
        record_count,
        weeks_covered
    ) VALUES (
        backup_reason,
        COALESCE(backup_data, '[]'::jsonb),
        COALESCE(backup_count, 0),
        COALESCE(weeks_count, 0)
    );
    
    RETURN COALESCE(backup_count, 0);
END;
$$;

-- 2. 日利計算関数の完全修正
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch(DATE);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch(p_calculation_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    calculation_date TEXT,
    processed_count INTEGER,
    total_rewards NUMERIC,
    completed_nfts INTEGER,
    error_message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_processed_count INTEGER := 0;
    v_total_rewards NUMERIC := 0;
    v_completed_nfts INTEGER := 0;
    v_error_message TEXT := NULL;
    v_day_of_week INTEGER;
    v_is_weekday BOOLEAN;
    user_nft_record RECORD;
    v_daily_rate NUMERIC;
    v_reward_amount NUMERIC;
    v_new_total NUMERIC;
    v_week_start_date DATE;
BEGIN
    -- 曜日チェック（1=月曜日, 5=金曜日）
    v_day_of_week := EXTRACT(DOW FROM p_calculation_date);
    v_is_weekday := v_day_of_week BETWEEN 1 AND 5;
    
    IF NOT v_is_weekday THEN
        RETURN QUERY SELECT 
            p_calculation_date::TEXT,
            0,
            0::NUMERIC,
            0,
            '土日は日利計算を行いません'::TEXT;
        RETURN;
    END IF;
    
    -- 週の開始日を計算（月曜日）
    v_week_start_date := p_calculation_date - (v_day_of_week - 1);
    
    -- アクティブなuser_nftsを処理
    FOR user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.current_investment,
            un.total_rewards_received,
            n.daily_rate_limit,
            n.name as nft_name
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        WHERE un.is_active = true 
        AND un.current_investment > 0
        AND n.is_active = true
        AND un.total_rewards_received < (un.current_investment * 3) -- 300%チェック
    LOOP
        -- その日の日利を取得
        SELECT 
            CASE v_day_of_week
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END
        INTO v_daily_rate
        FROM group_weekly_rates gwr
        JOIN daily_rate_groups drg ON gwr.group_id = drg.id
        WHERE drg.daily_rate_limit = user_nft_record.daily_rate_limit
        AND gwr.week_start_date = v_week_start_date;
        
        -- 日利が設定されていない場合はスキップ
        IF v_daily_rate IS NULL OR v_daily_rate = 0 THEN
            CONTINUE;
        END IF;
        
        -- 報酬額を計算
        v_reward_amount := user_nft_record.current_investment * v_daily_rate;
        
        -- 300%上限チェック
        v_new_total := user_nft_record.total_rewards_received + v_reward_amount;
        IF v_new_total > (user_nft_record.current_investment * 3) THEN
            v_reward_amount := (user_nft_record.current_investment * 3) - user_nft_record.total_rewards_received;
            IF v_reward_amount <= 0 THEN
                CONTINUE;
            END IF;
        END IF;
        
        -- 既存の報酬レコードをチェック
        IF NOT EXISTS (
            SELECT 1 FROM daily_rewards 
            WHERE user_nft_id = user_nft_record.user_nft_id 
            AND reward_date = p_calculation_date
        ) THEN
            -- 日利報酬を記録
            INSERT INTO daily_rewards (
                user_id,
                user_nft_id,
                nft_id,
                reward_date,
                reward_amount,
                daily_rate_applied,
                investment_amount,
                reward_type
            ) VALUES (
                user_nft_record.user_id,
                user_nft_record.user_nft_id,
                user_nft_record.nft_id,
                p_calculation_date,
                v_reward_amount,
                v_daily_rate,
                user_nft_record.current_investment,
                'DAILY_REWARD'
            );
            
            -- user_nftsの累計報酬を更新
            UPDATE user_nfts 
            SET 
                total_rewards_received = total_rewards_received + v_reward_amount,
                updated_at = NOW()
            WHERE id = user_nft_record.user_nft_id;
            
            -- 300%達成チェック
            IF (user_nft_record.total_rewards_received + v_reward_amount) >= (user_nft_record.current_investment * 3) THEN
                UPDATE user_nfts 
                SET 
                    is_active = false,
                    completion_date = p_calculation_date,
                    updated_at = NOW()
                WHERE id = user_nft_record.user_nft_id;
                
                v_completed_nfts := v_completed_nfts + 1;
            END IF;
            
            v_processed_count := v_processed_count + 1;
            v_total_rewards := v_total_rewards + v_reward_amount;
        END IF;
    END LOOP;
    
    -- 結果を返す
    RETURN QUERY SELECT 
        p_calculation_date::TEXT,
        v_processed_count,
        v_total_rewards,
        v_completed_nfts,
        v_error_message;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        p_calculation_date::TEXT,
        0,
        0::NUMERIC,
        0,
        SQLERRM::TEXT;
END;
$$;

-- 3. 週利設定関数の修正
DROP FUNCTION IF EXISTS set_weekly_rates_for_all_groups(NUMERIC, DATE);

CREATE OR REPLACE FUNCTION set_weekly_rates_for_all_groups(
    p_weekly_rate NUMERIC,
    p_week_start_date DATE DEFAULT NULL
)
RETURNS TABLE(
    group_name TEXT,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    status TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_week_start_date DATE;
    v_week_end_date DATE;
    v_week_number INTEGER;
    group_record RECORD;
    v_rates RECORD;
BEGIN
    -- 週の開始日を設定（デフォルトは今週の月曜日）
    IF p_week_start_date IS NULL THEN
        v_week_start_date := DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
    ELSE
        v_week_start_date := p_week_start_date;
    END IF;
    
    v_week_end_date := v_week_start_date + INTERVAL '6 days';
    v_week_number := EXTRACT(WEEK FROM v_week_start_date);
    
    -- 既存の週利設定を削除
    DELETE FROM group_weekly_rates WHERE week_start_date = v_week_start_date;
    
    -- ランダム配分を生成
    SELECT * INTO v_rates FROM generate_synchronized_weekly_distribution(p_weekly_rate);
    
    -- 各グループに週利を設定
    FOR group_record IN
        SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit
    LOOP
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
            distribution_method
        ) VALUES (
            group_record.id,
            v_week_start_date,
            v_week_end_date,
            v_week_number,
            p_weekly_rate,
            v_rates.monday_rate,
            v_rates.tuesday_rate,
            v_rates.wednesday_rate,
            v_rates.thursday_rate,
            v_rates.friday_rate,
            'RANDOM_SYNCHRONIZED'
        );
        
        RETURN QUERY SELECT 
            group_record.group_name,
            p_weekly_rate,
            v_rates.monday_rate,
            v_rates.tuesday_rate,
            v_rates.wednesday_rate,
            v_rates.thursday_rate,
            v_rates.friday_rate,
            'SUCCESS'::TEXT;
    END LOOP;
END;
$$;

-- 4. ランダム配分関数の修正
DROP FUNCTION IF EXISTS generate_synchronized_weekly_distribution(NUMERIC);

CREATE OR REPLACE FUNCTION generate_synchronized_weekly_distribution(p_weekly_rate NUMERIC)
RETURNS TABLE(
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rates NUMERIC[5] := ARRAY[0,0,0,0,0];
    v_zero_days INTEGER;
    v_zero_indices INTEGER[];
    v_active_days INTEGER;
    v_base_rate NUMERIC;
    v_current_total NUMERIC;
    v_adjustment_factor NUMERIC;
    i INTEGER;
BEGIN
    -- 0%の日を1-2日ランダムに選択
    v_zero_days := 1 + (RANDOM() * 2)::INTEGER; -- 1または2日
    
    -- ランダムなインデックスを選択
    WHILE array_length(v_zero_indices, 1) < v_zero_days OR v_zero_indices IS NULL LOOP
        i := 1 + (RANDOM() * 5)::INTEGER;
        IF NOT (i = ANY(v_zero_indices)) THEN
            v_zero_indices := array_append(v_zero_indices, i);
        END IF;
    END LOOP;
    
    -- アクティブな日数を計算
    v_active_days := 5 - v_zero_days;
    
    IF v_active_days > 0 THEN
        v_base_rate := p_weekly_rate / v_active_days;
        
        -- 各日に基本レートを設定（0%の日以外）
        FOR i IN 1..5 LOOP
            IF NOT (i = ANY(v_zero_indices)) THEN
                -- ±20%の範囲でランダム調整
                v_rates[i] := v_base_rate * (0.8 + RANDOM() * 0.4);
            END IF;
        END LOOP;
        
        -- 合計を週利に調整
        v_current_total := 0;
        FOR i IN 1..5 LOOP
            v_current_total := v_current_total + v_rates[i];
        END LOOP;
        
        IF v_current_total > 0 THEN
            v_adjustment_factor := p_weekly_rate / v_current_total;
            FOR i IN 1..5 LOOP
                IF NOT (i = ANY(v_zero_indices)) THEN
                    v_rates[i] := v_rates[i] * v_adjustment_factor;
                END IF;
            END LOOP;
        END IF;
    END IF;
    
    RETURN QUERY SELECT 
        v_rates[1],
        v_rates[2], 
        v_rates[3],
        v_rates[4],
        v_rates[5];
END;
$$;

-- 5. 管理画面用の関数修正
DROP FUNCTION IF EXISTS get_weekly_rates_for_admin_ui();

CREATE OR REPLACE FUNCTION get_weekly_rates_for_admin_ui()
RETURNS TABLE(
    id UUID,
    group_id UUID,
    group_name TEXT,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    distribution_method TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.group_id,
        drg.group_name,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$;

-- 6. システム状況確認関数
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    active_user_nfts INTEGER,
    total_user_nfts INTEGER,
    active_nfts INTEGER,
    current_week_rates INTEGER,
    is_weekday BOOLEAN,
    day_of_week INTEGER,
    today_calculations INTEGER,
    today_total_rewards NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_week_start_date DATE;
    v_day_of_week INTEGER;
BEGIN
    v_day_of_week := EXTRACT(DOW FROM CURRENT_DATE);
    v_week_start_date := CURRENT_DATE - (v_day_of_week - 1);
    
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true AND current_investment > 0),
        (SELECT COUNT(*)::INTEGER FROM user_nfts),
        (SELECT COUNT(*)::INTEGER FROM nfts WHERE is_active = true),
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates WHERE week_start_date = v_week_start_date),
        (v_day_of_week BETWEEN 1 AND 5),
        v_day_of_week,
        (SELECT COUNT(*)::INTEGER FROM daily_rewards WHERE reward_date = CURRENT_DATE),
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date = CURRENT_DATE);
END;
$$;

-- 初期バックアップを作成
SELECT create_manual_backup('SYSTEM_REPAIR_INITIAL_BACKUP');

-- 修正完了確認
SELECT 
    '✅ 修正完了確認' as status,
    (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as today_calculations,
    (SELECT COALESCE(SUM(reward_amount), 0)::TEXT FROM daily_rewards WHERE reward_date = CURRENT_DATE) as total_rewards;
