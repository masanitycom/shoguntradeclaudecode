-- 修正されたテーブル構造に基づく日利計算関数

-- 1. 日利計算関数（修正版）
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_date(DATE);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_date(target_date DATE)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    user_nft_record RECORD;
    daily_rate_value NUMERIC;
    reward_amount NUMERIC;
    rewards_calculated INTEGER := 0;
    day_of_week INTEGER;
    week_start_date DATE;
BEGIN
    -- 平日のみ計算（月曜=1, 火曜=2, 水曜=3, 木曜=4, 金曜=5）
    day_of_week := EXTRACT(DOW FROM target_date);
    
    IF day_of_week NOT IN (1, 2, 3, 4, 5) THEN
        RETURN format('⚠️ %s は平日ではありません（土日は計算対象外）', target_date);
    END IF;
    
    -- 週の開始日を計算
    week_start_date := target_date - (day_of_week - 1);
    
    -- 既存の計算結果を削除
    DELETE FROM daily_rewards WHERE reward_date = target_date;
    
    -- アクティブなNFTに対して日利計算
    FOR user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            COALESCE(un.current_investment, un.purchase_price, 0) as investment_amount,
            n.daily_rate_limit,
            n.daily_rate_group_id,
            drg.group_name
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
        WHERE un.is_active = true
        AND COALESCE(un.current_investment, un.purchase_price, 0) > 0
        AND COALESCE(un.total_earned, 0) < COALESCE(un.max_earning, un.purchase_price * 3, 0) -- 300%未満
    LOOP
        -- その日の日利を取得
        SELECT 
            CASE day_of_week
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END
        INTO daily_rate_value
        FROM group_weekly_rates gwr
        WHERE gwr.group_id = user_nft_record.daily_rate_group_id
        AND gwr.week_start_date = week_start_date;
        
        -- 日利が見つからない場合はデフォルト値を使用
        IF daily_rate_value IS NULL THEN
            daily_rate_value := LEAST(user_nft_record.daily_rate_limit, 0.005); -- 最大0.5%
        END IF;
        
        -- NFTの日利上限を適用
        daily_rate_value := LEAST(daily_rate_value, user_nft_record.daily_rate_limit);
        
        -- 報酬額計算
        reward_amount := user_nft_record.investment_amount * daily_rate_value;
        
        -- 300%キャップチェック
        IF COALESCE((SELECT total_earned FROM user_nfts WHERE id = user_nft_record.user_nft_id), 0) + reward_amount > 
           COALESCE((SELECT max_earning FROM user_nfts WHERE id = user_nft_record.user_nft_id), user_nft_record.investment_amount * 3) THEN
            reward_amount := COALESCE((SELECT max_earning FROM user_nfts WHERE id = user_nft_record.user_nft_id), user_nft_record.investment_amount * 3) - 
                           COALESCE((SELECT total_earned FROM user_nfts WHERE id = user_nft_record.user_nft_id), 0);
        END IF;
        
        -- 報酬額が0以下の場合はスキップ
        IF reward_amount <= 0 THEN
            CONTINUE;
        END IF;
        
        -- 日利報酬を記録
        INSERT INTO daily_rewards (
            id,
            user_id,
            user_nft_id,
            nft_id,
            reward_date,
            investment_amount,
            daily_rate,
            reward_amount,
            reward_type,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            user_nft_record.user_id,
            user_nft_record.user_nft_id,
            user_nft_record.nft_id,
            target_date,
            user_nft_record.investment_amount,
            daily_rate_value,
            reward_amount,
            'DAILY_REWARD',
            NOW(),
            NOW()
        );
        
        -- user_nftsのtotal_earnedを更新
        UPDATE user_nfts 
        SET 
            total_earned = COALESCE(total_earned, 0) + reward_amount,
            updated_at = NOW()
        WHERE id = user_nft_record.user_nft_id;
        
        rewards_calculated := rewards_calculated + 1;
    END LOOP;
    
    RETURN format('✅ %s件の日利報酬を計算しました（%s）', rewards_calculated, target_date);
END;
$$;

-- 2. 強制日利計算関数（今日用）
DROP FUNCTION IF EXISTS force_daily_calculation();

CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    calculation_result TEXT;
    today_date DATE := CURRENT_DATE;
    result JSON;
BEGIN
    -- 今日の日利計算を実行
    SELECT calculate_daily_rewards_for_date(today_date) INTO calculation_result;
    
    -- 結果をJSON形式で返す
    SELECT json_build_object(
        'success', true,
        'message', calculation_result,
        'calculation_date', today_date,
        'timestamp', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 3. 週利復元関数（修正版）
DROP FUNCTION IF EXISTS restore_weekly_rates_from_csv_data();

CREATE OR REPLACE FUNCTION restore_weekly_rates_from_csv_data()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    week_start DATE;
    week_end DATE;
    group_record RECORD;
    weeks_created INTEGER := 0;
    constraint_exists BOOLEAN := FALSE;
BEGIN
    -- 2024年12月2日（月曜日）から開始
    week_start := '2024-12-02';
    
    -- UNIQUE制約の存在確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'group_weekly_rates' 
        AND constraint_type = 'UNIQUE'
    ) INTO constraint_exists;
    
    IF NOT constraint_exists THEN
        -- UNIQUE制約を作成
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT unique_week_group 
        UNIQUE (week_start_date, group_id);
        RAISE NOTICE 'UNIQUE制約を作成しました';
    END IF;
    
    -- 現在の週まで設定を作成
    WHILE week_start <= CURRENT_DATE LOOP
        week_end := week_start + 6;
        
        -- 各グループに対して週利設定を作成
        FOR group_record IN 
            SELECT id, group_name, daily_rate_limit 
            FROM daily_rate_groups 
            ORDER BY daily_rate_limit
        LOOP
            -- グループ別の適切な週利を設定
            INSERT INTO group_weekly_rates (
                id,
                week_start_date,
                week_end_date,
                weekly_rate,
                monday_rate,
                tuesday_rate,
                wednesday_rate,
                thursday_rate,
                friday_rate,
                group_id,
                group_name,
                distribution_method,
                created_at,
                updated_at
            ) VALUES (
                gen_random_uuid(),
                week_start,
                week_end,
                -- グループ別の週利設定
                CASE 
                    WHEN group_record.daily_rate_limit = 0.005 THEN 0.015  -- 0.5%グループ: 1.5%週利
                    WHEN group_record.daily_rate_limit = 0.010 THEN 0.020  -- 1.0%グループ: 2.0%週利
                    WHEN group_record.daily_rate_limit = 0.0125 THEN 0.023 -- 1.25%グループ: 2.3%週利
                    WHEN group_record.daily_rate_limit = 0.015 THEN 0.026  -- 1.5%グループ: 2.6%週利
                    WHEN group_record.daily_rate_limit = 0.0175 THEN 0.029 -- 1.75%グループ: 2.9%週利
                    WHEN group_record.daily_rate_limit = 0.020 THEN 0.032  -- 2.0%グループ: 3.2%週利
                    ELSE 0.020
                END,
                -- 月曜日の日利（週利の20%）
                CASE 
                    WHEN group_record.daily_rate_limit = 0.005 THEN 0.003
                    WHEN group_record.daily_rate_limit = 0.010 THEN 0.004
                    WHEN group_record.daily_rate_limit = 0.0125 THEN 0.0046
                    WHEN group_record.daily_rate_limit = 0.015 THEN 0.0052
                    WHEN group_record.daily_rate_limit = 0.0175 THEN 0.0058
                    WHEN group_record.daily_rate_limit = 0.020 THEN 0.0064
                    ELSE 0.004
                END,
                -- 火曜日の日利（週利の25%）
                CASE 
                    WHEN group_record.daily_rate_limit = 0.005 THEN 0.00375
                    WHEN group_record.daily_rate_limit = 0.010 THEN 0.005
                    WHEN group_record.daily_rate_limit = 0.0125 THEN 0.00575
                    WHEN group_record.daily_rate_limit = 0.015 THEN 0.0065
                    WHEN group_record.daily_rate_limit = 0.0175 THEN 0.00725
                    WHEN group_record.daily_rate_limit = 0.020 THEN 0.008
                    ELSE 0.005
                END,
                -- 水曜日の日利（週利の20%）
                CASE 
                    WHEN group_record.daily_rate_limit = 0.005 THEN 0.003
                    WHEN group_record.daily_rate_limit = 0.010 THEN 0.004
                    WHEN group_record.daily_rate_limit = 0.0125 THEN 0.0046
                    WHEN group_record.daily_rate_limit = 0.015 THEN 0.0052
                    WHEN group_record.daily_rate_limit = 0.0175 THEN 0.0058
                    WHEN group_record.daily_rate_limit = 0.020 THEN 0.0064
                    ELSE 0.004
                END,
                -- 木曜日の日利（週利の20%）
                CASE 
                    WHEN group_record.daily_rate_limit = 0.005 THEN 0.003
                    WHEN group_record.daily_rate_limit = 0.010 THEN 0.004
                    WHEN group_record.daily_rate_limit = 0.0125 THEN 0.0046
                    WHEN group_record.daily_rate_limit = 0.015 THEN 0.0052
                    WHEN group_record.daily_rate_limit = 0.0175 THEN 0.0058
                    WHEN group_record.daily_rate_limit = 0.020 THEN 0.0064
                    ELSE 0.004
                END,
                -- 金曜日の日利（週利の15%）
                CASE 
                    WHEN group_record.daily_rate_limit = 0.005 THEN 0.00225
                    WHEN group_record.daily_rate_limit = 0.010 THEN 0.003
                    WHEN group_record.daily_rate_limit = 0.0125 THEN 0.00345
                    WHEN group_record.daily_rate_limit = 0.015 THEN 0.0039
                    WHEN group_record.daily_rate_limit = 0.0175 THEN 0.00435
                    WHEN group_record.daily_rate_limit = 0.020 THEN 0.0048
                    ELSE 0.003
                END,
                group_record.id,
                group_record.group_name,
                'RESTORED_FROM_SPECIFICATION',
                NOW(),
                NOW()
            )
            ON CONFLICT (week_start_date, group_id) DO NOTHING;
        END LOOP;
        
        weeks_created := weeks_created + 1;
        week_start := week_start + 7; -- 次の週
    END LOOP;
    
    RETURN format('✅ %s週分の週利設定を復元しました', weeks_created);
END;
$$;

-- 4. 関数作成完了確認
SELECT 
    '🔧 修正された関数作成完了' as status,
    COUNT(*) as created_functions,
    array_agg(routine_name) as function_names
FROM information_schema.routines 
WHERE routine_name IN (
    'calculate_daily_rewards_for_date',
    'force_daily_calculation',
    'restore_weekly_rates_from_csv_data'
);
