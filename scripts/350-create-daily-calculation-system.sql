-- 日利計算システムの完全実装

-- 1. 必要な関数を完全削除（既存の場合）
DROP FUNCTION IF EXISTS get_nft_group(NUMERIC);
DROP FUNCTION IF EXISTS is_weekday(DATE);
DROP FUNCTION IF EXISTS check_300_percent_cap(UUID, NUMERIC);
DROP FUNCTION IF EXISTS calculate_daily_rewards(DATE);
DROP FUNCTION IF EXISTS distribute_weekly_rate(NUMERIC, DATE);
DROP FUNCTION IF EXISTS record_daily_rewards(DATE);

-- 2. NFTグループ判定関数
CREATE OR REPLACE FUNCTION get_nft_group(nft_price NUMERIC)
RETURNS VARCHAR(20) AS $$
BEGIN
    CASE 
        WHEN nft_price <= 125 THEN RETURN 'group_125';
        WHEN nft_price <= 250 THEN RETURN 'group_250';
        WHEN nft_price <= 375 THEN RETURN 'group_375';
        WHEN nft_price <= 625 THEN RETURN 'group_625';
        WHEN nft_price <= 1250 THEN RETURN 'group_1250';
        WHEN nft_price <= 2500 THEN RETURN 'group_2500';
        WHEN nft_price <= 7500 THEN RETURN 'group_7500';
        ELSE RETURN 'group_high';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 3. 平日判定関数
CREATE OR REPLACE FUNCTION is_weekday(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXTRACT(DOW FROM check_date) BETWEEN 1 AND 5;
END;
$$ LANGUAGE plpgsql;

-- 4. 300%キャップチェック関数
CREATE OR REPLACE FUNCTION check_300_percent_cap(user_nft_id UUID, new_reward NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE
    current_earned NUMERIC;
    max_earning NUMERIC;
BEGIN
    SELECT total_earned, max_earning 
    INTO current_earned, max_earning
    FROM user_nfts 
    WHERE id = user_nft_id;
    
    IF current_earned IS NULL THEN
        current_earned := 0;
    END IF;
    
    RETURN (current_earned + new_reward) <= max_earning;
END;
$$ LANGUAGE plpgsql;

-- 5. 週利配分関数
CREATE OR REPLACE FUNCTION distribute_weekly_rate(weekly_rate NUMERIC, target_date DATE)
RETURNS TABLE(
    day_of_week INTEGER,
    daily_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 1 as day_of_week, (weekly_rate * 0.2)::NUMERIC as daily_rate
    UNION ALL
    SELECT 2, (weekly_rate * 0.2)::NUMERIC
    UNION ALL
    SELECT 3, (weekly_rate * 0.2)::NUMERIC
    UNION ALL
    SELECT 4, (weekly_rate * 0.2)::NUMERIC
    UNION ALL
    SELECT 5, (weekly_rate * 0.2)::NUMERIC;
END;
$$ LANGUAGE plpgsql;

-- 6. 日利計算メイン関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards(target_date DATE)
RETURNS TABLE(
    user_id UUID,
    user_nft_id UUID,
    nft_id UUID,
    nft_name VARCHAR(255),
    investment_amount NUMERIC,
    daily_rate NUMERIC,
    reward_amount NUMERIC,
    calculation_status VARCHAR(50),
    error_message VARCHAR(255)
) AS $$
DECLARE
    user_nft_record RECORD;
    nft_group VARCHAR(20);
    week_start DATE;
    group_weekly_rate NUMERIC;
    day_of_week INTEGER;
    calculated_daily_rate NUMERIC;
    calculated_reward NUMERIC;
    can_earn BOOLEAN;
BEGIN
    -- 平日チェック
    IF NOT is_weekday(target_date) THEN
        RETURN;
    END IF;
    
    -- 週の開始日を計算
    week_start := DATE_TRUNC('week', target_date)::DATE;
    day_of_week := EXTRACT(DOW FROM target_date);
    
    -- 各ユーザーNFTに対して処理
    FOR user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            n.name as nft_name,
            un.current_investment,
            n.price as nft_price,
            n.daily_rate_limit
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        WHERE un.is_active = true
        AND un.operation_start_date IS NOT NULL
        AND un.operation_start_date <= target_date
    LOOP
        BEGIN
            -- NFTグループを判定
            nft_group := get_nft_group(user_nft_record.nft_price);
            
            -- 週利を取得
            SELECT gwr.weekly_rate INTO group_weekly_rate
            FROM group_weekly_rates gwr
            WHERE gwr.nft_group = nft_group
            AND gwr.week_start_date = week_start;
            
            IF group_weekly_rate IS NULL THEN
                group_weekly_rate := 0.026; -- デフォルト2.6%
            END IF;
            
            -- 日利を計算（週利を5日で均等配分）
            calculated_daily_rate := group_weekly_rate / 5.0;
            
            -- 日利上限チェック
            IF calculated_daily_rate > user_nft_record.daily_rate_limit THEN
                calculated_daily_rate := user_nft_record.daily_rate_limit;
            END IF;
            
            -- 報酬額を計算
            calculated_reward := user_nft_record.current_investment * calculated_daily_rate;
            
            -- 300%キャップチェック
            can_earn := check_300_percent_cap(user_nft_record.user_nft_id, calculated_reward);
            
            IF NOT can_earn THEN
                -- 300%に達している場合、NFTを非アクティブ化
                UPDATE user_nfts 
                SET is_active = false, 
                    completion_date = target_date
                WHERE id = user_nft_record.user_nft_id;
                
                calculated_reward := 0;
                calculated_daily_rate := 0;
            END IF;
            
            -- 結果を返す
            user_id := user_nft_record.user_id;
            user_nft_id := user_nft_record.user_nft_id;
            nft_id := user_nft_record.nft_id;
            nft_name := user_nft_record.nft_name;
            investment_amount := user_nft_record.current_investment;
            daily_rate := calculated_daily_rate;
            reward_amount := calculated_reward;
            calculation_status := CASE 
                WHEN NOT can_earn THEN 'completed'
                WHEN calculated_reward > 0 THEN 'success'
                ELSE 'no_reward'
            END;
            error_message := '';
            
            RETURN NEXT;
            
        EXCEPTION WHEN OTHERS THEN
            -- エラーが発生した場合
            user_id := user_nft_record.user_id;
            user_nft_id := user_nft_record.user_nft_id;
            nft_id := user_nft_record.nft_id;
            nft_name := user_nft_record.nft_name;
            investment_amount := user_nft_record.current_investment;
            daily_rate := 0;
            reward_amount := 0;
            calculation_status := 'error';
            error_message := SQLERRM;
            
            RETURN NEXT;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 7. 日利報酬記録関数
CREATE OR REPLACE FUNCTION record_daily_rewards(target_date DATE)
RETURNS INTEGER AS $$
DECLARE
    reward_record RECORD;
    inserted_count INTEGER := 0;
BEGIN
    -- 既存の報酬記録を削除（重複防止）
    DELETE FROM daily_rewards WHERE reward_date = target_date;
    
    -- 日利計算結果を取得して記録
    FOR reward_record IN
        SELECT * FROM calculate_daily_rewards(target_date)
        WHERE reward_amount > 0
    LOOP
        INSERT INTO daily_rewards (
            user_nft_id,
            user_id,
            nft_id,
            reward_date,
            daily_rate,
            reward_amount,
            week_start_date,
            investment_amount,
            calculation_date,
            calculation_details,
            is_claimed
        ) VALUES (
            reward_record.user_nft_id,
            reward_record.user_id,
            reward_record.nft_id,
            target_date,
            reward_record.daily_rate,
            reward_record.reward_amount,
            DATE_TRUNC('week', target_date)::DATE,
            reward_record.investment_amount,
            CURRENT_DATE,
            jsonb_build_object(
                'calculation_status', reward_record.calculation_status,
                'nft_name', reward_record.nft_name,
                'calculated_at', NOW()
            ),
            false
        );
        
        -- user_nftsのtotal_earnedを更新
        UPDATE user_nfts 
        SET total_earned = COALESCE(total_earned, 0) + reward_record.reward_amount
        WHERE id = reward_record.user_nft_id;
        
        inserted_count := inserted_count + 1;
    END LOOP;
    
    RETURN inserted_count;
END;
$$ LANGUAGE plpgsql;

-- 8. テスト実行
SELECT 
    '🧪 日利計算テスト実行' as status,
    user_id,
    nft_name,
    investment_amount,
    daily_rate,
    reward_amount,
    calculation_status
FROM calculate_daily_rewards(CURRENT_DATE)
LIMIT 10;

-- 9. 関数作成完了確認
SELECT 
    '✅ 関数作成完了確認' as status,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_nft_group',
    'is_weekday',
    'check_300_percent_cap',
    'calculate_daily_rewards',
    'distribute_weekly_rate',
    'record_daily_rewards'
)
ORDER BY routine_name;

-- 10. 日利報酬記録テスト
SELECT 
    '🧪 日利報酬記録テスト' as status,
    record_daily_rewards(CURRENT_DATE) as inserted_records;

-- 11. 記録された報酬確認
SELECT 
    '📊 記録された報酬確認' as status,
    COUNT(*) as total_records,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_amount,
    MAX(reward_date) as latest_date
FROM daily_rewards
WHERE reward_date = CURRENT_DATE;
