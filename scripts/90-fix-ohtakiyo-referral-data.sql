-- OHTAKIYOユーザーの紹介データを確認・生成
DO $$
DECLARE
    user_record RECORD;
    base_url TEXT := 'https://shogun-trade.vercel.app';
BEGIN
    -- OHTAKIYOユーザーを取得
    SELECT * INTO user_record 
    FROM users 
    WHERE user_id = 'OHTAKIYO';
    
    IF user_record.id IS NULL THEN
        RAISE EXCEPTION 'OHTAKIYOユーザーが見つかりません';
    END IF;
    
    -- 紹介コードと紹介リンクを更新
    UPDATE users 
    SET 
        my_referral_code = COALESCE(my_referral_code, 'OHTAKIYO'),
        referral_link = COALESCE(referral_link, base_url || '/register?ref=OHTAKIYO'),
        updated_at = NOW()
    WHERE id = user_record.id;
    
    RAISE NOTICE 'Updated referral data for user: %', user_record.user_id;
END $$;

-- 結果を確認
SELECT 
    'Updated referral data' as status,
    user_id,
    my_referral_code,
    referral_link
FROM users 
WHERE user_id = 'OHTAKIYO';
