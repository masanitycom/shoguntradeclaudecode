-- 緊急修正: 自己参照と循環参照の解決

-- 1. 自己参照の修正（最も重要）
DO $$
DECLARE
    self_ref_user_id UUID;
    replacement_referrer_id UUID;
BEGIN
    -- 自己参照しているユーザーを特定
    SELECT id INTO self_ref_user_id 
    FROM users 
    WHERE id = referrer_id;
    
    IF self_ref_user_id IS NOT NULL THEN
        -- 代替紹介者を見つける（最も早く登録されたユーザー、自分以外）
        SELECT id INTO replacement_referrer_id
        FROM users 
        WHERE is_admin = false 
          AND id != self_ref_user_id
          AND created_at < (SELECT created_at FROM users WHERE id = self_ref_user_id)
        ORDER BY created_at ASC
        LIMIT 1;
        
        -- 代替紹介者が見つからない場合は、2番目に早いユーザーを使用
        IF replacement_referrer_id IS NULL THEN
            SELECT id INTO replacement_referrer_id
            FROM users 
            WHERE is_admin = false 
              AND id != self_ref_user_id
            ORDER BY created_at ASC
            LIMIT 1 OFFSET 1;
        END IF;
        
        -- 自己参照を修正
        UPDATE users 
        SET referrer_id = replacement_referrer_id,
            updated_at = NOW()
        WHERE id = self_ref_user_id;
        
        RAISE NOTICE 'Fixed self-reference for user ID: %', self_ref_user_id;
    END IF;
END $$;

-- 2. 紹介コードの修正
UPDATE users 
SET my_referral_code = user_id,
    updated_at = NOW()
WHERE my_referral_code IS NULL 
   OR my_referral_code != user_id;

-- 3. 修正結果の確認
SELECT 
    'Emergency Fix Results' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_referrals,
    COUNT(CASE WHEN my_referral_code IS NULL THEN 1 END) as null_referral_codes,
    COUNT(CASE WHEN my_referral_code != user_id THEN 1 END) as incorrect_referral_codes
FROM users 
WHERE is_admin = false;
