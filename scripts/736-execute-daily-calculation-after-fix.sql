-- 🚀 修復後の日利計算実行

-- 1. 今日の日利計算を実行
SELECT 
    '=== 日利計算実行 ===' as section,
    success,
    message,
    processed_count,
    total_amount
FROM execute_daily_calculation(CURRENT_DATE);

-- 2. 過去の日利も計算（2025-02-10から今日まで）
DO $$
DECLARE
    calc_date DATE;
    day_of_week INTEGER;
    result_record RECORD;
BEGIN
    -- 2025-02-10から今日まで平日のみ計算
    FOR calc_date IN 
        SELECT generate_series('2025-02-10'::DATE, CURRENT_DATE, '1 day'::INTERVAL)::DATE
    LOOP
        day_of_week := EXTRACT(DOW FROM calc_date);
        
        -- 平日のみ（月曜=1, 火曜=2, ..., 金曜=5）
        IF day_of_week BETWEEN 1 AND 5 THEN
            -- 既存の計算をチェック
            IF NOT EXISTS (SELECT 1 FROM daily_rewards WHERE reward_date = calc_date) THEN
                SELECT * INTO result_record FROM execute_daily_calculation(calc_date);
                RAISE NOTICE '% の日利計算: %', calc_date, result_record.message;
            END IF;
        END IF;
    END LOOP;
END $$;

-- 3. 計算結果の確認
SELECT 
    '=== 計算結果サマリー ===' as section,
    COUNT(DISTINCT reward_date) as calculated_days,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_reward_amount,
    MIN(reward_date) as first_reward_date,
    MAX(reward_date) as last_reward_date
FROM daily_rewards;

-- 4. ユーザー別の報酬状況
SELECT 
    '=== ユーザー別報酬状況 ===' as section,
    u.name as user_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    SUM(un.total_earned) as total_earned_updated
FROM users u
JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN daily_rewards dr ON dr.user_nft_id = un.id
WHERE u.is_admin = false
GROUP BY u.id, u.name
HAVING SUM(dr.reward_amount) > 0
ORDER BY total_rewards DESC
LIMIT 10;

SELECT '🚀 修復後日利計算完了' as status;
