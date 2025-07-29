-- 緊急：全ユーザーの日利計算を強制実行
-- 正しいテーブル構造を使用

-- 1. テーブル構造を確認
SELECT 
    '📋 group_weekly_rates構造確認' as status,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;

-- 2. 現在の週の週利データを確認・作成
DO $$
DECLARE
    current_week_start DATE;
    current_week_end DATE;
    week_number INTEGER;
    group_record RECORD;
BEGIN
    -- 現在の週の開始日と終了日を計算
    current_week_start := date_trunc('week', CURRENT_DATE);
    current_week_end := current_week_start + INTERVAL '6 days';
    week_number := EXTRACT(week FROM CURRENT_DATE);
    
    RAISE NOTICE '現在の週: % - % (第%週)', current_week_start, current_week_end, week_number;
    
    -- 各グループの週利データが存在しない場合は作成
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
            distribution_method
        )
        SELECT 
            group_record.id,
            current_week_start,
            current_week_end,
            week_number,
            0.026, -- 2.6%
            0.005, 0.006, 0.005, 0.005, 0.005, -- デフォルト日利配分
            'EMERGENCY_DEFAULT'
        WHERE NOT EXISTS (
            SELECT 1 FROM group_weekly_rates gwr 
            WHERE gwr.group_id = group_record.id 
            AND gwr.week_start_date = current_week_start
        );
        
        RAISE NOTICE 'グループ % の週利データ作成/確認完了', group_record.group_name;
    END LOOP;
    
    RAISE NOTICE '週利データ作成完了';
END $$;

-- 3. 全ユーザーの日利を強制計算（過去4週間分）
DO $$
DECLARE
    calc_date DATE;
    user_record RECORD;
    nft_record RECORD;
    daily_rate DECIMAL(10,6);
    reward_amount DECIMAL(10,2);
    week_start DATE;
    day_column TEXT;
    total_processed INTEGER := 0;
BEGIN
    RAISE NOTICE '🚀 日利計算開始...';
    
    -- 過去4週間の平日について計算
    FOR i IN 0..27 LOOP -- 4週間 = 28日
        calc_date := CURRENT_DATE - INTERVAL '1 day' * i;
        
        -- 平日のみ処理（月曜=1, 金曜=5）
        IF EXTRACT(dow FROM calc_date) BETWEEN 1 AND 5 THEN
            week_start := date_trunc('week', calc_date);
            day_column := CASE EXTRACT(dow FROM calc_date)
                WHEN 1 THEN 'monday_rate'
                WHEN 2 THEN 'tuesday_rate'
                WHEN 3 THEN 'wednesday_rate'
                WHEN 4 THEN 'thursday_rate'
                WHEN 5 THEN 'friday_rate'
            END;
            
            RAISE NOTICE '📅 計算日: % (曜日カラム: %)', calc_date, day_column;
            
            -- 全ユーザーのアクティブNFTについて計算
            FOR user_record IN 
                SELECT DISTINCT u.id as user_id, u.display_name
                FROM users u
                INNER JOIN user_nfts un ON u.id = un.user_id
                WHERE un.is_active = true
                AND un.purchase_date <= calc_date
            LOOP
                -- ユーザーの各NFTについて計算
                FOR nft_record IN
                    SELECT 
                        un.id as user_nft_id, 
                        un.purchase_price, 
                        un.total_earned,
                        n.daily_rate_limit, 
                        drg.id as group_id,
                        drg.group_name
                    FROM user_nfts un
                    INNER JOIN nfts n ON un.nft_id = n.id
                    INNER JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
                    WHERE un.user_id = user_record.user_id 
                    AND un.is_active = true
                    AND un.purchase_date <= calc_date
                    AND un.total_earned < un.purchase_price * 3 -- 300%未満
                LOOP
                    -- その日の日利を取得
                    EXECUTE format('
                        SELECT COALESCE(%I, 0) 
                        FROM group_weekly_rates 
                        WHERE group_id = $1 AND week_start_date = $2
                        LIMIT 1
                    ', day_column) 
                    INTO daily_rate 
                    USING nft_record.group_id, week_start;
                    
                    -- デフォルト値設定
                    IF daily_rate IS NULL OR daily_rate = 0 THEN
                        daily_rate := 0.005; -- デフォルト0.5%
                    END IF;
                    
                    -- 日利上限を適用
                    IF daily_rate > nft_record.daily_rate_limit THEN
                        daily_rate := nft_record.daily_rate_limit;
                    END IF;
                    
                    -- 報酬計算
                    reward_amount := nft_record.purchase_price * daily_rate;
                    
                    -- 300%上限チェック
                    IF nft_record.total_earned + reward_amount > nft_record.purchase_price * 3 THEN
                        reward_amount := nft_record.purchase_price * 3 - nft_record.total_earned;
                    END IF;
                    
                    IF reward_amount > 0 THEN
                        -- 日利報酬を記録
                        INSERT INTO daily_rewards (
                            user_id, 
                            user_nft_id, 
                            reward_date, 
                            reward_amount, 
                            daily_rate_used, 
                            calculation_date
                        )
                        VALUES (
                            user_record.user_id, 
                            nft_record.user_nft_id, 
                            calc_date, 
                            reward_amount, 
                            daily_rate, 
                            CURRENT_TIMESTAMP
                        )
                        ON CONFLICT (user_id, user_nft_id, reward_date) 
                        DO UPDATE SET 
                            reward_amount = EXCLUDED.reward_amount,
                            daily_rate_used = EXCLUDED.daily_rate_used,
                            calculation_date = EXCLUDED.calculation_date;
                        
                        -- user_nftsのtotal_earnedを更新
                        UPDATE user_nfts 
                        SET 
                            total_earned = (
                                SELECT COALESCE(SUM(reward_amount), 0) 
                                FROM daily_rewards 
                                WHERE user_nft_id = nft_record.user_nft_id
                            ),
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = nft_record.user_nft_id;
                        
                        total_processed := total_processed + 1;
                        
                        IF total_processed % 100 = 0 THEN
                            RAISE NOTICE '💰 処理済み: %件', total_processed;
                        END IF;
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ 全ユーザーの日利計算完了！処理件数: %件', total_processed;
END $$;

-- 4. 結果確認
SELECT 
    '🏆 トップユーザー確認' as check_type,
    u.display_name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(un.total_earned) as total_earned,
    COUNT(CASE WHEN un.total_earned >= un.purchase_price * 3 THEN 1 END) as completed_nfts
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
GROUP BY u.id, u.display_name
HAVING SUM(un.purchase_price) > 0
ORDER BY total_earned DESC
LIMIT 10;

-- 5. 日利報酬の確認
SELECT 
    '📊 日利報酬サマリー' as check_type,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date,
    COUNT(DISTINCT user_id) as unique_users
FROM daily_rewards;

RAISE NOTICE '🎉 緊急修正完了！全ユーザーの報酬計算が実行されました！';
