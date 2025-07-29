-- 計算関数のRAISE文パラメータ数を修正

DROP FUNCTION IF EXISTS test_daily_calculation(DATE);

CREATE OR REPLACE FUNCTION test_daily_calculation(
    target_date DATE DEFAULT CURRENT_DATE
) RETURNS JSON AS $$
DECLARE
    processed_count INTEGER := 0;
    total_amount NUMERIC := 0;
    day_of_week INTEGER;
    calculation_rec RECORD;
    result JSON;
    reward_amount NUMERIC;
    daily_rate_decimal NUMERIC;
    max_reward NUMERIC;
    log_message TEXT;
BEGIN
    -- 曜日チェック
    day_of_week := EXTRACT(DOW FROM target_date);
    
    IF day_of_week = 0 OR day_of_week = 6 THEN
        result := json_build_object(
            'success', false,
            'message', format('土日は計算対象外: %s', target_date::TEXT),
            'processed_count', 0,
            'total_amount', 0
        );
        RETURN result;
    END IF;
    
    -- 計算実行
    FOR calculation_rec IN
        SELECT 
            un.id as user_nft_id,
            u.email,
            u.name,
            n.name as nft_name,
            un.purchase_price,
            n.daily_rate_limit,
            drg.group_name,
            CASE day_of_week
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END as daily_rate
        FROM user_nfts un
        JOIN users u ON un.user_id = u.id
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
        JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
        WHERE u.is_admin = false
        AND un.operation_start_date <= target_date
        AND target_date >= gwr.week_start_date
        AND target_date <= gwr.week_end_date
        ORDER BY u.email, n.name
    LOOP
        -- 日利を小数に変換（例：2.6% → 0.026）
        daily_rate_decimal := calculation_rec.daily_rate / 100.0;
        
        -- 報酬計算（投資額 × 日利）
        reward_amount := calculation_rec.purchase_price * daily_rate_decimal;
        
        -- 日利上限適用（投資額 × 日利上限%）
        max_reward := calculation_rec.purchase_price * (calculation_rec.daily_rate_limit / 100.0);
        
        IF reward_amount > max_reward THEN
            reward_amount := max_reward;
        END IF;
        
        -- ログメッセージを文字列として構築（パラメータ数制限対応）
        log_message := format('User: %s | NFT: %s | Price: $%s | Rate: %s%% | Reward: $%s', 
            calculation_rec.email,
            calculation_rec.nft_name,
            calculation_rec.purchase_price,
            ROUND(calculation_rec.daily_rate, 3),
            ROUND(reward_amount, 2)
        );
        
        RAISE NOTICE '%', log_message;
        
        processed_count := processed_count + 1;
        total_amount := total_amount + reward_amount;
    END LOOP;
    
    result := json_build_object(
        'success', true,
        'message', format('%s件の報酬を計算（合計: $%s）', processed_count, ROUND(total_amount, 2)),
        'processed_count', processed_count,
        'total_amount', total_amount,
        'target_date', target_date,
        'day_of_week', day_of_week
    );
    
    RETURN result;
        
EXCEPTION
    WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'message', format('計算エラー: %s', SQLERRM),
            'processed_count', 0,
            'total_amount', 0
        );
        RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION test_daily_calculation(DATE) TO authenticated;

SELECT 'Fixed calculation function created' as status;
