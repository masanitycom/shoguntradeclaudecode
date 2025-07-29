-- ユニーク制約の追加と安全な過去分計算関数の作成

-- 1. daily_rewardsテーブルにユニーク制約を追加
DO $$
BEGIN
    -- 既存の制約があるかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'daily_rewards_user_nft_reward_date_unique'
        AND table_name = 'daily_rewards'
    ) THEN
        ALTER TABLE daily_rewards 
        ADD CONSTRAINT daily_rewards_user_nft_reward_date_unique 
        UNIQUE (user_nft_id, reward_date);
    END IF;
END $$;

-- 2. 安全な過去分計算関数の作成
CREATE OR REPLACE FUNCTION calculate_nft_historical_rewards_safe(
    start_week INTEGER,
    end_week INTEGER
) RETURNS TABLE (
    nft_name TEXT,
    week_number INTEGER,
    rewards_calculated INTEGER,
    total_reward_amount NUMERIC
) AS $$
DECLARE
    nft_rate_record RECORD;
    user_nft_record RECORD;
    week_num INTEGER;
    week_start DATE;
    week_end DATE;
    calculation_date DATE;
    day_index INTEGER;
    daily_rates NUMERIC[];
    daily_reward NUMERIC;
    existing_reward_id UUID;
    rewards_count INTEGER := 0;
    week_total NUMERIC := 0;
BEGIN
    -- NFT別の週利データを取得
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
        -- 週ごとの処理
        FOR week_num IN start_week..end_week LOOP
            -- 週の開始日と終了日を計算
            week_start := '2025-01-06'::DATE + (week_num - 1) * INTERVAL '7 days';
            week_end := week_start + INTERVAL '6 days';
            
            -- その週の日利率配列を取得
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
            
            -- 日利率が見つからない場合はスキップ
            IF daily_rates IS NULL THEN
                CONTINUE;
            END IF;
            
            rewards_count := 0;
            week_total := 0;
            
            -- そのNFTを持つユーザーを取得
            FOR user_nft_record IN
                SELECT 
                    un.id as user_nft_id, 
                    un.user_id, 
                    un.current_investment as investment_amount
                FROM user_nfts un 
                WHERE un.nft_id = nft_rate_record.nft_id 
                AND un.is_active = true 
                AND un.purchase_date <= week_end
            LOOP
                -- 平日（月〜金）の日利計算
                FOR day_index IN 1..5 LOOP
                    calculation_date := week_start + (day_index - 1);
                    
                    -- 既存のレコードをチェック
                    SELECT id INTO existing_reward_id
                    FROM daily_rewards 
                    WHERE user_nft_id = user_nft_record.user_nft_id 
                    AND reward_date = calculation_date;
                    
                    -- 日利報酬を計算
                    daily_reward := user_nft_record.investment_amount * (daily_rates[day_index] / 100);
                    
                    IF existing_reward_id IS NOT NULL THEN
                        -- 既存レコードを更新
                        UPDATE daily_rewards SET
                            daily_rate = daily_rates[day_index],
                            reward_amount = daily_reward,
                            week_start_date = week_start
                        WHERE id = existing_reward_id;
                    ELSE
                        -- 新規レコードを挿入
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
                        );
                    END IF;
                    
                    rewards_count := rewards_count + 1;
                    week_total := week_total + daily_reward;
                END LOOP;
            END LOOP;
            
            -- 週別結果を返す
            RETURN QUERY SELECT 
                nft_rate_record.name,
                week_num,
                rewards_count,
                week_total;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 実行結果を返す
SELECT 'Safe historical calculation function created successfully.' as status;
