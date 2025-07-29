-- 緊急修正：日利計算システムの完全再構築

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS force_daily_calculation();
DROP FUNCTION IF EXISTS calculate_daily_rewards(DATE);

-- 2. テーブル構造に基づいた新しい日利計算関数を作成
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS TABLE(
    status TEXT,
    message TEXT,
    processed_users INTEGER,
    total_rewards DECIMAL(10,2),
    debug_info TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    current_date_jst DATE;
    processed_count INTEGER := 0;
    total_amount DECIMAL(10,2) := 0;
    user_record RECORD;
    nft_record RECORD;
    daily_rate DECIMAL(5,4);
    reward_amount DECIMAL(10,2);
    week_start DATE;
    day_of_week INTEGER;
    debug_messages TEXT := '';
    total_nfts INTEGER := 0;
    total_rates INTEGER := 0;
    group_name_var TEXT;
BEGIN
    -- 日本時間の現在日付を取得
    current_date_jst := CURRENT_DATE;
    debug_messages := debug_messages || format('計算日: %s, ', current_date_jst);
    
    -- 平日チェック（月曜=1, 金曜=5）
    day_of_week := EXTRACT(DOW FROM current_date_jst);
    debug_messages := debug_messages || format('曜日: %s, ', day_of_week);
    
    IF day_of_week = 0 OR day_of_week = 6 THEN
        RETURN QUERY SELECT 
            'skipped'::TEXT,
            '土日は日利計算を実行しません'::TEXT,
            0,
            0.00::DECIMAL(10,2),
            debug_messages;
        RETURN;
    END IF;
    
    -- 週の開始日（月曜日）を計算
    week_start := current_date_jst - (day_of_week - 1);
    debug_messages := debug_messages || format('週開始: %s, ', week_start);
    
    -- システム状況をチェック
    SELECT COUNT(*) INTO total_nfts FROM user_nfts WHERE is_active = true;
    SELECT COUNT(*) INTO total_rates FROM group_weekly_rates WHERE week_start_date = week_start;
    
    debug_messages := debug_messages || format('NFT数: %s, 週利設定数: %s, ', total_nfts, total_rates);
    
    -- 週利設定がない場合は終了
    IF total_rates = 0 THEN
        RETURN QUERY SELECT 
            'error'::TEXT,
            format('週利設定が見つかりません（週開始: %s）', week_start)::TEXT,
            0,
            0.00::DECIMAL(10,2),
            debug_messages;
        RETURN;
    END IF;
    
    -- 各ユーザーの処理
    FOR user_record IN 
        SELECT DISTINCT u.id, u.name
        FROM users u
        INNER JOIN user_nfts un ON u.id = un.user_id
        WHERE un.is_active = true
    LOOP
        -- ユーザーの各NFTを処理
        FOR nft_record IN
            SELECT 
                un.id as user_nft_id,
                un.user_id,
                un.nft_id,
                un.purchase_price,
                n.daily_rate_limit,
                n.price as nft_price
            FROM user_nfts un
            INNER JOIN nfts n ON un.nft_id = n.id
            WHERE un.user_id = user_record.id 
              AND un.is_active = true
        LOOP
            -- 既に今日の報酬が計算済みかチェック
            IF EXISTS (
                SELECT 1 FROM daily_rewards 
                WHERE user_id = nft_record.user_id 
                  AND user_nft_id = nft_record.user_nft_id
                  AND reward_date = current_date_jst
            ) THEN
                CONTINUE;
            END IF;
            
            -- NFTの価格に基づいてグループを決定
            CASE 
                WHEN nft_record.nft_price <= 100 THEN group_name_var := '0.5%グループ';
                WHEN nft_record.nft_price <= 300 THEN group_name_var := '1.0%グループ';
                WHEN nft_record.nft_price <= 500 THEN group_name_var := '1.25%グループ';
                WHEN nft_record.nft_price <= 1000 THEN group_name_var := '1.5%グループ';
                WHEN nft_record.nft_price <= 1500 THEN group_name_var := '1.75%グループ';
                ELSE group_name_var := '2.0%グループ';
            END CASE;
            
            -- 週利から日利を取得
            SELECT 
                CASE day_of_week
                    WHEN 1 THEN monday_rate
                    WHEN 2 THEN tuesday_rate  
                    WHEN 3 THEN wednesday_rate
                    WHEN 4 THEN thursday_rate
                    WHEN 5 THEN friday_rate
                    ELSE 0
                END INTO daily_rate
            FROM group_weekly_rates
            WHERE week_start_date = week_start
              AND (
                  -- group_nameカラムが存在する場合
                  (EXISTS (SELECT 1 FROM information_schema.columns 
                          WHERE table_name = 'group_weekly_rates' AND column_name = 'group_name')
                   AND group_name = group_name_var)
                  OR
                  -- group_nameカラムが存在しない場合は最初のレコードを使用
                  (NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name = 'group_weekly_rates' AND column_name = 'group_name'))
              )
            LIMIT 1;
            
            -- 日利が設定されていない場合はデフォルト値を使用
            IF daily_rate IS NULL THEN
                daily_rate := 0.005; -- 0.5%のデフォルト
                debug_messages := debug_messages || format('デフォルト日利使用: %s, ', group_name_var);
            END IF;
            
            -- 報酬計算
            reward_amount := nft_record.purchase_price * daily_rate;
            
            -- 日利上限チェック
            IF nft_record.daily_rate_limit > 0 AND reward_amount > nft_record.daily_rate_limit THEN
                reward_amount := nft_record.daily_rate_limit;
            END IF;
            
            -- 報酬記録を挿入
            INSERT INTO daily_rewards (
                user_id,
                user_nft_id,
                nft_id,
                reward_amount,
                daily_rate,
                reward_date,
                created_at,
                updated_at
            ) VALUES (
                nft_record.user_id,
                nft_record.user_nft_id,
                nft_record.nft_id,
                reward_amount,
                daily_rate,
                current_date_jst,
                NOW(),
                NOW()
            );
            
            processed_count := processed_count + 1;
            total_amount := total_amount + reward_amount;
        END LOOP;
    END LOOP;
    
    RETURN QUERY SELECT 
        'success'::TEXT,
        format('日利計算完了: %s件処理、合計$%s', processed_count, total_amount)::TEXT,
        processed_count,
        total_amount,
        debug_messages;
END;
$$;

-- 権限設定
GRANT EXECUTE ON FUNCTION force_daily_calculation() TO authenticated;
