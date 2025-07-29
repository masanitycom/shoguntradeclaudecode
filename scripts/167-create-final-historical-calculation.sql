-- daily_rewardsテーブルの実際の構造に基づいた最終的な過去分計算関数

CREATE OR REPLACE FUNCTION calculate_nft_historical_rewards_final(
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
    nft_amount NUMERIC;
BEGIN
    -- 基準日: 2025年1月6日（第1週の月曜日）
    
    -- 各NFTの週利設定を取得
    FOR nft_rate_record IN 
        SELECT DISTINCT 
            n.id as nft_id, 
            n.name::TEXT as name,
            n.price as nft_price
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
                SELECT 
                    un.id as user_nft_id, 
                    un.user_id,
                    un.current_investment as amount,
                    un.purchase_date
                FROM user_nfts un
                WHERE un.nft_id = nft_rate_record.nft_id
                AND un.is_active = true
                AND un.purchase_date <= week_end
            LOOP
                nft_amount := user_nft_record.amount;
                
                -- 月曜日から金曜日まで計算
                FOR day_index IN 1..5 LOOP
                    calculation_date := week_start + (day_index - 1);
                    
                    -- 日利が0%でない場合のみ計算
                    IF daily_rates[day_index] > 0 THEN
                        daily_reward := nft_amount * (daily_rates[day_index] / 100.0);
                        
                        -- daily_rewardsテーブルの実際の構造に基づいてINSERT
                        INSERT INTO daily_rewards (
                            user_nft_id,
                            reward_date,
                            daily_rate,
                            reward_amount,
                            week_start_date,
                            is_claimed,
                            created_at
                        ) VALUES (
                            user_nft_record.user_nft_id,
                            calculation_date,
                            daily_rates[day_index],
                            daily_reward,
                            week_start,
                            false,
                            NOW()
                        ) ON CONFLICT (user_nft_id, reward_date) DO UPDATE SET
                            daily_rate = EXCLUDED.daily_rate,
                            reward_amount = EXCLUDED.reward_amount,
                            week_start_date = EXCLUDED.week_start_date;
                        
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

-- 関数作成完了
SELECT 'Final historical calculation function created successfully with correct daily_rewards structure.' as status;
