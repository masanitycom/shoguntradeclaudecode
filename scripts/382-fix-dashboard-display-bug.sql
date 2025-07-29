-- 週利配分システムの完全修正

-- 1. 現在の計算関数を確認
SELECT 
    '🔧 現在の関数確認' as info,
    routine_name as 関数名,
    routine_definition as 関数定義
FROM information_schema.routines 
WHERE routine_name LIKE '%daily%' 
AND routine_type = 'FUNCTION';

-- 2. 正しい週利配分システムの実装
DROP FUNCTION IF EXISTS calculate_daily_rewards_correct(DATE);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_correct(target_date DATE)
RETURNS TABLE(
    user_id UUID,
    user_nft_id UUID,
    nft_name TEXT,
    investment_amount NUMERIC,
    weekly_rate NUMERIC,
    daily_rate NUMERIC,
    reward_amount NUMERIC,
    calculation_method TEXT
) AS $$
DECLARE
    day_of_week INTEGER;
    week_start DATE;
    rate_column TEXT;
BEGIN
    -- 曜日を取得（1=月曜, 2=火曜, ..., 5=金曜）
    day_of_week := EXTRACT(DOW FROM target_date);
    
    -- 平日以外は計算しない
    IF day_of_week NOT IN (1, 2, 3, 4, 5) THEN
        RETURN;
    END IF;
    
    -- その週の月曜日を計算
    week_start := target_date - (day_of_week - 1) * INTERVAL '1 day';
    
    -- 曜日に対応する列名を決定
    rate_column := CASE day_of_week
        WHEN 1 THEN 'monday_rate'
        WHEN 2 THEN 'tuesday_rate'
        WHEN 3 THEN 'wednesday_rate'
        WHEN 4 THEN 'thursday_rate'
        WHEN 5 THEN 'friday_rate'
    END;
    
    -- 週利設定がある場合のみ計算
    RETURN QUERY
    SELECT 
        u.id as user_id,
        un.id as user_nft_id,
        n.name as nft_name,
        n.price as investment_amount,
        gwr.weekly_rate as weekly_rate,
        CASE rate_column
            WHEN 'monday_rate' THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'tuesday_rate' THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'wednesday_rate' THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'thursday_rate' THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'friday_rate' THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        END as daily_rate,
        n.price * CASE rate_column
            WHEN 'monday_rate' THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'tuesday_rate' THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'wednesday_rate' THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'thursday_rate' THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 'friday_rate' THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        END as reward_amount,
        '週利配分システム' as calculation_method
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE un.is_active = true
    AND gwr.week_start_date = week_start
    AND CASE rate_column
        WHEN 'monday_rate' THEN gwr.monday_rate
        WHEN 'tuesday_rate' THEN gwr.tuesday_rate
        WHEN 'wednesday_rate' THEN gwr.wednesday_rate
        WHEN 'thursday_rate' THEN gwr.thursday_rate
        WHEN 'friday_rate' THEN gwr.friday_rate
    END IS NOT NULL
    AND CASE rate_column
        WHEN 'monday_rate' THEN gwr.monday_rate
        WHEN 'tuesday_rate' THEN gwr.tuesday_rate
        WHEN 'wednesday_rate' THEN gwr.wednesday_rate
        WHEN 'thursday_rate' THEN gwr.thursday_rate
        WHEN 'friday_rate' THEN gwr.friday_rate
    END > 0;
END;
$$ LANGUAGE plpgsql;

-- 3. 2025-02-10週の正しい計算テスト
SELECT 
    '🧪 2025-02-12(水曜)の正しい計算テスト' as info,
    *
FROM calculate_daily_rewards_correct('2025-02-12')
WHERE nft_name IN ('SHOGUN NFT 100', 'SHOGUN NFT 1000 (Special)')
LIMIT 5;

-- 4. 今日(7/2)は週利設定がないことを確認
SELECT 
    '❌ 今日は計算対象外' as info,
    CURRENT_DATE as 今日,
    '週利設定がない週' as 理由,
    '計算は実行されるべきではない' as 正しい動作;

-- 5. 既存の間違った報酬データを削除（オプション）
-- DELETE FROM daily_rewards WHERE reward_date = CURRENT_DATE;

-- 6. user_nftsのtotal_earnedを正しい値に更新
UPDATE user_nfts 
SET total_earned = (
    SELECT COALESCE(SUM(dr.reward_amount), 0)
    FROM daily_rewards dr
    WHERE dr.user_nft_id = user_nfts.id
),
updated_at = NOW()
WHERE is_active = true;

-- 7. 修正結果の確認
SELECT 
    '✅ 修正完了確認' as info,
    COUNT(*) as 更新されたNFT数,
    SUM(total_earned) as 総報酬額,
    AVG(total_earned) as 平均報酬
FROM user_nfts 
WHERE is_active = true;
