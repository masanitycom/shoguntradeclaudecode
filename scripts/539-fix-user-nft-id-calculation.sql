-- user_nft_idの問題を修正した日利計算

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

-- 2. user_nft_idを正確に取得する日利計算
DO $$
DECLARE
    calc_date DATE;
    nft_record RECORD;
    daily_rate DECIMAL(10,6);
    reward_amount DECIMAL(10,2);
    week_start DATE;
    day_column TEXT;
    total_processed INTEGER := 0;
    existing_reward INTEGER;
    user_name TEXT;
BEGIN
    RAISE NOTICE '修正版日利計算開始...';
    
    -- 今日から過去1週間の平日について計算
    FOR i IN 0..6 LOOP -- 1週間のテスト
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
            
            RAISE NOTICE '計算日: % (週開始: %, 曜日カラム: %)', calc_date, week_start, day_column;
            
            -- 全てのアクティブNFTについて直接計算（JOINを使用）
            FOR nft_record IN
                SELECT 
                    un.id as user_nft_id,
                    un.user_id,
                    un.nft_id,
                    un.purchase_price, 
                    un.total_earned,
                    un.purchase_date,
                    n.name as nft_name,
                    n.daily_rate_limit, 
                    drg.id as group_id,
                    drg.group_name,
                    COALESCE(u.name, u.email, u.id::text) as user_name
                FROM user_nfts un
                INNER JOIN nfts n ON un.nft_id = n.id
                INNER JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
                INNER JOIN users u ON un.user_id = u.id
                WHERE un.is_active = true
                AND un.purchase_date <= calc_date
                AND un.total_earned < un.purchase_price * 3 -- 300%未満
                ORDER BY un.user_id, un.id
                LIMIT 10 -- テスト用に制限
            LOOP
                -- user_nft_idがNULLでないことを確認
                IF nft_record.user_nft_id IS NULL THEN
                    RAISE NOTICE '⚠️ user_nft_idがNULL: ユーザー%, NFT%', nft_record.user_id, nft_record.nft_id;
                    CONTINUE;
                END IF;
                
                -- 既存の報酬レコードをチェック
                SELECT COUNT(*) INTO existing_reward
                FROM daily_rewards 
                WHERE user_nft_id = nft_record.user_nft_id 
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
                        RAISE NOTICE '処理中: ユーザー% (%), NFT% (%), user_nft_id=%, 日利=%, 報酬=%', 
                            nft_record.user_name, nft_record.user_id, nft_record.nft_name, nft_record.nft_id, 
                            nft_record.user_nft_id, daily_rate, reward_amount;
                        
                        -- 段階的にINSERTを試行
                        BEGIN
                            -- 最小限のカラムでINSERT
                            INSERT INTO daily_rewards (
                                user_id,
                                user_nft_id,
                                nft_id,
                                reward_date,
                                reward_amount
                            ) VALUES (
                                nft_record.user_id,
                                nft_record.user_nft_id,
                                nft_record.nft_id,
                                calc_date,
                                reward_amount
                            );
                            
                            RAISE NOTICE '✅ 最小カラムでINSERT成功';
                            
                        EXCEPTION WHEN OTHERS THEN
                            RAISE NOTICE '❌ 最小カラムでINSERT失敗: %', SQLERRM;
                            
                            -- より多くのカラムでINSERT
                            BEGIN
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
                                ) VALUES (
                                    nft_record.user_id,
                                    nft_record.user_nft_id,
                                    nft_record.nft_id,
                                    calc_date,
                                    week_start,
                                    daily_rate,
                                    reward_amount,
                                    false,
                                    CURRENT_TIMESTAMP,
                                    CURRENT_TIMESTAMP
                                );
                                
                                RAISE NOTICE '✅ 拡張カラムでINSERT成功';
                                
                            EXCEPTION WHEN OTHERS THEN
                                RAISE NOTICE '❌ 拡張カラムでINSERT失敗: %', SQLERRM;
                                RAISE NOTICE '詳細: user_id=%, user_nft_id=%, nft_id=%, reward_date=%', 
                                    nft_record.user_id, nft_record.user_nft_id, nft_record.nft_id, calc_date;
                                CONTINUE;
                            END;
                        END;
                        
                        -- user_nftsのtotal_earnedを更新
                        UPDATE user_nfts 
                        SET 
                            total_earned = total_earned + reward_amount,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = nft_record.user_nft_id;
                        
                        total_processed := total_processed + 1;
                        
                    ELSE
                        RAISE NOTICE 'スキップ: 報酬額が0以下 (ユーザー%, NFT%)', nft_record.user_name, nft_record.nft_name;
                    END IF;
                ELSE
                    RAISE NOTICE 'スキップ: 既存レコード (ユーザー%, NFT%, 日付%)', 
                        nft_record.user_name, nft_record.nft_name, calc_date;
                END IF;
            END LOOP;
        END IF;
    END LOOP;
    
    RAISE NOTICE '修正版日利計算完了！処理件数: %件', total_processed;
END $$;
