-- 緊急：全ユーザーの日利計算を強制実行
-- テーブル構造確認後の正しいバージョン

-- 1. 現在の週の週利データを確認・作成
DO $$
DECLARE
    current_week_start DATE;
    current_week_end DATE;
    week_number INTEGER;
    group_record RECORD;
    rates_exist INTEGER;
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
        -- 既存データをチェック
        SELECT COUNT(*) INTO rates_exist
        FROM group_weekly_rates 
        WHERE group_id = group_record.id 
        AND week_start_date = current_week_start;
        
        IF rates_exist = 0 THEN
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
            ) VALUES (
                group_record.id,
                current_week_start,
                current_week_end,
                week_number,
                0.026, -- 2.6%
                0.005, 0.006, 0.005, 0.005, 0.005, -- デフォルト日利配分
                'EMERGENCY_DEFAULT'
            );
            
            RAISE NOTICE 'グループ % の週利データ作成完了', group_record.group_name;
        ELSE
            RAISE NOTICE 'グループ % の週利データは既に存在', group_record.group_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '週利データ作成完了';
END $$;

-- 2. 全ユーザーの日利を強制計算（過去4週間分）
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
    existing_reward INTEGER;
BEGIN
    RAISE NOTICE '日利計算開始...';
    
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
            
            RAISE NOTICE '計算日: % (曜日カラム: %)', calc_date, day_column;
            
            -- 全ユーザーのアクティブNFTについて計算
            FOR user_record IN 
                SELECT DISTINCT u.id as user_id, COALESCE(u.name, u.email, u.id::text) as user_name
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
                    -- 既存の報酬レコードをチェック
                    SELECT COUNT(*) INTO existing_reward
                    FROM daily_rewards 
                    WHERE user_id = user_record.user_id 
                    AND user_nft_id = nft_record.user_nft_id 
                    AND reward_date = calc_date;
                    
                    IF existing_reward = 0 THEN
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
                            ) VALUES (
                                user_record.user_id, 
                                nft_record.user_nft_id, 
                                calc_date, 
                                reward_amount, 
                                daily_rate, 
                                CURRENT_TIMESTAMP
                            );
                            
                            -- user_nftsのtotal_earnedを更新
                            UPDATE user_nfts 
                            SET 
                                total_earned = total_earned + reward_amount,
                                updated_at = CURRENT_TIMESTAMP
                            WHERE id = nft_record.user_nft_id;
                            
                            total_processed := total_processed + 1;
                            
                            IF total_processed % 100 = 0 THEN
                                RAISE NOTICE '処理済み: %件', total_processed;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
    END LOOP;
    
    RAISE NOTICE '全ユーザーの日利計算完了！処理件数: %件', total_processed;
END $$;
