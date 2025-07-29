-- 🚨 緊急：週利設定復旧とシステム修正
-- 失われた週利設定の復旧と保護システム強化

-- 1. まず現在の状況を確認
SELECT 
    '🔍 現在の週利設定状況' as info,
    COUNT(*) as total_settings,
    COUNT(DISTINCT week_start_date) as unique_weeks,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 2. バックアップテーブルの確認
SELECT 
    '📋 バックアップ状況確認' as info,
    COUNT(*) as backup_count,
    MAX(backup_date) as latest_backup
FROM weekly_rates_backup;

-- 3. 失われた週利設定を手動で復旧（2/10の週から）
-- 2024年2月10日の週（2/5-2/11）から復旧

-- まず、2024年2月5日（月曜日）からの週利設定を作成
DO $$
DECLARE
    start_date DATE := '2024-02-05'; -- 2024年2月5日（月曜日）
    current_week_start DATE;
    week_count INTEGER := 0;
    group_record RECORD;
    rates RECORD;
BEGIN
    -- 現在の日付まで週利設定を作成
    current_week_start := start_date;
    
    WHILE current_week_start <= CURRENT_DATE AND week_count < 50 LOOP
        RAISE NOTICE '週利設定を作成中: %', current_week_start;
        
        -- 既存の設定があるかチェック
        IF NOT EXISTS (
            SELECT 1 FROM group_weekly_rates 
            WHERE week_start_date = current_week_start
        ) THEN
            -- 各グループに対して週利設定を作成
            FOR group_record IN 
                SELECT id, group_name, daily_rate_limit 
                FROM daily_rate_groups 
                ORDER BY daily_rate_limit
            LOOP
                -- ランダム配分を生成（週利2.6%をベースに）
                WITH random_distribution AS (
                    SELECT 
                        0.004 + (RANDOM() * 0.006) as monday_rate,    -- 0.4% - 1.0%
                        0.004 + (RANDOM() * 0.006) as tuesday_rate,   -- 0.4% - 1.0%
                        0.004 + (RANDOM() * 0.006) as wednesday_rate, -- 0.4% - 1.0%
                        0.004 + (RANDOM() * 0.006) as thursday_rate,  -- 0.4% - 1.0%
                        0.004 + (RANDOM() * 0.006) as friday_rate     -- 0.4% - 1.0%
                )
                SELECT * INTO rates FROM random_distribution;
                
                -- 合計を2.6%に調整
                DECLARE
                    total_rate DECIMAL := rates.monday_rate + rates.tuesday_rate + rates.wednesday_rate + rates.thursday_rate + rates.friday_rate;
                    adjustment_factor DECIMAL := 0.026 / total_rate;
                BEGIN
                    rates.monday_rate := rates.monday_rate * adjustment_factor;
                    rates.tuesday_rate := rates.tuesday_rate * adjustment_factor;
                    rates.wednesday_rate := rates.wednesday_rate * adjustment_factor;
                    rates.thursday_rate := rates.thursday_rate * adjustment_factor;
                    rates.friday_rate := rates.friday_rate * adjustment_factor;
                END;
                
                -- 週利設定を挿入
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
                    current_week_start + INTERVAL '6 days',
                    EXTRACT(WEEK FROM current_week_start),
                    0.026, -- 2.6%
                    rates.monday_rate,
                    rates.tuesday_rate,
                    rates.wednesday_rate,
                    rates.thursday_rate,
                    rates.friday_rate,
                    'RECOVERY_AUTO_GENERATED',
                    NOW()
                );
            END LOOP;
            
            week_count := week_count + 1;
        END IF;
        
        -- 次の週へ
        current_week_start := current_week_start + INTERVAL '7 days';
    END LOOP;
    
    RAISE NOTICE '週利設定復旧完了: %週分', week_count;
END $$;

-- 4. 復旧結果を確認
SELECT 
    '✅ 復旧結果確認' as info,
    COUNT(*) as total_settings,
    COUNT(DISTINCT week_start_date) as unique_weeks,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 5. 週別の設定数を確認
SELECT 
    '📅 週別設定確認' as info,
    week_start_date,
    COUNT(*) as group_count,
    ROUND(AVG(weekly_rate) * 100, 2) || '%' as avg_weekly_rate
FROM group_weekly_rates
ORDER BY week_start_date DESC
LIMIT 10;
