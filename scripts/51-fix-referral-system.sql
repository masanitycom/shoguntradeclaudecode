-- 紹介システムの修正

-- 現在の紹介関係を確認
SELECT 'current_referral_status' as step;

SELECT 
    COUNT(*) as total_users,
    COUNT(referral_code) as has_referral_code,
    COUNT(my_referral_code) as has_own_code,
    COUNT(referral_link) as has_referral_link
FROM users 
WHERE is_admin = false;

-- 紹介関係の修正
DO $$
DECLARE
    user_record RECORD;
    referrer_record RECORD;
    available_referrers UUID[];
    selected_referrer_id UUID;
    random_index INTEGER;
    counter INTEGER := 0;
BEGIN
    -- 自分の紹介コードがないユーザーに生成
    UPDATE users 
    SET 
        my_referral_code = 'REF' || LPAD((ROW_NUMBER() OVER (ORDER BY created_at))::TEXT, 6, '0'),
        updated_at = NOW()
    WHERE my_referral_code IS NULL AND is_admin = false;
    
    -- 紹介リンクを生成
    UPDATE users 
    SET 
        referral_link = 'https://shogun-trade.com/register?ref=' || my_referral_code,
        updated_at = NOW()
    WHERE referral_link IS NULL AND my_referral_code IS NOT NULL;
    
    RAISE NOTICE '✅ 紹介コードと紹介リンクを生成しました';
    
    -- 紹介者がいないユーザーに紹介関係を設定
    -- 利用可能な紹介者（既存ユーザー）のIDを取得
    SELECT ARRAY(
        SELECT id FROM users 
        WHERE is_admin = false 
        AND my_referral_code IS NOT NULL
        AND created_at < NOW() - INTERVAL '1 day' -- 1日以上前に作成されたユーザー
        ORDER BY created_at
        LIMIT 50 -- 最大50人の紹介者候補
    ) INTO available_referrers;
    
    IF array_length(available_referrers, 1) > 0 THEN
        -- 紹介者がいないユーザーに紹介関係を設定
        FOR user_record IN 
            SELECT id, user_id, created_at
            FROM users 
            WHERE referral_code IS NULL 
            AND is_admin = false
            AND created_at > (SELECT MIN(created_at) + INTERVAL '1 day' FROM users WHERE is_admin = false)
            ORDER BY created_at
        LOOP
            -- ランダムな紹介者を選択
            random_index := floor(random() * array_length(available_referrers, 1)) + 1;
            selected_referrer_id := available_referrers[random_index];
            
            -- 紹介者の紹介コードを取得
            SELECT my_referral_code INTO referrer_record
            FROM users 
            WHERE id = selected_referrer_id;
            
            -- 紹介関係を設定
            UPDATE users 
            SET 
                referral_code = referrer_record.my_referral_code,
                updated_at = NOW()
            WHERE id = user_record.id;
            
            counter := counter + 1;
            
            -- 進捗表示
            IF counter % 20 = 0 THEN
                RAISE NOTICE '進捗: % 人の紹介関係を設定', counter;
            END IF;
        END LOOP;
        
        RAISE NOTICE '✅ % 人のユーザーに紹介関係を設定しました', counter;
    ELSE
        RAISE NOTICE 'ℹ️ 紹介者候補が見つかりませんでした';
    END IF;
END
$$;

-- 紹介関係の統計
SELECT 'referral_statistics' as step;

SELECT 
    '紹介関係統計' as type,
    COUNT(*) as total_users,
    COUNT(referral_code) as users_with_referrer,
    COUNT(my_referral_code) as users_with_own_code,
    ROUND(COUNT(referral_code) * 100.0 / COUNT(*), 1) as referral_percentage
FROM users 
WHERE is_admin = false;

-- 紹介者別の被紹介者数
SELECT 'top_referrers' as step;

SELECT 
    u1.user_id as referrer_user_id,
    u1.name as referrer_name,
    u1.my_referral_code as referral_code,
    COUNT(u2.id) as referred_count
FROM users u1
LEFT JOIN users u2 ON u1.my_referral_code = u2.referral_code
WHERE u1.is_admin = false
GROUP BY u1.id, u1.user_id, u1.name, u1.my_referral_code
HAVING COUNT(u2.id) > 0
ORDER BY referred_count DESC
LIMIT 10;

SELECT '紹介システム修正完了' AS result;
