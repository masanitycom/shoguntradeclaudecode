-- 手動で重要な紹介関係を修正

-- 1. まず1125RitsukoをUSER0a18の紹介下に正しく配置
DO $$
DECLARE
    ritsuko_id UUID;
    user0a18_id UUID;
    user0a18_created TIMESTAMP WITH TIME ZONE;
    ritsuko_created TIMESTAMP WITH TIME ZONE;
BEGIN
    -- UUIDを取得
    SELECT id, created_at INTO ritsuko_id, ritsuko_created 
    FROM users WHERE user_id = '1125Ritsuko';
    
    SELECT id, created_at INTO user0a18_id, user0a18_created 
    FROM users WHERE user_id = 'USER0a18';
    
    -- 両方のユーザーが存在し、日付が論理的に正しいかチェック
    IF ritsuko_id IS NOT NULL AND user0a18_id IS NOT NULL THEN
        IF user0a18_created < ritsuko_created THEN
            -- 1125RitsukoをUSER0a18の紹介下に配置
            UPDATE users 
            SET referrer_id = user0a18_id,
                updated_at = NOW()
            WHERE id = ritsuko_id;
            
            RAISE NOTICE '1125Ritsuko referrer set to USER0a18';
        ELSE
            RAISE NOTICE 'Date conflict: USER0a18 created after 1125Ritsuko';
        END IF;
    ELSE
        RAISE NOTICE 'One or both users not found';
    END IF;
END $$;

-- 2. 現在1125Ritsukoを紹介者としているユーザーを適切に再配置
-- これらのユーザーを時系列順に適切な紹介者に再配置
WITH misplaced_users AS (
    SELECT 
        u.id,
        u.user_id,
        u.name,
        u.created_at,
        -- より適切な紹介者を見つける（1125Ritsukoより前に登録された人）
        (SELECT id 
         FROM users potential_ref 
         WHERE potential_ref.is_admin = false
           AND potential_ref.created_at < u.created_at
           AND potential_ref.user_id != '1125Ritsuko'  -- 1125Ritsukoは除外
           AND potential_ref.id != u.id
         ORDER BY potential_ref.created_at DESC
         LIMIT 1) as new_referrer_id
    FROM users u
    JOIN users ref ON u.referrer_id = ref.id
    WHERE ref.user_id = '1125Ritsuko'
      AND u.is_admin = false
)
UPDATE users 
SET referrer_id = misplaced_users.new_referrer_id,
    updated_at = NOW()
FROM misplaced_users
WHERE users.id = misplaced_users.id
  AND misplaced_users.new_referrer_id IS NOT NULL;

-- 3. 修正結果の確認
SELECT 
    'Manual Fix Results' as check_type,
    'After manual correction' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_referrals
FROM users 
WHERE is_admin = false;

-- 4. 1125Ritsukoの現在の状況
SELECT 
    'Ritsuko Current Status' as check_type,
    u.user_id,
    u.name,
    ref.user_id as referrer_code,
    ref.name as referrer_name,
    COUNT(referred.id) as current_referral_count
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
WHERE u.user_id = '1125Ritsuko'
GROUP BY u.id, u.user_id, u.name, ref.user_id, ref.name;
