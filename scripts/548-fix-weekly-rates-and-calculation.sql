-- 週利設定と日利計算の完全修正

-- 1. 現在の週利設定を全削除（データ整合性のため）
DELETE FROM group_weekly_rates;

-- 2. 今週の週利設定を強制作成
DO $$
DECLARE
    current_week_start DATE;
    current_week_end DATE;
    week_number INTEGER;
    group_record RECORD;
BEGIN
    -- 今週の月曜日を計算
    current_week_start := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE;
    current_week_end := current_week_start + INTERVAL '6 days';
    week_number := EXTRACT(week FROM CURRENT_DATE);
    
    RAISE NOTICE '今週の週利設定を作成: % - %', current_week_start, current_week_end;
    
    -- 各グループに週利設定を作成
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit 
        FROM daily_rate_groups 
        ORDER BY daily_rate_limit
    LOOP
        INSERT INTO group_weekly_rates (
            group_id,
            week_start_date,
            week_end_date,
            week_number,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            created_at
        ) VALUES (
            group_record.id,
            current_week_start,
            current_week_end,
            week_number,
            0.026, -- 2.6%
            0.005, -- 0.5%
            0.006, -- 0.6%
            0.005, -- 0.5%
            0.005, -- 0.5%
            0.005, -- 0.5%
            'SYSTEM_DEFAULT',
            NOW()
        );
        
        RAISE NOTICE 'グループ % の週利設定作成完了', group_record.group_name;
    END LOOP;
END $$;

-- 3. 過去3週間の週利設定も作成（履歴データのため）
DO $$
DECLARE
    week_start DATE;
    week_end DATE;
    week_number INTEGER;
    group_record RECORD;
BEGIN
    -- 過去3週間分作成
    FOR i IN 1..3 LOOP
        week_start := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day' - INTERVAL '7 days' * i)::DATE;
        week_end := week_start + INTERVAL '6 days';
        week_number := EXTRACT(week FROM week_start);
        
        RAISE NOTICE '過去週利設定作成: % - %', week_start, week_end;
        
        FOR group_record IN 
            SELECT id, group_name, daily_rate_limit 
            FROM daily_rate_groups 
            ORDER BY daily_rate_limit
        LOOP
            INSERT INTO group_weekly_rates (
                group_id,
                week_start_date,
                week_end_date,
                week_number,
                weekly_rate,
                monday_rate,
                tuesday_rate,
                wednesday_rate,
                thursday_rate,
                friday_rate,
                distribution_method,
                created_at
            ) VALUES (
                group_record.id,
                week_start,
                week_end,
                week_number,
                0.026, -- 2.6%
                0.005, -- 0.5%
                0.006, -- 0.6%
                0.005, -- 0.5%
                0.005, -- 0.5%
                0.005, -- 0.5%
                'HISTORICAL_DATA',
                NOW() - INTERVAL '7 days' * i
            );
        END LOOP;
    END LOOP;
END $$;

-- 4. 日利計算関数を完全に修正
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch(DATE);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch(
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    message TEXT,
    processed_count INTEGER,
    total_rewards DECIMAL,
    completed_nfts INTEGER,
    error_message TEXT
) AS $$
DECLARE
    calc_date DATE := p_calculation_date;
    day_of_week INTEGER;
    processed_count INTEGER := 0;
    total_amount DECIMAL := 0;
    completed_count INTEGER := 0;
    error_msg TEXT := NULL;
    debug_info TEXT := '';
BEGIN
    -- 曜日を取得（0=日曜、1=月曜、...、6=土曜）
    day_of_week := EXTRACT(DOW FROM calc_date);
    
    -- 平日のみ処理（月〜金：1-5）
    IF day_of_week NOT BETWEEN 1 AND 5 THEN
        RETURN QUERY SELECT 
            format('土日は日利計算を行いません: %s (曜日: %s)', calc_date, day_of_week)::TEXT,
            0::INTEGER,
            0::DECIMAL,
            0::INTEGER,
            NULL::TEXT;
        RETURN;
    END IF;

    BEGIN
        -- デバッグ情報
        debug_info := format('計算日: %s, 曜日: %s', calc_date, day_of_week);
        
        -- 今日の既存レコードを削除
        DELETE FROM daily_rewards WHERE reward_date = calc_date;
        
        -- 週利設定の存在確認
        IF NOT EXISTS (
            SELECT 1 FROM group_weekly_rates gwr
            WHERE calc_date BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
        ) THEN
            error_msg := format('週利設定が見つかりません: %s', calc_date);
            RAISE EXCEPTION '%', error_msg;
        END IF;
        
        -- 日利計算実行
        WITH calculation_data AS (
            SELECT 
                un.id as user_nft_id,
                un.user_id,
                un.nft_id,
                un.purchase_price as investment_amount,
                n.name as nft_name,
                n.daily_rate_limit,
                CASE 
                    WHEN day_of_week = 1 THEN gwr.monday_rate
                    WHEN day_of_week = 2 THEN gwr.tuesday_rate
                    WHEN day_of_week = 3 THEN gwr.wednesday_rate
                    WHEN day_of_week = 4 THEN gwr.thursday_rate
                    WHEN day_of_week = 5 THEN gwr.friday_rate
                    ELSE 0
                END as daily_rate
            FROM user_nfts un
            JOIN nfts n ON un.nft_id = n.id
            JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
            JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
            WHERE un.is_active = true
            AND un.purchase_price > 0
            AND n.is_active = true
            AND calc_date BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
            AND un.total_earned < un.purchase_price * 3 -- 300%未満
        )
        INSERT INTO daily_rewards (
            user_id,
            user_nft_id,
            nft_id,
            reward_date,
            week_start_date,
            daily_rate,
            reward_amount,
            is_claimed,
            created_at,
            updated_at
        )
        SELECT 
            user_id,
            user_nft_id,
            nft_id,
            calc_date,
            (DATE_TRUNC('week', calc_date) + INTERVAL '1 day')::DATE,
            LEAST(daily_rate, daily_rate_limit),
            investment_amount * LEAST(daily_rate, daily_rate_limit),
            false,
            NOW(),
            NOW()
        FROM calculation_data
        WHERE daily_rate > 0;
        
        -- 処理件数取得
        GET DIAGNOSTICS processed_count = ROW_COUNT;
        
        -- 合計金額計算
        SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
        FROM daily_rewards 
        WHERE reward_date = calc_date;
        
        -- user_nftsのtotal_earnedを更新
        UPDATE user_nfts 
        SET total_earned = (
            SELECT COALESCE(SUM(dr.reward_amount), 0)
            FROM daily_rewards dr
            WHERE dr.user_nft_id = user_nfts.id
        ),
        updated_at = NOW()
        WHERE is_active = true;
        
        -- 300%達成NFTを無効化
        UPDATE user_nfts 
        SET is_active = false,
            updated_at = NOW()
        WHERE total_earned >= purchase_price * 3
        AND is_active = true;
        
        -- 完了NFT数を計算
        SELECT COUNT(*) INTO completed_count
        FROM user_nfts 
        WHERE total_earned >= purchase_price * 3;
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        processed_count := 0;
        total_amount := 0;
        completed_count := 0;
    END;
    
    RETURN QUERY SELECT 
        CASE 
            WHEN error_msg IS NOT NULL THEN format('エラー: %s (%s)', error_msg, debug_info)
            WHEN processed_count > 0 THEN format('成功: %s件処理, 合計$%.2f (%s)', processed_count, total_amount, debug_info)
            ELSE format('処理対象なし (%s)', debug_info)
        END::TEXT,
        processed_count::INTEGER,
        total_amount::DECIMAL,
        completed_count::INTEGER,
        error_msg::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 5. 今日の日利計算を実行
SELECT 
    '🚀 今日の日利計算実行' as status,
    * 
FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 6. 結果確認
SELECT 
    '📊 計算結果確認' as info,
    COUNT(*) as total_records,
    SUM(reward_amount) as total_rewards,
    COUNT(DISTINCT user_id) as unique_users
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 7. 週利設定確認
SELECT 
    '📈 週利設定確認' as info,
    COUNT(*) as total_weekly_rates,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

SELECT '✅ 週利設定と日利計算の修正完了' as final_status;
