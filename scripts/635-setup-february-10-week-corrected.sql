-- 2月10日週の設定を修正版で実行

-- 1. 2月10日週の基本情報
SELECT 
    '📅 2月10日週設定準備' as section,
    '2025-02-10'::DATE as week_start,
    '2025-02-14'::DATE as week_end,
    EXTRACT(DOW FROM '2025-02-10'::DATE) as day_of_week_check;

-- 2. 利用可能なグループを確認
SELECT 
    '📊 利用可能グループ確認' as section,
    * 
FROM show_available_groups();

-- 3. 既存の2月10日週設定を確認
SELECT 
    '🔍 既存設定確認' as section,
    *
FROM group_weekly_rates 
WHERE week_start_date = '2025-02-10'::DATE;

-- 4. 設定が存在しない場合のみ作成
DO $$
DECLARE
    group_rec RECORD;
    week_start DATE := '2025-02-10'::DATE;
    week_end DATE := '2025-02-14'::DATE;
    base_rates NUMERIC[] := ARRAY[1.5, 2.0, 2.3, 2.6, 2.9, 3.2];
    rate_index INTEGER := 1;
BEGIN
    -- 既存設定をチェック
    IF EXISTS(SELECT 1 FROM group_weekly_rates WHERE week_start_date = week_start) THEN
        RAISE NOTICE '2月10日週の設定は既に存在します';
        RETURN;
    END IF;
    
    -- 各グループに対して週利設定
    FOR group_rec IN 
        SELECT id, group_name FROM daily_rate_groups ORDER BY group_name
    LOOP
        INSERT INTO group_weekly_rates (
            id,
            group_id,
            week_start_date,
            week_end_date,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            group_rec.id,
            week_start,
            week_end,
            base_rates[rate_index] / 100.0,
            base_rates[rate_index] / 100.0 * 0.2,
            base_rates[rate_index] / 100.0 * 0.2,
            base_rates[rate_index] / 100.0 * 0.2,
            base_rates[rate_index] / 100.0 * 0.2,
            base_rates[rate_index] / 100.0 * 0.2,
            'equal',
            NOW(),
            NOW()
        );
        
        rate_index := rate_index + 1;
        IF rate_index > array_length(base_rates, 1) THEN
            rate_index := array_length(base_rates, 1);
        END IF;
        
        RAISE NOTICE '設定完了: % - %.%％', group_rec.group_name, base_rates[LEAST(rate_index, array_length(base_rates, 1))];
    END LOOP;
    
    RAISE NOTICE '2月10日週の設定が完了しました';
END $$;

-- 5. 設定結果を確認
SELECT 
    '✅ 設定結果確認' as section,
    drg.group_name,
    gwr.weekly_rate * 100 as weekly_rate_percent,
    gwr.monday_rate * 100 as monday_percent,
    gwr.tuesday_rate * 100 as tuesday_percent,
    gwr.wednesday_rate * 100 as wednesday_percent,
    gwr.thursday_rate * 100 as thursday_percent,
    gwr.friday_rate * 100 as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'::DATE
ORDER BY drg.group_name;

SELECT '2月10日週設定完了!' as status;
