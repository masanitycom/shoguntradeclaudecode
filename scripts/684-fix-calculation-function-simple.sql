-- シンプルで確実に動作する日利計算関数

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS force_daily_calculation();

-- 2. シンプルな日利計算関数を作成
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS TABLE(
    status TEXT,
    message TEXT,
    processed_users INTEGER,
    total_rewards DECIMAL(10,2)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    current_date_jst DATE;
    processed_count INTEGER := 0;
    total_amount DECIMAL(10,2) := 0;
    user_record RECORD;
    daily_rate DECIMAL(8,6);
    reward_amount DECIMAL(10,2);
    week_start DATE;
    day_of_week INTEGER;
BEGIN
    -- 日本時間の現在日付を取得
    current_date_jst := CURRENT_DATE;
    
    -- 平日チェック（日曜=0, 月曜=1, ..., 土曜=6）
    day_of_week := EXTRACT(DOW FROM current_date_jst);
    
    IF day_of_week = 0 OR day_of_week = 6 THEN
        RETURN QUERY SELECT 
            'skipped'::TEXT,
            '土日は日利計算を実行しません'::TEXT,
            0,
            0.00::DECIMAL(10,2);
        RETURN;
    END IF;
    
    -- 週の開始日（月曜日）を計算
    week_start := current_date_jst - (day_of_week - 1);
    
    -- 今日の日利レートを取得（シンプルに最初の設定を使用）
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
    LIMIT 1;
    
    -- 日利が設定されていない場合はデフォルト値を使用
    IF daily_rate IS NULL OR daily_rate = 0 THEN
        daily_rate := 0.0052; -- デフォルト0.52%
    END IF;
    
    -- 各ユーザーNFTの処理
    FOR user_record IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.purchase_price
        FROM user_nfts un
        WHERE un.is_active = true
          AND NOT EXISTS (
              SELECT 1 FROM daily_rewards 
              WHERE user_id = un.user_id 
                AND user_nft_id = un.id
                AND reward_date = current_date_jst
          )
    LOOP
        -- 報酬計算（購入価格 × 日利）
        reward_amount := user_record.purchase_price * daily_rate;
        
        -- 最小報酬チェック（0.01ドル未満は切り上げ）
        IF reward_amount > 0 AND reward_amount < 0.01 THEN
            reward_amount := 0.01;
        END IF;
        
        -- 報酬記録を挿入
        IF reward_amount > 0 THEN
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
                user_record.user_id,
                user_record.user_nft_id,
                user_record.nft_id,
                reward_amount,
                daily_rate,
                current_date_jst,
                NOW(),
                NOW()
            );
            
            processed_count := processed_count + 1;
            total_amount := total_amount + reward_amount;
        END IF;
    END LOOP;
    
    RETURN QUERY SELECT 
        'success'::TEXT,
        format('日利計算完了: %s件処理、合計$%s', processed_count, total_amount)::TEXT,
        processed_count,
        total_amount;
END;
$$;

-- 権限設定
GRANT EXECUTE ON FUNCTION force_daily_calculation() TO authenticated;
