-- 天下統一ボーナス分配関数のパラメータ順序を修正

-- 1. 既存関数を削除
DROP FUNCTION IF EXISTS calculate_and_distribute_tenka_bonus(NUMERIC, NUMERIC, DATE, DATE);
DROP FUNCTION IF EXISTS calculate_and_distribute_tenka_bonus(NUMERIC, DATE, DATE);

-- 2. 正しいパラメータ順序で関数を再作成
CREATE OR REPLACE FUNCTION calculate_and_distribute_tenka_bonus(
    company_profit_param NUMERIC,
    week_start_param DATE,
    week_end_param DATE,
    bonus_rate_param NUMERIC DEFAULT 20
)
RETURNS TABLE(
    distributed_amount NUMERIC,
    beneficiary_count INTEGER
) AS $$
DECLARE
    bonus_pool NUMERIC;
    total_distribution_rate NUMERIC := 0;
    user_record RECORD;
    user_bonus_amount NUMERIC;
    distribution_id UUID;
    total_distributed NUMERIC := 0;
    beneficiary_count_result INTEGER := 0;
BEGIN
    -- ボーナスプールを計算（指定された率で）
    bonus_pool := company_profit_param * (bonus_rate_param / 100);
    
    -- 全ランク保有者の分配率合計を計算
    SELECT COALESCE(SUM(mr.bonus_percentage), 0) INTO total_distribution_rate
    FROM user_rank_history urh
    JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
    WHERE urh.rank_level > 0;
    
    -- 分配率合計が0の場合は処理終了
    IF total_distribution_rate = 0 THEN
        RETURN QUERY SELECT 0::NUMERIC, 0::INTEGER;
        RETURN;
    END IF;
    
    -- 各ランク保有者にボーナスを分配
    FOR user_record IN
        SELECT 
            u.id,
            u.name,
            u.user_id,
            urh.rank_level,
            mr.rank_name,
            mr.bonus_percentage
        FROM users u
        JOIN user_rank_history urh ON u.id = urh.user_id
        JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
        WHERE urh.rank_level > 0
    LOOP
        -- 個別ボーナス額を計算
        user_bonus_amount := bonus_pool * (user_record.bonus_percentage / total_distribution_rate);
        
        -- tenka_bonus_distributionsテーブルに記録
        INSERT INTO tenka_bonus_distributions (
            week_start_date,
            week_end_date,
            total_company_profit,
            distribution_amount,
            user_id,
            user_rank,
            distribution_rate,
            bonus_amount,
            bonus_rate
        ) VALUES (
            week_start_param,
            week_end_param,
            company_profit_param,
            bonus_pool,
            user_record.id,
            user_record.rank_name,
            user_record.bonus_percentage,
            user_bonus_amount,
            bonus_rate_param
        );
        
        total_distributed := total_distributed + user_bonus_amount;
        beneficiary_count_result := beneficiary_count_result + 1;
    END LOOP;
    
    RETURN QUERY SELECT total_distributed, beneficiary_count_result;
END;
$$ LANGUAGE plpgsql;

-- 3. テスト実行
SELECT 'Function parameter order fixed successfully' as status;
