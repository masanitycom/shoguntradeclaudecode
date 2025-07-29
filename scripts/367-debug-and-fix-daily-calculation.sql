-- =====================================================================
-- 日利計算が0件処理になる問題をデバッグ・修正
-- =====================================================================

-- 1. 現在のデータ状況を確認
SELECT 
    '🔍 アクティブなuser_nfts確認' as status,
    COUNT(*) as total_user_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_user_nfts,
    COUNT(CASE WHEN current_investment > 0 THEN 1 END) as with_investment,
    COUNT(CASE WHEN is_active = true AND current_investment > 0 THEN 1 END) as active_with_investment
FROM user_nfts;

-- 2. NFTsテーブルの状況確認
SELECT 
    '🎯 NFTsテーブル確認' as status,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
    MIN(price) as min_price,
    MAX(price) as max_price,
    AVG(daily_rate_limit) as avg_daily_rate_limit
FROM nfts;

-- 3. 今日が平日かどうか確認
SELECT 
    '📅 今日の曜日確認' as status,
    CURRENT_DATE as today,
    EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '平日'
        ELSE '休日'
    END as day_type;

-- 4. group_weekly_ratesの状況確認
SELECT 
    '📊 週利設定確認' as status,
    COUNT(*) as total_weekly_rates,
    COUNT(CASE WHEN week_start_date <= CURRENT_DATE AND week_start_date + 6 >= CURRENT_DATE THEN 1 END) as current_week_rates
FROM group_weekly_rates;

-- 5. 詳細なuser_nfts情報を確認
SELECT 
    '👥 詳細user_nfts情報' as status,
    un.id,
    un.user_id,
    un.nft_id,
    un.current_investment,
    un.is_active,
    un.operation_start_date,
    n.name as nft_name,
    n.price as nft_price,
    n.daily_rate_limit,
    n.is_active as nft_is_active
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.current_investment DESC
LIMIT 10;

-- 6. 修正された日利計算関数を作成
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch(date);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch(
    p_calculation_date date DEFAULT CURRENT_DATE
) RETURNS TABLE(
    calculation_date date,
    processed_count integer,
    total_rewards numeric,
    completed_nfts integer,
    error_message text
) LANGUAGE plpgsql AS $$
DECLARE
    v_processed_count int := 0;
    v_total_amount numeric := 0;
    v_completed_nfts int := 0;
    v_error_msg text := null;
    v_user_nft_record RECORD;
    v_week_start date;
    v_day_of_week int;
    v_daily_rate numeric;
    v_reward_amount numeric;
    v_group_id uuid;
BEGIN
    -- デバッグ情報をログに出力
    RAISE NOTICE '🚀 日利計算開始: %', p_calculation_date;
    
    -- 平日チェック
    v_day_of_week := EXTRACT(DOW FROM p_calculation_date);
    IF v_day_of_week IN (0, 6) THEN
        RAISE NOTICE '⏰ 土日のため処理をスキップ';
        RETURN QUERY SELECT 
            p_calculation_date,
            0,
            0::numeric,
            0,
            '土日は日利計算を行いません'::text;
        RETURN;
    END IF;
    
    -- 週の開始日を計算
    v_week_start := DATE_TRUNC('week', p_calculation_date)::date;
    RAISE NOTICE '📅 週開始日: %, 曜日: %', v_week_start, v_day_of_week;
    
    -- アクティブなuser_nftsを処理
    FOR v_user_nft_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.current_investment,
            un.total_earned,
            un.max_earning,
            n.name as nft_name,
            n.price as nft_price,
            n.daily_rate_limit,
            drg.id as group_id
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
        WHERE un.is_active = true
        AND un.current_investment > 0
        AND n.is_active = true
        AND (un.total_earned < un.max_earning OR un.max_earning IS NULL)
    LOOP
        BEGIN
            v_processed_count := v_processed_count + 1;
            v_group_id := v_user_nft_record.group_id;
            
            RAISE NOTICE '🎯 処理中: NFT=%, 投資額=%, グループ=%', 
                v_user_nft_record.nft_name, 
                v_user_nft_record.current_investment,
                v_group_id;
            
            -- 該当週・グループの日利を取得
            SELECT 
                CASE v_day_of_week
                    WHEN 1 THEN monday_rate
                    WHEN 2 THEN tuesday_rate
                    WHEN 3 THEN wednesday_rate
                    WHEN 4 THEN thursday_rate
                    WHEN 5 THEN friday_rate
                    ELSE 0
                END
            INTO v_daily_rate
            FROM group_weekly_rates
            WHERE week_start_date = v_week_start
            AND group_id = v_group_id;
            
            -- 日利が見つからない場合はデフォルト値
            IF v_daily_rate IS NULL THEN
                v_daily_rate := 0.005; -- 0.5%
                RAISE NOTICE '⚠️ 日利が見つからないためデフォルト値使用: %', v_daily_rate;
            END IF;
            
            -- 日利上限チェック
            IF v_daily_rate > v_user_nft_record.daily_rate_limit THEN
                v_daily_rate := v_user_nft_record.daily_rate_limit;
            END IF;
            
            -- 報酬額を計算
            v_reward_amount := v_user_nft_record.current_investment * v_daily_rate;
            
            -- 300%キャップチェック
            IF (COALESCE(v_user_nft_record.total_earned, 0) + v_reward_amount) > v_user_nft_record.max_earning THEN
                -- 残り分のみ支給
                v_reward_amount := v_user_nft_record.max_earning - COALESCE(v_user_nft_record.total_earned, 0);
                IF v_reward_amount <= 0 THEN
                    v_reward_amount := 0;
                    -- NFTを非アクティブ化
                    UPDATE user_nfts 
                    SET is_active = false, completion_date = p_calculation_date
                    WHERE id = v_user_nft_record.user_nft_id;
                    v_completed_nfts := v_completed_nfts + 1;
                END IF;
            END IF;
            
            -- 報酬が0より大きい場合のみ記録
            IF v_reward_amount > 0 THEN
                -- daily_rewardsに記録
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
                    v_user_nft_record.user_nft_id,
                    v_user_nft_record.user_id,
                    v_user_nft_record.nft_id,
                    p_calculation_date,
                    v_daily_rate,
                    v_reward_amount,
                    v_week_start,
                    v_user_nft_record.current_investment,
                    CURRENT_DATE,
                    jsonb_build_object(
                        'nft_name', v_user_nft_record.nft_name,
                        'nft_price', v_user_nft_record.nft_price,
                        'group_id', v_group_id,
                        'day_of_week', v_day_of_week
                    ),
                    false
                )
                ON CONFLICT (user_nft_id, reward_date)
                DO UPDATE SET
                    daily_rate = EXCLUDED.daily_rate,
                    reward_amount = EXCLUDED.reward_amount,
                    investment_amount = EXCLUDED.investment_amount,
                    calculation_date = EXCLUDED.calculation_date,
                    calculation_details = EXCLUDED.calculation_details,
                    updated_at = NOW();
                
                -- user_nftsのtotal_earnedを更新
                UPDATE user_nfts 
                SET total_earned = COALESCE(total_earned, 0) + v_reward_amount
                WHERE id = v_user_nft_record.user_nft_id;
                
                v_total_amount := v_total_amount + v_reward_amount;
                
                RAISE NOTICE '💰 報酬記録: 金額=%, 累計=%', v_reward_amount, v_total_amount;
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
            v_error_msg := COALESCE(v_error_msg, '') || SQLERRM || '; ';
            RAISE NOTICE '❌ エラー: %', SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ 日利計算完了: 処理=%件, 総額=$%, 完了=%個', 
        v_processed_count, v_total_amount, v_completed_nfts;
    
    RETURN QUERY SELECT 
        p_calculation_date,
        v_processed_count,
        v_total_amount,
        v_completed_nfts,
        v_error_msg;
END;
$$;

-- 7. テスト用の週利データを作成（今週分）
DO $$
DECLARE
    v_week_start date := DATE_TRUNC('week', CURRENT_DATE)::date;
    v_group_record RECORD;
BEGIN
    -- 各グループに対して今週の週利を設定
    FOR v_group_record IN
        SELECT id, group_name, daily_rate_limit FROM daily_rate_groups
    LOOP
        -- 既存データを削除
        DELETE FROM group_weekly_rates 
        WHERE week_start_date = v_week_start AND group_id = v_group_record.id;
        
        -- 新しいデータを挿入
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
            distribution_method
        ) VALUES (
            v_group_record.id,
            v_week_start,
            v_week_start + 4,
            EXTRACT(week FROM v_week_start),
            0.026, -- 2.6%
            0.0052, -- 月曜 0.52%
            0.0052, -- 火曜 0.52%
            0.0052, -- 水曜 0.52%
            0.0052, -- 木曜 0.52%
            0.0052, -- 金曜 0.52%
            'auto'
        );
        
        RAISE NOTICE '📊 週利設定完了: % (ID: %)', v_group_record.group_name, v_group_record.id;
    END LOOP;
END $$;

-- 8. テスト用のuser_nftsデータを確認・作成
DO $$
DECLARE
    v_user_count int;
    v_test_user_id uuid;
    v_test_nft_id uuid;
BEGIN
    -- アクティブなuser_nftsの数を確認
    SELECT COUNT(*) INTO v_user_count
    FROM user_nfts 
    WHERE is_active = true AND current_investment > 0;
    
    IF v_user_count = 0 THEN
        RAISE NOTICE '⚠️ アクティブなuser_nftsが見つかりません。テストデータを作成します。';
        
        -- テスト用ユーザーを取得
        SELECT id INTO v_test_user_id FROM users WHERE email LIKE '%ohtakiyo%' LIMIT 1;
        
        -- テスト用NFTを取得
        SELECT id INTO v_test_nft_id FROM nfts WHERE is_active = true LIMIT 1;
        
        IF v_test_user_id IS NOT NULL AND v_test_nft_id IS NOT NULL THEN
            -- テスト用user_nftを作成
            INSERT INTO user_nfts (
                user_id,
                nft_id,
                current_investment,
                max_earning,
                total_earned,
                is_active,
                operation_start_date
            ) VALUES (
                v_test_user_id,
                v_test_nft_id,
                1000, -- $1000投資
                3000, -- $3000上限
                0,    -- まだ報酬なし
                true,
                CURRENT_DATE - 1 -- 昨日から開始
            )
            ON CONFLICT (user_id, nft_id) DO UPDATE SET
                current_investment = 1000,
                max_earning = 3000,
                is_active = true,
                operation_start_date = CURRENT_DATE - 1;
                
            RAISE NOTICE '✅ テスト用user_nftを作成しました';
        END IF;
    ELSE
        RAISE NOTICE '✅ アクティブなuser_nfts: %件', v_user_count;
    END IF;
END $$;

-- 9. 日利計算をテスト実行
SELECT 
    '🧪 日利計算テスト実行' as status,
    *
FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 10. 結果確認
SELECT 
    '📈 計算結果確認' as status,
    COUNT(*) as total_records,
    SUM(reward_amount) as total_rewards,
    AVG(reward_amount) as avg_reward,
    COUNT(DISTINCT user_nft_id) as unique_nfts
FROM daily_rewards
WHERE reward_date = CURRENT_DATE;
