-- 過去分計算関数のデータ型エラーを修正

-- 1. 修正された過去分計算関数
CREATE OR REPLACE FUNCTION calculate_nft_specific_historical_rewards_fixed(
    start_week INTEGER,
    end_week INTEGER
)
RETURNS TABLE(
    nft_name TEXT,
    week_number INTEGER,
    rewards_calculated INTEGER,
    total_reward_amount NUMERIC
) AS $$
DECLARE
    nft_rate_record RECORD;
    user_nft_record RECORD;
    week_num INTEGER;
    calculation_date DATE;
    week_start DATE;
    week_end DATE;
    daily_rates NUMERIC[];
    day_index INTEGER;
    daily_reward NUMERIC;
    rewards_count INTEGER;
    total_reward_amount NUMERIC;
BEGIN
    -- 基準日: 2025年1月6日（第1週の月曜日）
    
    -- 各NFTの週利設定を取得
    FOR nft_rate_record IN 
        SELECT DISTINCT 
            n.id as nft_id, 
            n.name::TEXT as name
        FROM nfts n
        JOIN nft_weekly_rates nwr ON n.id = nwr.nft_id
        WHERE nwr.week_number BETWEEN start_week AND end_week
        ORDER BY n.id, n.name::TEXT
    LOOP
        -- 各週の計算
        FOR week_num IN start_week..end_week LOOP
            -- その週の日利データを取得
            SELECT ARRAY[
                COALESCE(nwr.monday_rate, 0),
                COALESCE(nwr.tuesday_rate, 0), 
                COALESCE(nwr.wednesday_rate, 0),
                COALESCE(nwr.thursday_rate, 0),
                COALESCE(nwr.friday_rate, 0)
            ] INTO daily_rates
            FROM nft_weekly_rates nwr
            WHERE nwr.nft_id = nft_rate_record.nft_id 
            AND nwr.week_number = week_num;
            
            -- 日利データが存在しない場合はスキップ
            IF daily_rates IS NULL THEN
                CONTINUE;
            END IF;
            
            -- その週の期間を計算
            week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
            week_end := week_start + 4;
            
            rewards_count := 0;
            total_reward_amount := 0;
            
            -- そのNFTを持つ全ユーザーに対して計算
            FOR user_nft_record IN 
                SELECT un.id as user_nft_id, un.user_id, un.purchase_amount
                FROM user_nfts un
                WHERE un.nft_id = nft_rate_record.nft_id
                AND un.is_active = true
                AND un.purchased_at <= week_end
            LOOP
                -- 月曜日から金曜日まで計算
                FOR day_index IN 1..5 LOOP
                    calculation_date := week_start + (day_index - 1);
                    
                    -- 日利が0%でない場合のみ計算
                    IF daily_rates[day_index] > 0 THEN
                        daily_reward := user_nft_record.purchase_amount * (daily_rates[day_index] / 100.0);
                        
                        -- daily_rewards テーブルに挿入
                        INSERT INTO daily_rewards (
                            user_nft_id,
                            user_id,
                            reward_date,
                            daily_rate,
                            reward_amount,
                            calculation_type,
                            created_at
                        ) VALUES (
                            user_nft_record.user_nft_id,
                            user_nft_record.user_id,
                            calculation_date,
                            daily_rates[day_index],
                            daily_reward,
                            'HISTORICAL_CALCULATION',
                            NOW()
                        ) ON CONFLICT (user_nft_id, reward_date) DO UPDATE SET
                            daily_rate = EXCLUDED.daily_rate,
                            reward_amount = EXCLUDED.reward_amount,
                            calculation_type = EXCLUDED.calculation_type,
                            updated_at = NOW();
                        
                        rewards_count := rewards_count + 1;
                        total_reward_amount := total_reward_amount + daily_reward;
                    END IF;
                END LOOP;
            END LOOP;
            
            -- 結果を返す
            RETURN QUERY SELECT 
                nft_rate_record.name, 
                week_num, 
                rewards_count, 
                total_reward_amount;
        END LOOP;
    END LOOP;
    
END;
$$ LANGUAGE plpgsql;

-- 2. 修正された関数を実行
SELECT * FROM calculate_nft_specific_historical_rewards_fixed(2, 19);

-- 3. 計算結果の確認
SELECT 
    'Historical calculation completed successfully' as status,
    COUNT(*) as total_daily_rewards,
    COUNT(DISTINCT user_nft_id) as unique_user_nfts,
    SUM(reward_amount) as total_rewards_amount
FROM daily_rewards 
WHERE calculation_type = 'HISTORICAL_CALCULATION';
