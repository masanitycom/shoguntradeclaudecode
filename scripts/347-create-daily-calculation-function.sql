-- 日利計算システムの構築

-- 既存の関数を完全に削除
DROP FUNCTION IF EXISTS calculate_daily_rewards();
DROP FUNCTION IF EXISTS calculate_daily_rewards(date);
DROP FUNCTION IF EXISTS is_weekday(date);
DROP FUNCTION IF EXISTS check_300_percent_cap(uuid, numeric);

-- 平日判定関数を作成
CREATE OR REPLACE FUNCTION is_weekday(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXTRACT(DOW FROM check_date) BETWEEN 1 AND 5;
END;
$$ LANGUAGE plpgsql;

-- 300%キャップチェック関数を作成
CREATE OR REPLACE FUNCTION check_300_percent_cap(
    p_user_nft_id UUID,
    p_investment_amount NUMERIC
) RETURNS BOOLEAN AS $$
DECLARE
    total_rewards NUMERIC := 0;
    cap_amount NUMERIC;
BEGIN
    cap_amount := p_investment_amount * 3;
    
    SELECT COALESCE(SUM(reward_amount + COALESCE(bonus_amount, 0)), 0)
    INTO total_rewards
    FROM daily_rewards
    WHERE user_nft_id = p_user_nft_id;
    
    RETURN total_rewards < cap_amount;
END;
$$ LANGUAGE plpgsql;

-- 日利計算メイン関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards(
    target_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    user_id UUID,
    user_nft_id UUID,
    nft_id UUID,
    nft_name VARCHAR(255),
    investment_amount NUMERIC,
    daily_rate NUMERIC,
    reward_amount NUMERIC,
    calculation_status VARCHAR(50),
    error_message TEXT
) AS $$
DECLARE
    user_nft_record RECORD;
    nft_group TEXT;
    daily_rate_value NUMERIC := 0;
    calculated_reward NUMERIC := 0;
    week_start DATE;
    dow_value INTEGER;
    calculation_details JSONB;
    can_calculate BOOLEAN;
    total_processed INTEGER := 0;
    total_rewards NUMERIC := 0;
BEGIN
    -- 平日チェック
    IF NOT is_weekday(target_date) THEN
        RAISE NOTICE 'Not a weekday, skipping calculation';
        RETURN;
    END IF;
    
    -- 週の開始日を取得
    week_start := DATE_TRUNC('week', target_date);
    dow_value := EXTRACT(DOW FROM target_date);
    
    RAISE NOTICE 'Starting daily calculation for date: %', target_date;
    
    -- アクティブなuser_nftsを取得
    FOR user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.current_investment as investment_amount,
            un.is_active,
            n.name as nft_name,
            n.price as nft_price,
            n.daily_rate_limit
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        WHERE un.is_active = true
        AND un.current_investment > 0
        ORDER BY un.user_id, n.price
    LOOP
        BEGIN
            total_processed := total_processed + 1;
            
            -- 300%キャップチェック
            can_calculate := check_300_percent_cap(
                user_nft_record.user_nft_id, 
                user_nft_record.investment_amount
            );
            
            IF NOT can_calculate THEN
                -- NFTを非アクティブ化
                UPDATE user_nfts 
                SET is_active = false, updated_at = NOW()
                WHERE id = user_nft_record.user_nft_id;
                
                RAISE NOTICE 'NFT reached 300%% cap and deactivated: %', user_nft_record.nft_name;
                
                RETURN QUERY SELECT
                    user_nft_record.user_id,
                    user_nft_record.user_nft_id,
                    user_nft_record.nft_id,
                    user_nft_record.nft_name::VARCHAR(255),
                    user_nft_record.investment_amount,
                    0::NUMERIC,
                    0::NUMERIC,
                    '300% cap reached'::VARCHAR(50),
                    'NFT deactivated'::TEXT;
                CONTINUE;
            END IF;
            
            -- NFTグループを取得
            nft_group := get_nft_group(user_nft_record.nft_price);
            
            -- 曜日に応じた日利を取得
            SELECT 
                CASE dow_value
                    WHEN 1 THEN monday_rate
                    WHEN 2 THEN tuesday_rate
                    WHEN 3 THEN wednesday_rate
                    WHEN 4 THEN thursday_rate
                    WHEN 5 THEN friday_rate
                    ELSE 0
                END
            INTO daily_rate_value
            FROM group_weekly_rates
            WHERE week_start_date = week_start
            AND nft_group = nft_group;
            
            -- 日利が取得できない場合はデフォルト値を使用
            IF daily_rate_value IS NULL THEN
                daily_rate_value := 0.005;
                RAISE NOTICE 'No rate found for group %, using default', nft_group;
            END IF;
            
            -- 日利上限チェック
            IF daily_rate_value > (user_nft_record.daily_rate_limit / 100.0) THEN
                daily_rate_value := user_nft_record.daily_rate_limit / 100.0;
            END IF;
            
            -- 報酬額を計算
            calculated_reward := user_nft_record.investment_amount * daily_rate_value;
            
            -- 計算詳細をJSONBで作成
            calculation_details := jsonb_build_object(
                'target_date', target_date,
                'nft_group', nft_group,
                'week_start', week_start,
                'day_of_week', dow_value,
                'daily_rate', daily_rate_value,
                'investment_amount', user_nft_record.investment_amount,
                'calculated_reward', calculated_reward,
                'calculation_time', NOW()
            );
            
            -- daily_rewardsテーブルに挿入または更新
            INSERT INTO daily_rewards (
                user_nft_id,
                user_id,
                nft_id,
                reward_date,
                daily_rate,
                reward_amount,
                week_start_date,
                investment_amount,
                calculation_date,
                calculation_details,
                is_claimed
            ) VALUES (
                user_nft_record.user_nft_id,
                user_nft_record.user_id,
                user_nft_record.nft_id,
                target_date,
                daily_rate_value,
                calculated_reward,
                week_start,
                user_nft_record.investment_amount,
                CURRENT_DATE,
                calculation_details,
                false
            )
            ON CONFLICT (user_nft_id, reward_date)
            DO UPDATE SET
                daily_rate = EXCLUDED.daily_rate,
                reward_amount = EXCLUDED.reward_amount,
                investment_amount = EXCLUDED.investment_amount,
                calculation_date = EXCLUDED.calculation_date,
                calculation_details = EXCLUDED.calculation_details,
                updated_at = NOW();
            
            total_rewards := total_rewards + calculated_reward;
            
            -- 結果を返す
            RETURN QUERY SELECT
                user_nft_record.user_id,
                user_nft_record.user_nft_id,
                user_nft_record.nft_id,
                user_nft_record.nft_name::VARCHAR(255),
                user_nft_record.investment_amount,
                daily_rate_value,
                calculated_reward,
                'success'::VARCHAR(50),
                ''::TEXT;
                
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error calculating for NFT %: %', user_nft_record.nft_name, SQLERRM;
            
            RETURN QUERY SELECT
                user_nft_record.user_id,
                user_nft_record.user_nft_id,
                user_nft_record.nft_id,
                user_nft_record.nft_name::VARCHAR(255),
                user_nft_record.investment_amount,
                0::NUMERIC,
                0::NUMERIC,
                'error'::VARCHAR(50),
                SQLERRM::TEXT;
        END;
    END LOOP;
    
    RAISE NOTICE 'Daily calculation completed: % processed, total rewards: %', total_processed, total_rewards;
END;
$$ LANGUAGE plpgsql;

-- テスト実行
DO $$
DECLARE
    result_record RECORD;
    success_count INTEGER := 0;
    error_count INTEGER := 0;
    total_reward_amount NUMERIC := 0;
BEGIN
    RAISE NOTICE 'Starting daily calculation test...';
    
    FOR result_record IN
        SELECT * FROM calculate_daily_rewards(CURRENT_DATE)
    LOOP
        IF result_record.calculation_status = 'success' THEN
            success_count := success_count + 1;
            total_reward_amount := total_reward_amount + result_record.reward_amount;
        ELSE
            error_count := error_count + 1;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Test results: % success, % errors, total rewards: %', success_count, error_count, total_reward_amount;
END $$;

-- インデックスを作成
CREATE INDEX IF NOT EXISTS idx_daily_rewards_reward_date 
ON daily_rewards(reward_date);

CREATE INDEX IF NOT EXISTS idx_daily_rewards_user_nft_reward_date 
ON daily_rewards(user_nft_id, reward_date);

-- 計算結果の確認
SELECT 
    'Daily calculation results' as status,
    COUNT(*) as total_calculations,
    SUM(reward_amount) as total_rewards,
    AVG(daily_rate * 100) as avg_daily_rate_percent
FROM daily_rewards
WHERE reward_date = CURRENT_DATE;

-- 詳細結果の表示（最新10件）
SELECT 
    'Latest calculation details' as info,
    dr.reward_date,
    n.name as nft_name,
    dr.investment_amount,
    dr.daily_rate * 100 as daily_rate_percent,
    dr.reward_amount,
    dr.calculation_details->>'nft_group' as nft_group,
    dr.calculation_details->>'day_of_week' as day_of_week
FROM daily_rewards dr
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.created_at DESC
LIMIT 10;

RAISE NOTICE '日利計算システムの構築が完了しました';
