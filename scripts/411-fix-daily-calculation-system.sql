-- 🔧 日利計算システムの根本的修正

-- 1. 既存の壊れた計算関数を完全に削除
DROP FUNCTION IF EXISTS calculate_daily_rewards(date);
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch();
DROP FUNCTION IF EXISTS get_nft_group(numeric);

-- 2. 正しいNFTグループ分類関数を作成
CREATE OR REPLACE FUNCTION get_nft_group_by_price(nft_price NUMERIC)
RETURNS TEXT AS $$
BEGIN
    CASE 
        WHEN nft_price <= 125 THEN RETURN 'group_100';
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

-- 3. 管理画面設定値を使用する正しい日利計算関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards_correct(
    target_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    processed_count INTEGER,
    total_rewards NUMERIC,
    error_message TEXT
) AS $$
DECLARE
    user_nft_record RECORD;
    week_start DATE;
    dow_value INTEGER;
    daily_rate_value NUMERIC := 0;
    calculated_reward NUMERIC := 0;
    total_processed INTEGER := 0;
    total_reward_amount NUMERIC := 0;
    nft_group TEXT;
BEGIN
    -- 平日チェック
    dow_value := EXTRACT(DOW FROM target_date);
    IF dow_value NOT BETWEEN 1 AND 5 THEN
        RETURN QUERY SELECT 0, 0::NUMERIC, '土日は計算を行いません'::TEXT;
        RETURN;
    END IF;
    
    -- 週の開始日を取得
    week_start := DATE_TRUNC('week', target_date)::DATE;
    
    -- アクティブなuser_nftsを処理
    FOR user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.current_investment,
            n.price as nft_price,
            n.daily_rate_limit
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        WHERE un.is_active = true
        AND un.current_investment > 0
        AND un.operation_start_date <= target_date
        AND NOT EXISTS (
            SELECT 1 FROM daily_rewards dr 
            WHERE dr.user_nft_id = un.id 
            AND dr.reward_date = target_date
        )
    LOOP
        -- NFTグループを取得
        nft_group := get_nft_group_by_price(user_nft_record.nft_price);
        
        -- 管理画面設定値から日利を取得
        SELECT 
            CASE dow_value
                WHEN 1 THEN monday_rate
                WHEN 2 THEN tuesday_rate
                WHEN 3 THEN wednesday_rate
                WHEN 4 THEN thursday_rate
                WHEN 5 THEN friday_rate
                ELSE 0
            END
        INTO daily_rate_value
        FROM group_weekly_rates gwr
        JOIN daily_rate_groups drg ON gwr.group_id = drg.id
        WHERE gwr.week_start_date = week_start
        AND drg.group_name = nft_group;
        
        -- 設定が見つからない場合はスキップ
        IF daily_rate_value IS NULL THEN
            CONTINUE;
        END IF;
        
        -- 日利上限チェック
        IF daily_rate_value > (user_nft_record.daily_rate_limit / 100.0) THEN
            daily_rate_value := user_nft_record.daily_rate_limit / 100.0;
        END IF;
        
        -- 報酬額を計算
        calculated_reward := user_nft_record.current_investment * daily_rate_value;
        
        -- daily_rewardsに挿入
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
            is_claimed
        ) VALUES (
            user_nft_record.user_nft_id,
            user_nft_record.user_id,
            user_nft_record.nft_id,
            target_date,
            daily_rate_value,
            calculated_reward,
            week_start,
            user_nft_record.current_investment,
            CURRENT_DATE,
            false
        );
        
        total_processed := total_processed + 1;
        total_reward_amount := total_reward_amount + calculated_reward;
    END LOOP;
    
    -- user_nftsのtotal_earnedを更新
    UPDATE user_nfts 
    SET total_earned = COALESCE((
        SELECT SUM(dr.reward_amount)
        FROM daily_rewards dr 
        WHERE dr.user_nft_id = user_nfts.id
    ), 0),
    updated_at = NOW()
    WHERE is_active = true;
    
    RETURN QUERY SELECT total_processed, total_reward_amount, ''::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 4. バッチ処理用関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch()
RETURNS TABLE(
    calculation_date DATE,
    processed_count INTEGER,
    total_rewards NUMERIC,
    completed_nfts INTEGER,
    error_message TEXT
) AS $$
DECLARE
    result_record RECORD;
BEGIN
    SELECT * INTO result_record FROM calculate_daily_rewards_correct(CURRENT_DATE);
    
    RETURN QUERY SELECT 
        CURRENT_DATE,
        result_record.processed_count,
        result_record.total_rewards,
        0, -- completed_nfts は別途計算が必要
        result_record.error_message;
END;
$$ LANGUAGE plpgsql;

-- 5. テスト実行
SELECT 
    '🧪 修正されたシステムのテスト' as info,
    * 
FROM calculate_daily_rewards_correct(CURRENT_DATE);
