-- 緊急修正：全ての問題を一括解決

-- 1. 変数名の曖昧性を解決した復元関数
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
    
    -- UNIQUE制約の存在確認（変数名を変更）
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

-- 2. NFTテーブルにdaily_rate_group_idカラムを追加
DO $$
BEGIN
    -- nftsテーブルにdaily_rate_group_idカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nfts' 
        AND column_name = 'daily_rate_group_id'
    ) THEN
        ALTER TABLE nfts ADD COLUMN daily_rate_group_id UUID;
        RAISE NOTICE 'daily_rate_group_idカラムを追加しました';
        
        -- 既存のNFTにグループIDを設定
        UPDATE nfts SET daily_rate_group_id = (
            SELECT drg.id 
            FROM daily_rate_groups drg 
            WHERE drg.daily_rate_limit = nfts.daily_rate_limit
            LIMIT 1
        );
        
        RAISE NOTICE 'NFTにグループIDを設定しました';
    ELSE
        RAISE NOTICE 'daily_rate_group_idカラムは既に存在します';
    END IF;
    
    -- 外部キー制約を追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'nfts' 
        AND constraint_name = 'fk_nfts_daily_rate_group'
    ) THEN
        ALTER TABLE nfts 
        ADD CONSTRAINT fk_nfts_daily_rate_group 
        FOREIGN KEY (daily_rate_group_id) REFERENCES daily_rate_groups(id);
        
        RAISE NOTICE '外部キー制約を追加しました';
    ELSE
        RAISE NOTICE '外部キー制約は既に存在します';
    END IF;
END $$;

-- 3. 復元実行
SELECT restore_weekly_rates_from_csv_data() as restoration_result;

-- 4. 日利計算関数を修正
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
BEGIN
    -- 平日のみ計算（月曜=1, 火曜=2, 水曜=3, 木曜=4, 金曜=5）
    day_of_week := EXTRACT(DOW FROM target_date);
    
    IF day_of_week NOT IN (1, 2, 3, 4, 5) THEN
        RETURN format('⚠️ %s は平日ではありません（土日は計算対象外）', target_date);
    END IF;
    
    -- 既存の計算結果を削除
    DELETE FROM daily_rewards WHERE reward_date = target_date;
    
    -- アクティブなNFTに対して日利計算
    FOR user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.investment_amount,
            n.daily_rate_limit,
            n.daily_rate_group_id,
            drg.group_name
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
        WHERE un.is_active = true
        AND un.investment_amount > 0
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
        AND gwr.week_start_date <= target_date
        AND gwr.week_start_date + 6 >= target_date;
        
        -- 日利が見つからない場合はデフォルト値を使用
        IF daily_rate_value IS NULL THEN
            daily_rate_value := LEAST(user_nft_record.daily_rate_limit, 0.005); -- 最大0.5%
        END IF;
        
        -- NFTの日利上限を適用
        daily_rate_value := LEAST(daily_rate_value, user_nft_record.daily_rate_limit);
        
        -- 報酬額計算
        reward_amount := user_nft_record.investment_amount * daily_rate_value;
        
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
        
        rewards_calculated := rewards_calculated + 1;
    END LOOP;
    
    RETURN format('✅ %s件の日利報酬を計算しました（%s）', rewards_calculated, target_date);
END;
$$;

-- 5. 今日の日利計算を実行
SELECT calculate_daily_rewards_for_date(CURRENT_DATE) as calculation_result;
