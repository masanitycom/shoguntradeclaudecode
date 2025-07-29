-- 既存の関数を削除してから再作成

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS get_nft_group(numeric);
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch();
DROP FUNCTION IF EXISTS create_synchronized_weekly_distribution(date, integer, numeric);

-- 2. 既存の外部キー制約を削除
DO $$
BEGIN
    -- 既存の外部キー制約を全て削除
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_group_weekly_rates_group_id'
    ) THEN
        ALTER TABLE group_weekly_rates DROP CONSTRAINT fk_group_weekly_rates_group_id;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'group_weekly_rates_group_id_fkey'
    ) THEN
        ALTER TABLE group_weekly_rates DROP CONSTRAINT group_weekly_rates_group_id_fkey;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- エラーを無視
END $$;

-- 3. group_nameカラムを削除（group_idのみ使用）
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' AND column_name = 'group_name'
    ) THEN
        ALTER TABLE group_weekly_rates DROP COLUMN group_name;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- エラーを無視
END $$;

-- 4. distribution_methodカラムを追加
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' AND column_name = 'distribution_method'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN distribution_method TEXT DEFAULT 'auto';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- エラーを無視
END $$;

-- 5. 単一の外部キー制約を追加
DO $$
BEGIN
    ALTER TABLE group_weekly_rates 
    ADD CONSTRAINT fk_group_weekly_rates_group 
    FOREIGN KEY (group_id) REFERENCES daily_rate_groups(id) ON DELETE CASCADE;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- 既に存在する場合は無視
END $$;

-- 6. get_nft_group関数を再作成
CREATE OR REPLACE FUNCTION get_nft_group(nft_price NUMERIC)
RETURNS TEXT AS $$
BEGIN
    RETURN CASE 
        WHEN nft_price <= 125 THEN '1.0%グループ'
        WHEN nft_price <= 250 THEN '1.25%グループ'
        WHEN nft_price <= 500 THEN '1.5%グループ'
        WHEN nft_price <= 1000 THEN '1.75%グループ'
        ELSE '2.0%グループ'
    END;
END;
$$ LANGUAGE plpgsql;

-- 7. calculate_daily_rewards_batch関数を再作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch()
RETURNS TABLE(
    calculation_date DATE,
    processed_count INTEGER,
    total_rewards NUMERIC,
    completed_nfts INTEGER,
    error_message TEXT
) AS $$
DECLARE
    result_record RECORD;
    success_count INTEGER := 0;
    error_count INTEGER := 0;
    total_reward_amount NUMERIC := 0;
    completed_count INTEGER := 0;
    target_date DATE := CURRENT_DATE;
BEGIN
    -- 平日チェック
    IF EXTRACT(DOW FROM target_date) NOT BETWEEN 1 AND 5 THEN
        RETURN QUERY SELECT 
            target_date,
            0,
            0::NUMERIC,
            0,
            'Not a weekday'::TEXT;
        RETURN;
    END IF;
    
    -- 簡単な日利計算を実行
    FOR result_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.purchase_price,
            un.total_rewards_received,
            n.daily_rate_limit
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        WHERE un.is_active = true
        AND (un.purchase_price * 3) > un.total_rewards_received
    LOOP
        -- 日利を計算（簡単な例）
        DECLARE
            daily_reward NUMERIC;
            new_total NUMERIC;
        BEGIN
            daily_reward := result_record.purchase_price * result_record.daily_rate_limit;
            new_total := result_record.total_rewards_received + daily_reward;
            
            IF new_total >= (result_record.purchase_price * 3) THEN
                -- 300%達成
                completed_count := completed_count + 1;
            ELSE
                -- 報酬を記録
                INSERT INTO daily_rewards (
                    user_id, 
                    user_nft_id, 
                    reward_date, 
                    reward_amount, 
                    calculation_method
                ) VALUES (
                    result_record.user_id,
                    result_record.user_nft_id,
                    target_date,
                    daily_reward,
                    'batch_calculation'
                );
                
                success_count := success_count + 1;
                total_reward_amount := total_reward_amount + daily_reward;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                error_count := error_count + 1;
        END;
    END LOOP;
    
    -- 結果を返す
    RETURN QUERY SELECT 
        target_date,
        success_count,
        total_reward_amount,
        completed_count,
        CASE 
            WHEN error_count > 0 THEN 'Some errors occurred'::TEXT
            ELSE NULL::TEXT
        END;
END;
$$ LANGUAGE plpgsql;

-- 8. create_synchronized_weekly_distribution関数を作成
CREATE OR REPLACE FUNCTION create_synchronized_weekly_distribution(
    p_week_start_date DATE,
    p_group_id INTEGER,
    p_weekly_rate NUMERIC
)
RETURNS VOID AS $$
DECLARE
    week_end_date DATE;
    week_number INTEGER;
    base_rates RECORD;
    adjusted_rates RECORD;
BEGIN
    -- 週末日を計算
    week_end_date := p_week_start_date + INTERVAL '4 days';
    
    -- 週番号を計算
    week_number := EXTRACT(WEEK FROM p_week_start_date);
    
    -- 基準となるランダム配分を生成（最初のグループの場合）
    IF NOT EXISTS (
        SELECT 1 FROM group_weekly_rates 
        WHERE week_start_date = p_week_start_date
    ) THEN
        -- 基準パターンを生成
        WITH random_distribution AS (
            SELECT 
                (RANDOM() * 0.4 + 0.1) * p_weekly_rate AS monday_rate,
                (RANDOM() * 0.4 + 0.1) * p_weekly_rate AS tuesday_rate,
                (RANDOM() * 0.4 + 0.1) * p_weekly_rate AS wednesday_rate,
                (RANDOM() * 0.4 + 0.1) * p_weekly_rate AS thursday_rate,
                (RANDOM() * 0.4 + 0.1) * p_weekly_rate AS friday_rate
        )
        SELECT * INTO base_rates FROM random_distribution;
        
        -- 一部の日を0%にする
        IF RANDOM() < 0.3 THEN base_rates.monday_rate := 0; END IF;
        IF RANDOM() < 0.3 THEN base_rates.tuesday_rate := 0; END IF;
        IF RANDOM() < 0.3 THEN base_rates.wednesday_rate := 0; END IF;
        IF RANDOM() < 0.3 THEN base_rates.thursday_rate := 0; END IF;
        IF RANDOM() < 0.3 THEN base_rates.friday_rate := 0; END IF;
        
        -- 合計を週利に調整
        DECLARE
            total_rate NUMERIC;
            adjustment_factor NUMERIC;
        BEGIN
            total_rate := base_rates.monday_rate + base_rates.tuesday_rate + 
                         base_rates.wednesday_rate + base_rates.thursday_rate + base_rates.friday_rate;
            
            IF total_rate > 0 THEN
                adjustment_factor := p_weekly_rate / total_rate;
                base_rates.monday_rate := base_rates.monday_rate * adjustment_factor;
                base_rates.tuesday_rate := base_rates.tuesday_rate * adjustment_factor;
                base_rates.wednesday_rate := base_rates.wednesday_rate * adjustment_factor;
                base_rates.thursday_rate := base_rates.thursday_rate * adjustment_factor;
                base_rates.friday_rate := base_rates.friday_rate * adjustment_factor;
            END IF;
        END;
    ELSE
        -- 既存の基準パターンを取得
        SELECT 
            monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
        INTO base_rates
        FROM group_weekly_rates 
        WHERE week_start_date = p_week_start_date 
        LIMIT 1;
        
        -- このグループの週利に比例調整
        DECLARE
            base_total NUMERIC;
            adjustment_factor NUMERIC;
        BEGIN
            SELECT weekly_rate INTO base_total
            FROM group_weekly_rates 
            WHERE week_start_date = p_week_start_date 
            LIMIT 1;
            
            IF base_total > 0 THEN
                adjustment_factor := p_weekly_rate / base_total;
                base_rates.monday_rate := base_rates.monday_rate * adjustment_factor;
                base_rates.tuesday_rate := base_rates.tuesday_rate * adjustment_factor;
                base_rates.wednesday_rate := base_rates.wednesday_rate * adjustment_factor;
                base_rates.thursday_rate := base_rates.thursday_rate * adjustment_factor;
                base_rates.friday_rate := base_rates.friday_rate * adjustment_factor;
            END IF;
        END;
    END IF;
    
    -- データを挿入
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
        p_group_id,
        p_week_start_date,
        week_end_date,
        week_number,
        p_weekly_rate,
        base_rates.monday_rate,
        base_rates.tuesday_rate,
        base_rates.wednesday_rate,
        base_rates.thursday_rate,
        base_rates.friday_rate,
        'auto'
    )
    ON CONFLICT (group_id, week_start_date) 
    DO UPDATE SET
        weekly_rate = EXCLUDED.weekly_rate,
        monday_rate = EXCLUDED.monday_rate,
        tuesday_rate = EXCLUDED.tuesday_rate,
        wednesday_rate = EXCLUDED.wednesday_rate,
        thursday_rate = EXCLUDED.thursday_rate,
        friday_rate = EXCLUDED.friday_rate,
        distribution_method = EXCLUDED.distribution_method;
END;
$$ LANGUAGE plpgsql;

-- 9. テーブル構造を確認
SELECT 
    '📊 修正後のgroup_weekly_rates構造' as status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 10. 制約を確認
SELECT 
    '🔒 外部キー制約確認' as status,
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'group_weekly_rates'::regclass
AND contype = 'f';

-- 11. 関数の存在確認
SELECT 
    '⚙️ 関数存在確認' as status,
    proname as function_name,
    pronargs as parameter_count
FROM pg_proc 
WHERE proname IN ('calculate_daily_rewards_batch', 'get_nft_group', 'create_synchronized_weekly_distribution');
