-- 不足していたset_group_weekly_rate関数を作成

-- 1. 既存関数を削除
DROP FUNCTION IF EXISTS set_group_weekly_rate(DATE, TEXT, NUMERIC);

-- 2. set_group_weekly_rate関数を作成
CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name VARCHAR(50),
    p_weekly_rate NUMERIC
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_group_id UUID;
    v_week_end_date DATE;
    v_daily_rate NUMERIC;
BEGIN
    -- 月曜日チェック
    IF EXTRACT(DOW FROM p_week_start_date) != 1 THEN
        RETURN QUERY SELECT FALSE, '開始日は月曜日である必要があります';
        RETURN;
    END IF;
    
    -- 週利範囲チェック
    IF p_weekly_rate < 0 OR p_weekly_rate > 10 THEN
        RETURN QUERY SELECT FALSE, '週利は0%から10%の範囲で設定してください';
        RETURN;
    END IF;
    
    -- グループIDを取得
    SELECT id INTO v_group_id 
    FROM daily_rate_groups 
    WHERE group_name = p_group_name;
    
    IF v_group_id IS NULL THEN
        RETURN QUERY SELECT FALSE, format('グループ "%s" が見つかりません', p_group_name);
        RETURN;
    END IF;
    
    -- 週末日を計算
    v_week_end_date := p_week_start_date + INTERVAL '4 days';
    
    -- 日利を計算（週利を5日で等分）
    v_daily_rate := (p_weekly_rate / 100.0) / 5.0;
    
    -- 既存設定を更新または新規作成
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
        v_group_id,
        p_week_start_date,
        v_week_end_date,
        p_weekly_rate / 100.0,
        v_daily_rate,
        v_daily_rate,
        v_daily_rate,
        v_daily_rate,
        v_daily_rate,
        'equal',
        NOW(),
        NOW()
    )
    ON CONFLICT (group_id, week_start_date) 
    DO UPDATE SET
        weekly_rate = EXCLUDED.weekly_rate,
        monday_rate = EXCLUDED.monday_rate,
        tuesday_rate = EXCLUDED.tuesday_rate,
        wednesday_rate = EXCLUDED.wednesday_rate,
        thursday_rate = EXCLUDED.thursday_rate,
        friday_rate = EXCLUDED.friday_rate,
        distribution_method = EXCLUDED.distribution_method,
        updated_at = NOW();
    
    RETURN QUERY SELECT TRUE, format('グループ "%s" の週利 %.1f%% を設定しました', p_group_name, p_weekly_rate);
END;
$$ LANGUAGE plpgsql;

-- 3. 権限設定
GRANT EXECUTE ON FUNCTION set_group_weekly_rate(DATE, VARCHAR(50), NUMERIC) TO authenticated;

-- 4. 関数テスト
SELECT 'Testing set_group_weekly_rate function...' as status;

-- テスト実行（実際には設定しない）
SELECT * FROM set_group_weekly_rate('2025-02-17'::DATE, '0.5%グループ', 1.5);

SELECT 'set_group_weekly_rate function created successfully!' as status;
