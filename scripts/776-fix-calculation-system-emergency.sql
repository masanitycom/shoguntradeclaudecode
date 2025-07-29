-- 🚨 緊急計算システム修正

-- 1. まず現在の問題を特定
DO $$
DECLARE
    problem_count INTEGER := 0;
    fix_message TEXT := '';
BEGIN
    -- NFTとグループの対応チェック
    SELECT COUNT(*) INTO problem_count
    FROM nfts n
    WHERE n.daily_rate_group_id IS NULL;
    
    IF problem_count > 0 THEN
        fix_message := fix_message || format('NFTグループ未設定: %s件 ', problem_count);
    END IF;
    
    -- 週利設定チェック
    SELECT COUNT(*) INTO problem_count
    FROM daily_rate_groups drg
    WHERE NOT EXISTS (
        SELECT 1 FROM group_weekly_rates gwr 
        WHERE gwr.group_id = drg.id 
        AND CURRENT_DATE >= gwr.week_start_date 
        AND CURRENT_DATE <= gwr.week_end_date
    );
    
    IF problem_count > 0 THEN
        fix_message := fix_message || format('今週の週利設定なし: %sグループ ', problem_count);
    END IF;
    
    RAISE NOTICE '問題検出: %', fix_message;
END $$;

-- 2. NFTグループ設定の修正
UPDATE nfts SET daily_rate_group_id = (
    SELECT id FROM daily_rate_groups WHERE group_name = '0.5%グループ'
) WHERE name LIKE '%50%' AND daily_rate_group_id IS NULL;

UPDATE nfts SET daily_rate_group_id = (
    SELECT id FROM daily_rate_groups WHERE group_name = '1.0%グループ'
) WHERE name LIKE '%100%' AND daily_rate_group_id IS NULL;

UPDATE nfts SET daily_rate_group_id = (
    SELECT id FROM daily_rate_groups WHERE group_name = '1.25%グループ'
) WHERE name LIKE '%125%' AND daily_rate_group_id IS NULL;

UPDATE nfts SET daily_rate_group_id = (
    SELECT id FROM daily_rate_groups WHERE group_name = '1.5%グループ'
) WHERE name LIKE '%150%' AND daily_rate_group_id IS NULL;

UPDATE nfts SET daily_rate_group_id = (
    SELECT id FROM daily_rate_groups WHERE group_name = '1.75%グループ'
) WHERE name LIKE '%175%' AND daily_rate_group_id IS NULL;

UPDATE nfts SET daily_rate_group_id = (
    SELECT id FROM daily_rate_groups WHERE group_name = '2.0%グループ'
) WHERE name LIKE '%200%' AND daily_rate_group_id IS NULL;

-- 特別NFTの設定
UPDATE nfts SET daily_rate_group_id = (
    SELECT id FROM daily_rate_groups WHERE group_name = '2.0%グループ'
) WHERE name LIKE '%SHOGUN%' AND daily_rate_group_id IS NULL;

-- 3. 今週の週利設定を緊急作成（もし存在しない場合）
DO $$
DECLARE
    current_monday DATE;
    current_friday DATE;
    group_rec RECORD;
BEGIN
    -- 今週の月曜日を計算
    current_monday := CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE) - 1) * INTERVAL '1 day';
    current_friday := current_monday + INTERVAL '4 days';
    
    -- 各グループに対して今週の設定を作成
    FOR group_rec IN 
        SELECT id, group_name FROM daily_rate_groups
    LOOP
        -- 既存チェック
        IF NOT EXISTS (
            SELECT 1 FROM group_weekly_rates 
            WHERE group_id = group_rec.id 
            AND week_start_date = current_monday
        ) THEN
            -- デフォルト週利で設定
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
                current_monday,
                current_friday,
                CASE group_rec.group_name
                    WHEN '0.5%グループ' THEN 0.015
                    WHEN '1.0%グループ' THEN 0.020
                    WHEN '1.25%グループ' THEN 0.023
                    WHEN '1.5%グループ' THEN 0.026
                    WHEN '1.75%グループ' THEN 0.029
                    WHEN '2.0%グループ' THEN 0.032
                    ELSE 0.020
                END,
                -- 月〜金に均等分散
                CASE group_rec.group_name
                    WHEN '0.5%グループ' THEN 0.003
                    WHEN '1.0%グループ' THEN 0.004
                    WHEN '1.25%グループ' THEN 0.0046
                    WHEN '1.5%グループ' THEN 0.0052
                    WHEN '1.75%グループ' THEN 0.0058
                    WHEN '2.0%グループ' THEN 0.0064
                    ELSE 0.004
                END,
                CASE group_rec.group_name
                    WHEN '0.5%グループ' THEN 0.003
                    WHEN '1.0%グループ' THEN 0.004
                    WHEN '1.25%グループ' THEN 0.0046
                    WHEN '1.5%グループ' THEN 0.0052
                    WHEN '1.75%グループ' THEN 0.0058
                    WHEN '2.0%グループ' THEN 0.0064
                    ELSE 0.004
                END,
                CASE group_rec.group_name
                    WHEN '0.5%グループ' THEN 0.003
                    WHEN '1.0%グループ' THEN 0.004
                    WHEN '1.25%グループ' THEN 0.0046
                    WHEN '1.5%グループ' THEN 0.0052
                    WHEN '1.75%グループ' THEN 0.0058
                    WHEN '2.0%グループ' THEN 0.0064
                    ELSE 0.004
                END,
                CASE group_rec.group_name
                    WHEN '0.5%グループ' THEN 0.003
                    WHEN '1.0%グループ' THEN 0.004
                    WHEN '1.25%グループ' THEN 0.0046
                    WHEN '1.5%グループ' THEN 0.0052
                    WHEN '1.75%グループ' THEN 0.0058
                    WHEN '2.0%グループ' THEN 0.0064
                    ELSE 0.004
                END,
                CASE group_rec.group_name
                    WHEN '0.5%グループ' THEN 0.003
                    WHEN '1.0%グループ' THEN 0.004
                    WHEN '1.25%グループ' THEN 0.0046
                    WHEN '1.5%グループ' THEN 0.0052
                    WHEN '1.75%グループ' THEN 0.0058
                    WHEN '2.0%グループ' THEN 0.0064
                    ELSE 0.004
                END,
                'emergency_fix',
                NOW(),
                NOW()
            );
            
            RAISE NOTICE '緊急作成: % - 今週の週利設定', group_rec.group_name;
        END IF;
    END LOOP;
END $$;

-- 4. 日利計算関数の修正
CREATE OR REPLACE FUNCTION calculate_daily_rewards_fixed(
    target_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_count INTEGER,
    total_amount NUMERIC
) AS $$
DECLARE
    processed_count INTEGER := 0;
    total_amount NUMERIC := 0;
    day_of_week INTEGER;
    calculation_rec RECORD;
BEGIN
    -- 曜日チェック（0=日曜, 1=月曜...6=土曜）
    day_of_week := EXTRACT(DOW FROM target_date);
    
    IF day_of_week = 0 OR day_of_week = 6 THEN
        RETURN QUERY SELECT 
            false,
            format('土日は計算対象外です: %s', target_date::TEXT),
            0,
            0::NUMERIC;
        RETURN;
    END IF;
    
    -- 既存の報酬データを削除
    DELETE FROM daily_rewards WHERE reward_date = target_date;
    
    -- 計算実行
    FOR calculation_rec IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.purchase_price,
            n.daily_rate_limit,
            drg.group_name,
            CASE day_of_week
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END as daily_rate
        FROM user_nfts un
        JOIN users u ON un.user_id = u.id
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
        JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
        WHERE u.is_admin = false
        AND un.operation_start_date <= target_date
        AND target_date >= gwr.week_start_date
        AND target_date <= gwr.week_end_date
    LOOP
        DECLARE
            reward_amount NUMERIC;
        BEGIN
            -- 報酬計算
            reward_amount := calculation_rec.purchase_price * calculation_rec.daily_rate;
            
            -- 上限適用
            IF reward_amount > calculation_rec.daily_rate_limit THEN
                reward_amount := calculation_rec.daily_rate_limit;
            END IF;
            
            -- 報酬が0より大きい場合のみ記録
            IF reward_amount > 0 THEN
                INSERT INTO daily_rewards (
                    user_nft_id,
                    reward_amount,
                    reward_date,
                    created_at,
                    updated_at
                ) VALUES (
                    calculation_rec.user_nft_id,
                    reward_amount,
                    target_date,
                    NOW(),
                    NOW()
                );
                
                processed_count := processed_count + 1;
                total_amount := total_amount + reward_amount;
            END IF;
        END;
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('%s件の報酬を計算しました（合計: $%s）', processed_count, ROUND(total_amount, 2)),
        processed_count,
        total_amount;
        
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 
            false,
            format('計算エラー: %s', SQLERRM),
            0,
            0::NUMERIC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 権限設定
GRANT EXECUTE ON FUNCTION calculate_daily_rewards_fixed(DATE) TO authenticated;

-- 完了メッセージ
SELECT 'Emergency calculation system fixed' as status;
