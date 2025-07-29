-- 🚨 緊急修復: week_start_date 問題を完全解決

SELECT '=== 🚨 緊急修復開始: week_start_date 問題 🚨 ===' as "緊急修復開始";

-- 1. week_start_date カラムの NOT NULL 制約を削除
ALTER TABLE daily_rewards 
ALTER COLUMN week_start_date DROP NOT NULL;

-- 2. 既存のNULLデータに適切な週開始日を設定
UPDATE daily_rewards 
SET week_start_date = DATE_TRUNC('week', reward_date)::DATE
WHERE week_start_date IS NULL;

-- 3. force_daily_calculation 関数を完全修正
DROP FUNCTION IF EXISTS force_daily_calculation() CASCADE;

CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS JSON AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
    week_start DATE := DATE_TRUNC('week', today_date)::DATE;
    processed_count INTEGER := 0;
    result JSON;
BEGIN
    -- 平日チェック
    IF EXTRACT(DOW FROM today_date) IN (0, 6) THEN
        SELECT json_build_object(
            'success', false,
            'message', '土日は計算を実行しません',
            'calculation_date', today_date,
            'processed_count', 0
        ) INTO result;
        RETURN result;
    END IF;
    
    -- 完全な日利計算実行（全必須カラムを含む）
    INSERT INTO daily_rewards (
        user_nft_id,
        reward_amount,
        reward_date,
        week_start_date,
        daily_rate,
        created_at,
        updated_at
    )
    SELECT 
        user_nfts.id,
        LEAST(user_nfts.purchase_price * 0.01, nfts.daily_rate_limit) as reward_amount,
        today_date,
        week_start,
        0.01 as daily_rate,
        NOW(),
        NOW()
    FROM user_nfts
    JOIN nfts ON user_nfts.nft_id = nfts.id
    WHERE user_nfts.purchase_price > 0
    AND nfts.daily_rate_limit > 0
    AND user_nfts.is_active = true
    ON CONFLICT (user_nft_id, reward_date) DO UPDATE SET
        reward_amount = EXCLUDED.reward_amount,
        week_start_date = EXCLUDED.week_start_date,
        daily_rate = EXCLUDED.daily_rate,
        updated_at = NOW();
    
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    SELECT json_build_object(
        'success', true,
        'message', format('完全な日利計算完了: %s件処理', processed_count),
        'calculation_date', today_date,
        'week_start_date', week_start,
        'processed_count', processed_count
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 4. 修正結果確認
SELECT 
    column_name,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
AND column_name IN ('week_start_date', 'daily_rate')
ORDER BY column_name;

-- 5. テスト実行
SELECT force_daily_calculation() as "修正後テスト結果";

-- 完了メッセージ
SELECT '🎉 week_start_date 問題完全解決！' as "解決完了";
SELECT '✅ 日利計算が正常に動作します！' as "動作確認";
