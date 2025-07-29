-- set_group_weekly_rate関数の作成

-- 1. 既存関数を削除
DROP FUNCTION IF EXISTS set_group_weekly_rate(DATE, TEXT, NUMERIC);
DROP FUNCTION IF EXISTS set_group_weekly_rate(DATE, VARCHAR, NUMERIC);

-- 2. set_group_weekly_rate関数を作成
CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_group_id UUID;
    v_week_end_date DATE;
    v_daily_rate NUMERIC;
    v_existing_count INTEGER;
BEGIN
    -- 入力検証
    IF EXTRACT(DOW FROM p_week_start_date) != 1 THEN
        RETURN QUERY SELECT FALSE, '開始日は月曜日である必要があります';
        RETURN;
    END IF;
    
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
    
    -- 週末日を計算（金曜日）
    v_week_end_date := p_week_start_date + INTERVAL '4 days';
    
    -- 日利を計算（週利を5日で等分）
    v_daily_rate := (p_weekly_rate / 100.0) / 5.0;
    
    -- 既存設定をチェック
    SELECT COUNT(*) INTO v_existing_count
    FROM group_weekly_rates
    WHERE group_id = v_group_id AND week_start_date = p_week_start_date;
    
    IF v_existing_count > 0 THEN
        -- 既存設定を更新
        UPDATE group_weekly_rates SET
            weekly_rate = p_weekly_rate / 100.0,
            monday_rate = v_daily_rate,
            tuesday_rate = v_daily_rate,
            wednesday_rate = v_daily_rate,
            thursday_rate = v_daily_rate,
            friday_rate = v_daily_rate,
            distribution_method = 'equal',
            updated_at = NOW()
        WHERE group_id = v_group_id AND week_start_date = p_week_start_date;
        
        RETURN QUERY SELECT TRUE, format('グループ "%s" の週利 %.1f%% を更新しました', p_group_name, p_weekly_rate);
    ELSE
        -- 新規設定を作成
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
        );
        
        RETURN QUERY SELECT TRUE, format('グループ "%s" の週利 %.1f%% を設定しました', p_group_name, p_weekly_rate);
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, '設定エラー: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 3. 権限設定
GRANT EXECUTE ON FUNCTION set_group_weekly_rate(DATE, TEXT, NUMERIC) TO authenticated;

-- 4. 関数テスト
SELECT '🧪 set_group_weekly_rate テスト' as test_name;

-- テスト用の設定（実際には2025-02-17で実行）
SELECT * FROM set_group_weekly_rate('2025-02-17'::DATE, '1.5%グループ', 2.6);

SELECT '✅ set_group_weekly_rate関数作成完了!' as status;
