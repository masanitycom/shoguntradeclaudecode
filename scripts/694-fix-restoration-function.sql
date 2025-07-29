-- 復元関数の修正

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS restore_weekly_rates_from_csv_data();

-- 2. 修正された復元関数を作成
CREATE OR REPLACE FUNCTION restore_weekly_rates_from_csv_data()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    week_start DATE;
    week_end DATE;
    group_record RECORD;
    weeks_created INTEGER := 0;
    constraint_name TEXT;
BEGIN
    -- 2024年12月2日（月曜日）から開始
    week_start := '2024-12-02';
    
    -- UNIQUE制約を一時的に確認・作成
    SELECT constraint_name INTO constraint_name
    FROM information_schema.table_constraints 
    WHERE table_name = 'group_weekly_rates' 
    AND constraint_type = 'UNIQUE'
    LIMIT 1;
    
    IF constraint_name IS NULL THEN
        -- UNIQUE制約を作成
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT unique_week_group 
        UNIQUE (week_start_date, group_id);
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

-- 3. 復元実行
SELECT restore_weekly_rates_from_csv_data() as restoration_result;
