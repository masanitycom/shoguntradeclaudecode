-- 全ユーザーに紹介リンクを生成
DO $$
DECLARE
    user_record RECORD;
    base_url TEXT := 'https://shogun-trade.vercel.app';
    updated_count INTEGER := 0;
BEGIN
    -- 管理者以外の全ユーザーに紹介リンクを生成
    FOR user_record IN 
        SELECT id, user_id, my_referral_code 
        FROM users 
        WHERE is_admin = false
        ORDER BY created_at
    LOOP
        -- 紹介リンクを生成・更新
        UPDATE users 
        SET 
            referral_link = base_url || '/register?ref=' || user_record.user_id,
            updated_at = NOW()
        WHERE id = user_record.id;
        
        updated_count := updated_count + 1;
        
        RAISE NOTICE '✅ % さん (ID: %) の紹介リンクを生成', 
            (SELECT name FROM users WHERE id = user_record.id), 
            user_record.user_id;
    END LOOP;
    
    RAISE NOTICE '🎉 合計 % 人のユーザーに紹介リンクを生成しました', updated_count;
END
$$;

-- 結果確認
SELECT 
    COUNT(*) as total_users,
    COUNT(referral_link) as users_with_links,
    COUNT(*) - COUNT(referral_link) as users_without_links
FROM users 
WHERE is_admin = false;

SELECT '=== 紹介リンク生成完了 ===' as result;
