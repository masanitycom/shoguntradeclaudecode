-- 🚨 日利計算関数の修正（テーブル名を明示）

-- 既存関数を削除
DROP FUNCTION IF EXISTS force_daily_calculation() CASCADE;

-- 修正された強制日利計算関数
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS JSON AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
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
    
    -- 簡易計算実行（テーブル名を明示）
    INSERT INTO daily_rewards (
        user_nft_id,
        reward_amount,
        reward_date,
        created_at,
        updated_at
    )
    SELECT 
        user_nfts.id,
        LEAST(user_nfts.purchase_price * 0.01, nfts.daily_rate_limit) as reward_amount,
        today_date,
        NOW(),
        NOW()
    FROM user_nfts
    JOIN nfts ON user_nfts.nft_id = nfts.id
    WHERE user_nfts.purchase_price > 0
    AND nfts.daily_rate_limit > 0
    AND user_nfts.is_active = true
    ON CONFLICT (user_nft_id, reward_date) DO UPDATE SET
        reward_amount = EXCLUDED.reward_amount,
        updated_at = NOW();
    
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    SELECT json_build_object(
        'success', true,
        'message', format('簡易計算完了: %s件処理', processed_count),
        'calculation_date', today_date,
        'processed_count', processed_count
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 修正完了メッセージ
SELECT '日利計算関数が修正されました！' as "修正結果";
