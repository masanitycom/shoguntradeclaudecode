-- 構文エラーを修正し、完全なシステムを構築

-- 1. 既存の外部キー制約を削除
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

-- 2. group_nameカラムを削除（group_idのみ使用）
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

-- 3. 単一の外部キー制約を追加
DO $$
BEGIN
    ALTER TABLE group_weekly_rates 
    ADD CONSTRAINT fk_group_weekly_rates_group 
    FOREIGN KEY (group_id) REFERENCES daily_rate_groups(id) ON DELETE CASCADE;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- 既に存在する場合は無視
END $$;

-- 4. calculate_daily_rewards_batch関数を作成
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
    
    -- 日利計算を実行
    FOR result_record IN
        SELECT * FROM calculate_daily_rewards(target_date)
    LOOP
        IF result_record.calculation_status = 'success' THEN
            success_count := success_count + 1;
            total_reward_amount := total_reward_amount + result_record.reward_amount;
        ELSIF result_record.calculation_status = '300% cap reached' THEN
            completed_count := completed_count + 1;
        ELSE
            error_count := error_count + 1;
        END IF;
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

-- 5. get_nft_group関数を作成
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

-- 6. テーブル構造を確認
SELECT 
    '📊 修正後のgroup_weekly_rates構造' as status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 7. 制約を確認
SELECT 
    '🔒 外部キー制約確認' as status,
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'group_weekly_rates'::regclass
AND contype = 'f';

-- 8. 関数の存在確認
SELECT 
    '⚙️ 関数存在確認' as status,
    proname as function_name,
    pronargs as parameter_count
FROM pg_proc 
WHERE proname IN ('calculate_daily_rewards_batch', 'get_nft_group', 'calculate_daily_rewards');
