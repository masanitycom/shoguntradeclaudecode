-- Phase 1動作テスト用のサンプルデータ

-- テスト用の週間利益データを挿入
INSERT INTO weekly_profits (week_start_date, total_profit, input_by)
SELECT 
    date_trunc('week', CURRENT_DATE)::DATE,
    50000.00,
    (SELECT id FROM users WHERE is_admin = true LIMIT 1)
WHERE NOT EXISTS (
    SELECT 1 FROM weekly_profits 
    WHERE week_start_date = date_trunc('week', CURRENT_DATE)::DATE
);

-- テスト用のNFT購入申請を作成（管理者以外の最初のユーザー）
DO $$
DECLARE
    test_user_id UUID;
    test_nft_id UUID;
BEGIN
    -- テスト用ユーザーを取得
    SELECT id INTO test_user_id 
    FROM users 
    WHERE is_admin = false 
    LIMIT 1;
    
    -- 通常NFTを取得
    SELECT id INTO test_nft_id 
    FROM nfts 
    WHERE is_special = false 
    AND is_active = true 
    ORDER BY price ASC 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_nft_id IS NOT NULL THEN
        -- 既存の申請がない場合のみ作成
        INSERT INTO nft_purchase_applications (
            user_id,
            nft_id,
            requested_price,
            payment_method,
            status
        )
        SELECT 
            test_user_id,
            test_nft_id,
            (SELECT price FROM nfts WHERE id = test_nft_id),
            'USDT_BEP20',
            'PENDING'
        WHERE NOT EXISTS (
            SELECT 1 FROM nft_purchase_applications 
            WHERE user_id = test_user_id 
            AND status IN ('PENDING', 'PAYMENT_SUBMITTED')
        );
        
        RAISE NOTICE '✅ テスト用NFT購入申請を作成しました';
    ELSE
        RAISE NOTICE 'ℹ️ テストユーザーまたはNFTが見つかりません';
    END IF;
END
$$;

-- 今週の営業日配分をテスト表示
DO $$
DECLARE
    test_week_start DATE := get_week_start(CURRENT_DATE);
    result RECORD;
BEGIN
    RAISE NOTICE '=== 今週の営業日配分（週利2.6%%） ===';
    
    FOR result IN 
        SELECT * FROM distribute_weekly_rate(0.026, test_week_start)
    LOOP
        RAISE NOTICE '% (%) : %.4f%%', 
            result.business_date,
            to_char(result.business_date, 'Dy'),
            result.daily_rate * 100;
    END LOOP;
END
$$;

-- 完了メッセージ
SELECT 'Phase 1テストデータ作成完了' AS result;
