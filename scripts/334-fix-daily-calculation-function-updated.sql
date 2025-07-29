-- updated_at カラム対応の日利計算関数を作成

-- 既存の関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards_by_date(DATE, DATE);

-- 新しい関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_by_date(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE(
    message TEXT,
    processed_users INTEGER,
    total_rewards NUMERIC
) AS $$
DECLARE
    current_date DATE;
    day_of_week INTEGER;
    processed_count INTEGER := 0;
    total_reward_amount NUMERIC := 0;
    user_record RECORD;
    nft_record RECORD;
    daily_rate NUMERIC;
    reward_amount NUMERIC;
    current_total_rewards NUMERIC;
    max_total_rewards NUMERIC;
    can_receive_reward BOOLEAN;
BEGIN
    -- 開始メッセージ
    RAISE NOTICE '日利計算を開始します: % から %', start_date, end_date;
    
    -- 日付範囲をループ
    current_date := start_date;
    
    WHILE current_date <= end_date LOOP
        -- 曜日を取得（1=月曜, 7=日曜）
        day_of_week := EXTRACT(ISODOW FROM current_date);
        
        -- 平日のみ処理（月〜金: 1-5）
        IF day_of_week BETWEEN 1 AND 5 THEN
            RAISE NOTICE '処理中: % (曜日: %)', current_date, day_of_week;
            
            -- 全ユーザーをループ
            FOR user_record IN 
                SELECT DISTINCT u.id, u.username
                FROM users u
                INNER JOIN user_nfts un ON u.id = un.user_id
                WHERE un.is_active = true
            LOOP
                -- ユーザーの各NFTをループ
                FOR nft_record IN
                    SELECT 
                        un.id as user_nft_id,
                        un.user_id,
                        un.nft_id,
                        un.investment_amount,
                        n.daily_rate_limit,
                        drg.group_name
                    FROM user_nfts un
                    INNER JOIN nfts n ON un.nft_id = n.id
                    LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
                    WHERE un.user_id = user_record.id 
                    AND un.is_active = true
                LOOP
                    -- その日の日利を取得
                    daily_rate := 0;
                    
                    -- 曜日に応じて日利を取得
                    IF day_of_week = 1 THEN -- 月曜
                        SELECT COALESCE(gwr.monday_rate, 0) INTO daily_rate
                        FROM group_weekly_rates gwr
                        INNER JOIN daily_rate_groups drg ON gwr.group_id = drg.id::text
                        WHERE drg.daily_rate_limit = nft_record.daily_rate_limit
                        AND current_date BETWEEN gwr.week_start_date::date AND gwr.week_end_date::date
                        LIMIT 1;
                    ELSIF day_of_week = 2 THEN -- 火曜
                        SELECT COALESCE(gwr.tuesday_rate, 0) INTO daily_rate
                        FROM group_weekly_rates gwr
                        INNER JOIN daily_rate_groups drg ON gwr.group_id = drg.id::text
                        WHERE drg.daily_rate_limit = nft_record.daily_rate_limit
                        AND current_date BETWEEN gwr.week_start_date::date AND gwr.week_end_date::date
                        LIMIT 1;
                    ELSIF day_of_week = 3 THEN -- 水曜
                        SELECT COALESCE(gwr.wednesday_rate, 0) INTO daily_rate
                        FROM group_weekly_rates gwr
                        INNER JOIN daily_rate_groups drg ON gwr.group_id = drg.id::text
                        WHERE drg.daily_rate_limit = nft_record.daily_rate_limit
                        AND current_date BETWEEN gwr.week_start_date::date AND gwr.week_end_date::date
                        LIMIT 1;
                    ELSIF day_of_week = 4 THEN -- 木曜
                        SELECT COALESCE(gwr.thursday_rate, 0) INTO daily_rate
                        FROM group_weekly_rates gwr
                        INNER JOIN daily_rate_groups drg ON gwr.group_id = drg.id::text
                        WHERE drg.daily_rate_limit = nft_record.daily_rate_limit
                        AND current_date BETWEEN gwr.week_start_date::date AND gwr.week_end_date::date
                        LIMIT 1;
                    ELSIF day_of_week = 5 THEN -- 金曜
                        SELECT COALESCE(gwr.friday_rate, 0) INTO daily_rate
                        FROM group_weekly_rates gwr
                        INNER JOIN daily_rate_groups drg ON gwr.group_id = drg.id::text
                        WHERE drg.daily_rate_limit = nft_record.daily_rate_limit
                        AND current_date BETWEEN gwr.week_start_date::date AND gwr.week_end_date::date
                        LIMIT 1;
                    END IF;
                    
                    -- 日利が0より大きい場合のみ処理
                    IF daily_rate > 0 THEN
                        -- 日利上限チェック
                        IF daily_rate > nft_record.daily_rate_limit THEN
                            daily_rate := nft_record.daily_rate_limit;
                        END IF;
                        
                        -- 報酬額計算
                        reward_amount := nft_record.investment_amount * (daily_rate / 100);
                        
                        -- 300%キャップチェック
                        SELECT COALESCE(SUM(reward_amount), 0) INTO current_total_rewards
                        FROM daily_rewards
                        WHERE user_nft_id = nft_record.user_nft_id;
                        
                        max_total_rewards := nft_record.investment_amount * 3; -- 300%
                        can_receive_reward := (current_total_rewards + reward_amount) <= max_total_rewards;
                        
                        IF can_receive_reward THEN
                            -- 既存レコードを削除してから挿入（重複防止）
                            DELETE FROM daily_rewards 
                            WHERE user_nft_id = nft_record.user_nft_id 
                            AND reward_date = current_date;
                            
                            -- 日利報酬を記録
                            INSERT INTO daily_rewards (
                                user_id,
                                user_nft_id,
                                nft_id,
                                reward_date,
                                daily_rate,
                                investment_amount,
                                reward_amount,
                                created_at,
                                updated_at
                            ) VALUES (
                                nft_record.user_id,
                                nft_record.user_nft_id,
                                nft_record.nft_id,
                                current_date,
                                daily_rate,
                                nft_record.investment_amount,
                                reward_amount,
                                NOW(),
                                NOW()
                            );
                            
                            total_reward_amount := total_reward_amount + reward_amount;
                            processed_count := processed_count + 1;
                        END IF;
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
    
    RAISE NOTICE '日利計算完了: 処理件数=%, 総報酬額=%', processed_count, total_reward_amount;
    
    RETURN QUERY SELECT 
        format('日利計算が完了しました（%s〜%s）', start_date, end_date)::TEXT,
        processed_count,
        total_reward_amount;
END;
$$ LANGUAGE plpgsql;

-- 関数の存在確認
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition IS NOT NULL as has_definition
FROM information_schema.routines 
WHERE routine_name = 'calculate_daily_rewards_by_date';

SELECT 'updated_at カラム対応の日利計算関数を作成しました' as status;
