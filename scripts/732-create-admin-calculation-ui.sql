-- 📊 管理画面用の日利計算管理関数

-- 1. 管理画面用の日利計算実行関数
CREATE OR REPLACE FUNCTION admin_execute_daily_calculation(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_count INTEGER,
    total_amount DECIMAL,
    details JSONB
) AS $$
DECLARE
    result_record RECORD;
    details_json JSONB;
BEGIN
    -- 日利計算を実行
    SELECT * INTO result_record FROM execute_daily_calculation(target_date);
    
    -- 詳細情報を取得
    SELECT jsonb_build_object(
        'calculation_date', target_date,
        'day_of_week', EXTRACT(DOW FROM target_date),
        'is_weekday', EXTRACT(DOW FROM target_date) NOT IN (0, 6),
        'weekly_rates_count', (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date <= target_date AND week_start_date + INTERVAL '6 days' >= target_date),
        'active_nfts_count', (SELECT COUNT(*) FROM user_nfts WHERE is_active = true),
        'existing_rewards_count', (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = target_date)
    ) INTO details_json;
    
    RETURN QUERY SELECT 
        result_record.success,
        result_record.message,
        result_record.processed_count,
        result_record.total_amount,
        details_json;
END;
$$ LANGUAGE plpgsql;

-- 2. 日利計算履歴確認関数
CREATE OR REPLACE FUNCTION get_daily_calculation_history(days_back INTEGER DEFAULT 7)
RETURNS TABLE(
    reward_date DATE,
    total_rewards DECIMAL,
    reward_count INTEGER,
    unique_users INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dr.reward_date,
        SUM(dr.reward_amount) as total_rewards,
        COUNT(dr.id) as reward_count,
        COUNT(DISTINCT un.user_id) as unique_users
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    WHERE dr.reward_date >= CURRENT_DATE - days_back
    GROUP BY dr.reward_date
    ORDER BY dr.reward_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 3. システム状態確認関数（修正版）
CREATE OR REPLACE FUNCTION get_system_calculation_status()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_rewards DECIMAL,
    last_calculation_date TEXT,
    current_week_rates INTEGER,
    system_status TEXT
) AS $$
DECLARE
    last_calc_date DATE;
    week_rates_count INTEGER;
    status_text TEXT;
BEGIN
    -- 最後の計算日を取得
    SELECT MAX(reward_date) INTO last_calc_date FROM daily_rewards;
    
    -- 現在週の週利設定数を取得
    SELECT COUNT(*) INTO week_rates_count
    FROM group_weekly_rates 
    WHERE week_start_date <= CURRENT_DATE 
    AND week_start_date + INTERVAL '6 days' >= CURRENT_DATE;
    
    -- システム状態を判定
    IF week_rates_count = 0 THEN
        status_text := '週利未設定';
    ELSIF last_calc_date IS NULL THEN
        status_text := '計算未実行';
    ELSIF last_calc_date < CURRENT_DATE AND EXTRACT(DOW FROM CURRENT_DATE) NOT IN (0, 6) THEN
        status_text := '計算要実行';
    ELSE
        status_text := '正常';
    END IF;
    
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users),
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true),
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE is_claimed = false),
        COALESCE(last_calc_date::TEXT, 'なし'),
        week_rates_count,
        status_text;
END;
$$ LANGUAGE plpgsql;

SELECT '📊 管理画面用日利計算関数作成完了' as status;
