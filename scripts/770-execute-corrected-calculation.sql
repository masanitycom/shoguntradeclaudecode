-- 修正後の日利計算を実行

-- 1. 既存の計算結果をクリア
DELETE FROM daily_rewards WHERE reward_date = '2025-02-10';

-- 2. 日利計算関数を再作成（変数名の曖昧性を修正）
CREATE OR REPLACE FUNCTION calculate_daily_rewards_fixed(target_date DATE)
RETURNS TABLE(
    message TEXT,
    processed_count INTEGER,
    total_amount NUMERIC,
    success BOOLEAN
) AS $$
DECLARE
    day_of_week INTEGER;
    calc_week_start_date DATE;  -- 変数名を変更して曖昧性を回避
    processed_count INTEGER := 0;
    total_amount NUMERIC := 0;
    reward_record RECORD;
BEGIN
    -- 曜日を取得（1=月曜日、7=日曜日）
    day_of_week := EXTRACT(DOW FROM target_date);
    IF day_of_week = 0 THEN day_of_week := 7; END IF;
    
    -- 土日はスキップ
    IF day_of_week IN (6, 7) THEN
        RETURN QUERY SELECT 
            '土日のため計算をスキップしました'::TEXT,
            0::INTEGER,
            0::NUMERIC,
            true::BOOLEAN;
        RETURN;
    END IF;
    
    -- 週の開始日（月曜日）を計算
    calc_week_start_date := target_date - (day_of_week - 1);
    
    -- 日利計算と挿入
    FOR reward_record IN
        WITH daily_rates AS (
            SELECT 
                gwr.group_name,
                CASE day_of_week
                    WHEN 1 THEN gwr.monday_rate
                    WHEN 2 THEN gwr.tuesday_rate
                    WHEN 3 THEN gwr.wednesday_rate
                    WHEN 4 THEN gwr.thursday_rate
                    WHEN 5 THEN gwr.friday_rate
                    ELSE 0
                END as daily_rate
            FROM group_weekly_rates gwr
            WHERE gwr.week_start_date = calc_week_start_date  -- 修正された変数名を使用
        ),
        eligible_nfts AS (
            SELECT 
                un.id as user_nft_id,
                un.user_id,
                un.purchase_price,
                n.daily_rate_limit,
                drg.group_name
            FROM user_nfts un
            JOIN nfts n ON un.nft_id = n.id
            JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
            WHERE un.is_active = true
            AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= target_date
        )
        SELECT 
            en.user_nft_id,
            en.user_id,
            LEAST(en.purchase_price * dr.daily_rate, en.daily_rate_limit) as reward_amount,
            dr.daily_rate
        FROM eligible_nfts en
        JOIN daily_rates dr ON en.group_name = dr.group_name
        WHERE dr.daily_rate > 0
    LOOP
        -- daily_rewards テーブルに挿入
        INSERT INTO daily_rewards (
            user_nft_id,
            user_id,
            reward_amount,
            reward_date,
            daily_rate,
            created_at,
            updated_at
        ) VALUES (
            reward_record.user_nft_id,
            reward_record.user_id,
            reward_record.reward_amount,
            target_date,
            reward_record.daily_rate,
            NOW(),
            NOW()
        );
        
        processed_count := processed_count + 1;
        total_amount := total_amount + reward_record.reward_amount;
    END LOOP;
    
    RETURN QUERY SELECT 
        format('日利計算完了: %s件処理、合計%s円', processed_count, total_amount)::TEXT,
        processed_count::INTEGER,
        total_amount::NUMERIC,
        true::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

-- 3. 修正後の日利計算を実行
SELECT 
    '=== 修正後日利計算実行 ===' as section,
    *
FROM calculate_daily_rewards_fixed('2025-02-10'::date);

-- 4. 計算結果の詳細確認
SELECT 
    '=== 計算結果詳細 ===' as section,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward,
    COUNT(DISTINCT user_id) as unique_users
FROM daily_rewards
WHERE reward_date = '2025-02-10';

-- 5. グループ別の計算結果
SELECT 
    '=== グループ別結果 ===' as section,
    drg.group_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.reward_amount) as avg_reward,
    (dr.daily_rate * 100)::numeric(5,3) as daily_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE dr.reward_date = '2025-02-10'
GROUP BY drg.group_name, dr.daily_rate
ORDER BY total_rewards DESC;

-- 6. ユーザー統計の更新
UPDATE users 
SET 
    total_earned = COALESCE((
        SELECT SUM(reward_amount) 
        FROM daily_rewards 
        WHERE user_id = users.id
    ), 0),
    updated_at = NOW()
WHERE id IN (
    SELECT DISTINCT user_id 
    FROM daily_rewards 
    WHERE reward_date = '2025-02-10'
);

SELECT '✅ 修正後日利計算完了' as status;
