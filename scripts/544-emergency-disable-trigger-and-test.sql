-- トリガーを一時的に無効化してテスト

-- 1. トリガーを無効化
ALTER TABLE daily_rewards DISABLE TRIGGER trigger_300_percent_cap;

-- 2. 1件だけテストINSERT
DO $$
DECLARE
    test_user_nft_id UUID := '55cbdcbc-df77-414b-8d15-2b40c7369a11';
    test_user_id UUID := 'deaa37bc-cc8e-4225-866e-a31e22fd4efe';
    test_nft_id UUID := '240f2ce8-9f58-4c8b-888a-c32c2953df4e';
    calc_date DATE := CURRENT_DATE;
    week_start DATE := date_trunc('week', CURRENT_DATE);
    existing_count INTEGER;
BEGIN
    -- 既存レコードをチェック
    SELECT COUNT(*) INTO existing_count
    FROM daily_rewards 
    WHERE user_nft_id = test_user_nft_id 
    AND reward_date = calc_date;
    
    IF existing_count = 0 THEN
        RAISE NOTICE 'テストINSERT実行中...';
        RAISE NOTICE 'user_nft_id: %', test_user_nft_id;
        RAISE NOTICE 'user_id: %', test_user_id;
        RAISE NOTICE 'nft_id: %', test_nft_id;
        
        INSERT INTO daily_rewards (
            user_id,
            user_nft_id,
            nft_id,
            reward_date,
            week_start_date,
            daily_rate,
            reward_amount,
            is_claimed,
            created_at,
            updated_at
        ) VALUES (
            test_user_id,
            test_user_nft_id,
            test_nft_id,
            calc_date,
            week_start,
            0.005,
            150.00,
            false,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        
        RAISE NOTICE '✅ テストINSERT成功！';
    ELSE
        RAISE NOTICE 'テストレコードは既に存在します';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ テストINSERT失敗: %', SQLERRM;
END $$;

-- 3. トリガーを再有効化
ALTER TABLE daily_rewards ENABLE TRIGGER trigger_300_percent_cap;

-- 4. 結果確認
SELECT 
    '🔍 テスト結果確認' as info,
    user_id,
    user_nft_id,
    nft_id,
    reward_date,
    reward_amount,
    created_at
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE
ORDER BY created_at DESC
LIMIT 5;
