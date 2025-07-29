-- 修正されたトリガーを使用した安全な日利計算

DO $$
DECLARE
    calc_date DATE;
    nft_record RECORD;
    daily_rate DECIMAL(10,6);
    reward_amount DECIMAL(10,2);
    week_start DATE;
    day_column TEXT;
    total_processed INTEGER := 0;
    total_skipped INTEGER := 0;
    existing_reward INTEGER;
BEGIN
    RAISE NOTICE '安全な日利計算開始...';
    
    -- 今日のみテスト計算
    calc_date := CURRENT_DATE;
    
    -- 平日のみ処理
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
        
        -- 全てのアクティブNFTについて計算（テスト用に5件のみ）
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
            AND un.id IS NOT NULL
            AND un.user_id IS NOT NULL
            AND un.nft_id IS NOT NULL
            AND un.purchase_price > 0
            ORDER BY un.user_id, un.id
            LIMIT 5 -- テスト用に5件のみ
        LOOP
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
                
                IF reward_amount > 0 THEN
                    RAISE NOTICE '処理中: ユーザー% (%), NFT% (%), user_nft_id=%, 日利=%, 報酬=%', 
                        nft_record.user_name, nft_record.user_id, nft_record.nft_name, nft_record.nft_id, 
                        nft_record.user_nft_id, daily_rate, reward_amount;
                    
                    BEGIN
                        -- 修正されたトリガーを使用してINSERT
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
                        
                        total_processed := total_processed + 1;
                        RAISE NOTICE '✅ INSERT成功: %件目', total_processed;
                        
                    EXCEPTION WHEN OTHERS THEN
                        total_skipped := total_skipped + 1;
                        RAISE NOTICE '❌ INSERT失敗: % - %', SQLERRM, SQLSTATE;
                        RAISE NOTICE '詳細: user_id=%, user_nft_id=%, nft_id=%, reward_date=%', 
                            nft_record.user_id, nft_record.user_nft_id, nft_record.nft_id, calc_date;
                    END;
                ELSE
                    total_skipped := total_skipped + 1;
                    RAISE NOTICE 'スキップ: 報酬額が0以下 (ユーザー%, NFT%)', nft_record.user_name, nft_record.nft_name;
                END IF;
            ELSE
                total_skipped := total_skipped + 1;
                RAISE NOTICE 'スキップ: 既存レコード (ユーザー%, NFT%, 日付%)', 
                    nft_record.user_name, nft_record.nft_name, calc_date;
            END IF;
        END LOOP;
    ELSE
        RAISE NOTICE '今日は平日ではありません: %', calc_date;
    END IF;
    
    RAISE NOTICE '安全な日利計算完了！処理件数: %件, スキップ件数: %件', total_processed, total_skipped;
END $$;
