-- 日利計算関数の完全修正

-- 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS force_daily_calculation();
DROP FUNCTION IF EXISTS calculate_daily_rewards(DATE);

-- daily_rewardsテーブルの正確な構造に基づいた新しい関数
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS TABLE(
    status TEXT,
    message TEXT,
    processed_users INTEGER,
    total_rewards DECIMAL(10,2)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    current_date_jst DATE;
    processed_count INTEGER := 0;
    total_amount DECIMAL(10,2) := 0;
    user_record RECORD;
    nft_record RECORD;
    daily_rate DECIMAL(5,4);
    reward_amount DECIMAL(10,2);
    week_start DATE;
    day_of_week INTEGER;
BEGIN
    -- 日本時間の現在日付を取得
    current_date_jst := (NOW() AT TIME ZONE 'Asia/Tokyo')::DATE;
    
    -- 平日チェック（月曜=1, 金曜=5）
    day_of_week := EXTRACT(DOW FROM current_date_jst);
    IF day_of_week = 0 OR day_of_week = 6 THEN
        RETURN QUERY SELECT 
            'skipped'::TEXT,
            '土日は日利計算を実行しません'::TEXT,
            0,
            0.00::DECIMAL(10,2);
        RETURN;
    END IF;
    
    -- 週の開始日（月曜日）を計算
    week_start := current_date_jst - (day_of_week - 1);
    
    -- 各ユーザーの処理
    FOR user_record IN 
        SELECT DISTINCT u.id, u.name
        FROM users u
        INNER JOIN user_nfts un ON u.id = un.user_id
        WHERE un.is_active = true
    LOOP
        -- ユーザーの各NFTを処理
        FOR nft_record IN
            SELECT 
                un.id as user_nft_id,
                un.user_id,
                un.nft_id,
                un.purchase_price,
                n.daily_rate_limit,
                drg.group_name
            FROM user_nfts un
            INNER JOIN nfts n ON un.nft_id = n.id
            LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
            WHERE un.user_id = user_record.id 
              AND un.is_active = true
        LOOP
            -- 既に今日の報酬が計算済みかチェック
            IF EXISTS (
                SELECT 1 FROM daily_rewards 
                WHERE user_id = nft_record.user_id 
                  AND user_nft_id = nft_record.user_nft_id
                  AND reward_date = current_date_jst
            ) THEN
                CONTINUE;
            END IF;
            
            -- 週利から日利を取得
            SELECT 
                CASE day_of_week
                    WHEN 1 THEN gwr.monday_rate
                    WHEN 2 THEN gwr.tuesday_rate  
                    WHEN 3 THEN gwr.wednesday_rate
                    WHEN 4 THEN gwr.thursday_rate
                    WHEN 5 THEN gwr.friday_rate
                    ELSE 0
                END INTO daily_rate
            FROM group_weekly_rates gwr
            WHERE gwr.week_start_date = week_start
              AND gwr.group_name = nft_record.group_name;
            
            -- 日利が設定されていない場合はスキップ
            IF daily_rate IS NULL OR daily_rate = 0 THEN
                CONTINUE;
            END IF;
            
            -- 報酬計算
            reward_amount := nft_record.purchase_price * daily_rate;
            
            -- 日利上限チェック
            IF reward_amount > nft_record.daily_rate_limit THEN
                reward_amount := nft_record.daily_rate_limit;
            END IF;
            
            -- 報酬記録を挿入
            INSERT INTO daily_rewards (
                user_id,
                user_nft_id,
                nft_id,
                reward_amount,
                daily_rate,
                reward_date,
                created_at,
                updated_at
            ) VALUES (
                nft_record.user_id,
                nft_record.user_nft_id,
                nft_record.nft_id,
                reward_amount,
                daily_rate,
                current_date_jst,
                NOW(),
                NOW()
            );
            
            processed_count := processed_count + 1;
            total_amount := total_amount + reward_amount;
        END LOOP;
    END LOOP;
    
    RETURN QUERY SELECT 
        'success'::TEXT,
        format('日利計算完了: %s人のユーザー、合計$%s', processed_count, total_amount)::TEXT,
        processed_count,
        total_amount;
END;
$$;
