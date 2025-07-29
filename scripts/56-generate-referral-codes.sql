-- 既存ユーザーに紹介コードを生成

-- 管理者以外のユーザーに自分の紹介コードを生成
DO $$
DECLARE
    user_record RECORD;
    counter INTEGER := 1;
    generated_count INTEGER := 0;
BEGIN
    -- 紹介コードがないユーザーに順番に割り当て
    FOR user_record IN 
        SELECT id, name FROM users 
        WHERE my_referral_code IS NULL 
        AND is_admin = false
        ORDER BY created_at
    LOOP
        UPDATE users 
        SET my_referral_code = 'REF' || LPAD(counter::TEXT, 6, '0')
        WHERE id = user_record.id;
        
        RAISE NOTICE '✅ % さんに紹介コード REF% を生成', user_record.name, LPAD(counter::TEXT, 6, '0');
        
        counter := counter + 1;
        generated_count := generated_count + 1;
    END LOOP;
    
    RAISE NOTICE '🎉 合計 % 人のユーザーに紹介コードを生成しました', generated_count;
END
$$;

-- 紹介リンクを生成
UPDATE users 
SET referral_link = 'https://shogun-trade.com/register?ref=' || my_referral_code
WHERE referral_link IS NULL 
AND my_referral_code IS NOT NULL;

-- 結果確認
SELECT 
    COUNT(*) as total_users,
    COUNT(my_referral_code) as users_with_referral_code,
    COUNT(referral_link) as users_with_referral_link
FROM users 
WHERE is_admin = false;

SELECT '=== 紹介コード生成完了 ===' as result;
