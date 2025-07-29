-- 修正された日利計算関数を作成するスクリプト
-- グループ別週利システムと300%キャップに対応

-- 既存の関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_week(DATE);
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_user(UUID, DATE);
DROP FUNCTION IF EXISTS distribute_weekly_rate_to_days(DECIMAL);

-- 週利を平日に分散する関数
CREATE OR REPLACE FUNCTION distribute_weekly_rate_to_days(weekly_rate DECIMAL)
RETURNS DECIMAL[]
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    daily_rates DECIMAL[] := ARRAY[0, 0, 0, 0, 0]; -- 月火水木金
    base_rate DECIMAL;
    remaining_rate DECIMAL;
    random_adjustments DECIMAL[] := ARRAY[0.1, -0.05, 0.03, -0.08, 0.0]; -- ランダム調整値
    i INTEGER;
BEGIN
    -- 基本日利を計算（週利を5で割る）
    base_rate := weekly_rate / 5.0;
    
    -- 各曜日に基本日利を設定
    FOR i IN 1..5 LOOP
        daily_rates[i] := base_rate + (base_rate * random_adjustments[i]);
        -- 負の値にならないよう調整
        IF daily_rates[i] < 0 THEN
            daily_rates[i] := 0;
        END IF;
    END LOOP;
    
    -- 合計が週利と一致するよう最終調整
    remaining_rate := weekly_rate - (daily_rates[1] + daily_rates[2] + daily_rates[3] + daily_rates[4] + daily_rates[5]);
    daily_rates[5] := daily_rates[5] + remaining_rate;
    
    -- 最終的に負の値にならないよう調整
    IF daily_rates[5] < 0 THEN
        daily_rates[5] := 0;
    END IF;
    
    RETURN daily_rates;
END $$;

-- ユーザーの特定日の日利を計算する関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_user(
    target_user_id UUID,
    target_date DATE
)
RETURNS TABLE(
    user_id UUID,
    nft_id UUID,
    reward_date DATE,
    daily_rate DECIMAL,
    investment_amount DECIMAL,
    reward_amount DECIMAL,
    cumulative_rewards DECIMAL,
    remaining_capacity DECIMAL,
    is_completed BOOLEAN
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    user_nft RECORD;
    week_start DATE;
    day_of_week INTEGER;
    weekly_rate DECIMAL;
    daily_rates DECIMAL[];
    daily_rate DECIMAL;
    current_cumulative DECIMAL;
    max_rewards DECIMAL;
    reward_amount DECIMAL;
    remaining_capacity DECIMAL;
    is_weekday BOOLEAN;
BEGIN
    -- 平日チェック（月曜=1, 日曜=7）
    day_of_week := EXTRACT(DOW FROM target_date);
    is_weekday := day_of_week BETWEEN 1 AND 5;
    
    -- 平日でない場合は何も返さない
    IF NOT is_weekday THEN
        RETURN;
    END IF;
    
    -- 週の開始日を計算（月曜日）
    week_start := target_date - (day_of_week - 1) * INTERVAL '1 day';
    
    -- ユーザーのアクティブなNFTを取得
    FOR user_nft IN
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.purchase_amount,
            un.is_active,
            n.price as nft_price,
            n.daily_rate_limit,
            n.name as nft_name
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        WHERE un.user_id = target_user_id
        AND un.is_active = true
        AND un.purchase_amount > 0
    LOOP
        -- NFTグループの週利を取得
        weekly_rate := get_weekly_rate(user_nft.nft_price, week_start);
        
        -- 週利を日利に分散
        daily_rates := distribute_weekly_rate_to_days(weekly_rate);
        
        -- 対象日の日利を取得
        daily_rate := daily_rates[day_of_week];
        
        -- 日利上限チェック
        IF daily_rate > user_nft.daily_rate_limit THEN
            daily_rate := user_nft.daily_rate_limit;
        END IF;
        
        -- 現在の累積報酬を取得
        SELECT COALESCE(SUM(dr.reward_amount), 0) INTO current_cumulative
        FROM daily_rewards dr
        WHERE dr.user_id = target_user_id
        AND dr.nft_id = user_nft.nft_id;
        
        -- 最大報酬額（300%キャップ）
        max_rewards := user_nft.purchase_amount * 3.0;
        
        -- 残り報酬容量
        remaining_capacity := max_rewards - current_cumulative;
        
        -- NFTが完了済みかチェック
        IF remaining_capacity <= 0 THEN
            -- 完了済みNFTの情報を返す
            user_id := user_nft.user_id;
            nft_id := user_nft.nft_id;
            reward_date := target_date;
            daily_rate := 0;
            investment_amount := user_nft.purchase_amount;
            reward_amount := 0;
            cumulative_rewards := current_cumulative;
            remaining_capacity := 0;
            is_completed := true;
            RETURN NEXT;
            CONTINUE;
        END IF;
        
        -- 報酬額を計算
        reward_amount := user_nft.purchase_amount * (daily_rate / 100.0);
        
        -- 残り容量を超えないよう調整
        IF reward_amount > remaining_capacity THEN
            reward_amount := remaining_capacity;
        END IF;
        
        -- 結果を返す
        user_id := user_nft.user_id;
        nft_id := user_nft.nft_id;
        reward_date := target_date;
        investment_amount := user_nft.purchase_amount;
        cumulative_rewards := current_cumulative;
        is_completed := (current_cumulative + reward_amount >= max_rewards);
        
        RETURN NEXT;
    END LOOP;
END $$;

-- 指定週の全ユーザーの日利を計算する関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_week(week_start_date DATE)
RETURNS TABLE(
    calculation_date DATE,
    total_users INTEGER,
    total_nfts INTEGER,
    total_rewards DECIMAL,
    completed_nfts INTEGER,
    processing_summary TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_date DATE;
    day_count INTEGER := 0;
    total_processed INTEGER := 0;
    daily_summary TEXT := '';
BEGIN
    RAISE NOTICE '🔧 週間日利計算開始: %', week_start_date;
    
    -- 月曜日から金曜日まで処理
    FOR day_count IN 0..4 LOOP
        current_date := week_start_date + (day_count * INTERVAL '1 day');
        
        -- 既存の日利データを削除（再計算の場合）
        DELETE FROM daily_rewards 
        WHERE reward_date = current_date;
        
        -- 全ユーザーの日利を計算して挿入
        INSERT INTO daily_rewards (
            user_id, nft_id, reward_date, daily_rate, 
            investment_amount, reward_amount, created_at
        )
        SELECT 
            calc.user_id,
            calc.nft_id,
            calc.reward_date,
            calc.daily_rate,
            calc.investment_amount,
            calc.reward_amount,
            NOW()
        FROM (
            SELECT DISTINCT u.id as user_id
            FROM users u
            WHERE EXISTS (
                SELECT 1 FROM user_nfts un 
                WHERE un.user_id = u.id 
                AND un.is_active = true
            )
        ) users_with_nfts
        CROSS JOIN LATERAL calculate_daily_rewards_for_user(users_with_nfts.user_id, current_date) calc
        WHERE calc.reward_amount > 0;
        
        GET DIAGNOSTICS total_processed = ROW_COUNT;
        
        daily_summary := daily_summary || current_date || ': ' || total_processed || '件, ';
        
        RAISE NOTICE '✅ % の日利計算完了: % 件処理', current_date, total_processed;
    END LOOP;
    
    -- 週間サマリーを返す
    calculation_date := week_start_date;
    
    SELECT 
        COUNT(DISTINCT dr.user_id),
        COUNT(DISTINCT dr.nft_id),
        COALESCE(SUM(dr.reward_amount), 0),
        COUNT(CASE WHEN un.purchase_amount * 3.0 <= 
            (SELECT COALESCE(SUM(dr2.reward_amount), 0) 
             FROM daily_rewards dr2 
             WHERE dr2.user_id = dr.user_id AND dr2.nft_id = dr.nft_id)
        THEN 1 END)
    INTO total_users, total_nfts, total_rewards, completed_nfts
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_id = un.user_id AND dr.nft_id = un.nft_id
    WHERE dr.reward_date BETWEEN week_start_date AND week_start_date + INTERVAL '4 days';
    
    processing_summary := '週間処理: ' || daily_summary;
    
    RETURN NEXT;
    
    RAISE NOTICE '✅ 週間日利計算完了: % - 総報酬額: %', week_start_date, total_rewards;
END $$;

-- テスト用の日利計算実行関数
CREATE OR REPLACE FUNCTION test_daily_calculation(test_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    test_result TEXT,
    user_count INTEGER,
    nft_count INTEGER,
    total_reward DECIMAL,
    sample_data TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    sample_record RECORD;
    sample_text TEXT := '';
BEGIN
    RAISE NOTICE '🧪 日利計算テスト開始: %', test_date;
    
    -- テスト実行
    SELECT 
        COUNT(DISTINCT calc.user_id),
        COUNT(DISTINCT calc.nft_id),
        COALESCE(SUM(calc.reward_amount), 0)
    INTO user_count, nft_count, total_reward
    FROM (
        SELECT DISTINCT u.id as user_id
        FROM users u
        WHERE EXISTS (
            SELECT 1 FROM user_nfts un 
            WHERE un.user_id = u.id 
            AND un.is_active = true
        )
        LIMIT 5  -- テスト用に5ユーザーのみ
    ) test_users
    CROSS JOIN LATERAL calculate_daily_rewards_for_user(test_users.user_id, test_date) calc;
    
    -- サンプルデータを取得
    FOR sample_record IN
        SELECT 
            u.username,
            n.name as nft_name,
            calc.daily_rate,
            calc.reward_amount
        FROM (
            SELECT DISTINCT u.id as user_id
            FROM users u
            WHERE EXISTS (
                SELECT 1 FROM user_nfts un 
                WHERE un.user_id = u.id 
                AND un.is_active = true
            )
            LIMIT 3
        ) test_users
        CROSS JOIN LATERAL calculate_daily_rewards_for_user(test_users.user_id, test_date) calc
        JOIN users u ON calc.user_id = u.id
        JOIN nfts n ON calc.nft_id = n.id
        LIMIT 5
    LOOP
        sample_text := sample_text || sample_record.username || '(' || sample_record.nft_name || 
                      '): ' || sample_record.daily_rate || '% = $' || sample_record.reward_amount || '; ';
    END LOOP;
    
    test_result := 'テスト完了';
    sample_data := sample_text;
    
    RETURN NEXT;
    
    RAISE NOTICE '✅ テスト完了 - ユーザー: %, NFT: %, 総報酬: $%', user_count, nft_count, total_reward;
END $$;

RAISE NOTICE '✅ 日利計算関数の作成が完了しました';

-- 関数のテスト実行
SELECT * FROM test_daily_calculation();
