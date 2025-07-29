-- 🚨 NFTグループ分類と計算システムの緊急修正

-- 1. 現在のNFTとグループの状況を確認
SELECT 
    '🔍 現在のNFT状況確認' as info,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.is_active,
    COUNT(un.id) as user_count
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
WHERE n.is_active = true
GROUP BY n.id, n.name, n.price, n.daily_rate_limit, n.is_active
ORDER BY n.price;

-- 2. 日利上限グループの正しいNFT数を確認
SELECT 
    '📊 グループ別NFT数（正しい計算）' as info,
    drg.group_name,
    drg.daily_rate_limit,
    COUNT(n.id) as actual_nft_count,
    STRING_AGG(n.name, ', ') as nft_names
FROM daily_rate_groups drg
LEFT JOIN nfts n ON (n.daily_rate_limit * 100) = (drg.daily_rate_limit * 100)
    AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 3. 🎯 NFTの日利上限を正しく設定（CSVデータに基づく）
UPDATE nfts SET daily_rate_limit = 0.005 WHERE price <= 125;     -- 0.5%グループ
UPDATE nfts SET daily_rate_limit = 0.010 WHERE price > 125 AND price <= 250;   -- 1.0%グループ  
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE price > 250 AND price <= 375;  -- 1.25%グループ
UPDATE nfts SET daily_rate_limit = 0.015 WHERE price > 375 AND price <= 625;   -- 1.5%グループ
UPDATE nfts SET daily_rate_limit = 0.0175 WHERE price > 625 AND price <= 1250; -- 1.75%グループ
UPDATE nfts SET daily_rate_limit = 0.020 WHERE price > 1250;    -- 2.0%グループ

-- 4. 修正後のNFTグループ分類を確認
SELECT 
    '✅ 修正後のグループ分類' as info,
    CASE 
        WHEN n.daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN n.daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN n.daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN n.daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN n.daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN n.daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE 'その他'
    END as group_name,
    COUNT(*) as nft_count,
    STRING_AGG(n.name, ', ') as nft_names
FROM nfts n
WHERE n.is_active = true
GROUP BY n.daily_rate_limit
ORDER BY n.daily_rate_limit;

-- 5. 🎯 今週の週利設定を確認・修正
DO $$
DECLARE
    current_monday DATE;
    group_record RECORD;
BEGIN
    -- 今週の月曜日を取得
    current_monday := DATE_TRUNC('week', CURRENT_DATE)::DATE;
    
    RAISE NOTICE '今週の月曜日: %', current_monday;
    
    -- 今週の設定があるかチェック
    IF NOT EXISTS (
        SELECT 1 FROM group_weekly_rates 
        WHERE week_start_date = current_monday
    ) THEN
        RAISE NOTICE '今週の週利設定がありません。デフォルト設定を作成します。';
        
        -- 各グループにデフォルト週利を設定
        FOR group_record IN 
            SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit
        LOOP
            PERFORM create_synchronized_weekly_distribution(
                current_monday,
                group_record.id,
                0.026  -- 2.6%のデフォルト週利
            );
            
            RAISE NOTICE 'グループにデフォルト週利を設定: %', group_record.group_name;
        END LOOP;
    ELSE
        RAISE NOTICE '今週の週利設定は既に存在します。';
    END IF;
END $$;

-- 6. 🔧 計算システムの修正（NFTグループ関数を更新）
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

-- 7. 🎯 日利計算システムを修正（正しいグループマッピング）
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
    nft_group_name TEXT;
    debug_msg TEXT;
BEGIN
    -- 平日チェック
    dow_value := EXTRACT(DOW FROM target_date);
    IF dow_value NOT BETWEEN 1 AND 5 THEN
        RETURN QUERY SELECT 0, 0::NUMERIC, '土日は計算を行いません'::TEXT;
        RETURN;
    END IF;
    
    -- 週の開始日を取得
    week_start := DATE_TRUNC('week', target_date)::DATE;
    
    debug_msg := '日利計算開始: 対象日=' || target_date || ', 週開始=' || week_start || ', 曜日=' || dow_value;
    RAISE NOTICE '%', debug_msg;
    
    -- アクティブなuser_nftsを処理
    FOR user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.current_investment,
            n.price as nft_price,
            n.daily_rate_limit,
            n.name as nft_name
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
        -- NFTの日利上限に基づいてグループを決定
        nft_group_name := CASE 
            WHEN user_nft_record.daily_rate_limit = 0.005 THEN 'group_100'
            WHEN user_nft_record.daily_rate_limit = 0.010 THEN 'group_250'
            WHEN user_nft_record.daily_rate_limit = 0.0125 THEN 'group_375'
            WHEN user_nft_record.daily_rate_limit = 0.015 THEN 'group_625'
            WHEN user_nft_record.daily_rate_limit = 0.0175 THEN 'group_1250'
            WHEN user_nft_record.daily_rate_limit = 0.020 THEN 'group_2500'
            ELSE 'group_high'
        END;
        
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
        AND drg.group_name = nft_group_name;
        
        -- 設定が見つからない場合はスキップ
        IF daily_rate_value IS NULL THEN
            debug_msg := 'グループの週利設定が見つかりません: ' || nft_group_name;
            RAISE NOTICE '%', debug_msg;
            CONTINUE;
        END IF;
        
        -- 日利上限チェック
        IF daily_rate_value > user_nft_record.daily_rate_limit THEN
            daily_rate_value := user_nft_record.daily_rate_limit;
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
        
        debug_msg := 'NFT: ' || user_nft_record.nft_name || ', グループ: ' || nft_group_name || ', 報酬: $' || calculated_reward;
        RAISE NOTICE '%', debug_msg;
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
    
    debug_msg := '日利計算完了: 処理件数=' || total_processed || ', 総報酬=$' || total_reward_amount;
    RAISE NOTICE '%', debug_msg;
    
    RETURN QUERY SELECT total_processed, total_reward_amount, ''::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 8. バッチ処理関数も更新
CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch(
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    calculation_date DATE,
    processed_count INTEGER,
    total_rewards NUMERIC,
    completed_nfts INTEGER,
    error_message TEXT
) AS $$
DECLARE
    result_record RECORD;
BEGIN
    SELECT * INTO result_record FROM calculate_daily_rewards_correct(p_calculation_date);
    
    RETURN QUERY SELECT 
        p_calculation_date,
        result_record.processed_count,
        result_record.total_rewards,
        0, -- completed_nfts は別途計算が必要
        result_record.error_message;
END;
$$ LANGUAGE plpgsql;

-- 9. 🧪 修正後のテスト実行
SELECT 
    '🧪 修正後のシステムテスト' as info,
    * 
FROM calculate_daily_rewards_correct(CURRENT_DATE);

-- 10. 最終確認
SELECT 
    '✅ 修正完了確認' as info,
    '今週の週利設定数: ' || COUNT(DISTINCT gwr.week_start_date) as 週利設定,
    'アクティブNFT数: ' || COUNT(DISTINCT n.id) as NFT数,
    'アクティブ投資数: ' || COUNT(DISTINCT un.id) as 投資数
FROM group_weekly_rates gwr
CROSS JOIN nfts n
CROSS JOIN user_nfts un
WHERE n.is_active = true 
AND un.is_active = true 
AND un.current_investment > 0
AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE;
