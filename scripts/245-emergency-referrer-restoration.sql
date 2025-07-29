-- 緊急：紹介者データの復元

-- 1. auth.usersのメタデータから紹介者情報を復元
DO $$
DECLARE
    user_record RECORD;
    referrer_user_id TEXT;
    referrer_id UUID;
BEGIN
    -- auth.usersのメタデータに紹介者情報があるユーザーを処理
    FOR user_record IN 
        SELECT 
            au.id,
            pu.user_id,
            au.raw_user_meta_data->>'referrer_id' as auth_referrer_id,
            au.raw_user_meta_data->>'ref' as auth_ref
        FROM auth.users au
        JOIN public.users pu ON au.id = pu.id
        WHERE pu.referrer_id IS NULL 
          AND pu.is_admin = false
          AND (au.raw_user_meta_data->>'referrer_id' IS NOT NULL 
               OR au.raw_user_meta_data->>'ref' IS NOT NULL)
    LOOP
        -- 紹介者IDを特定
        referrer_user_id := COALESCE(user_record.auth_referrer_id, user_record.auth_ref);
        
        IF referrer_user_id IS NOT NULL THEN
            -- 紹介者のUUIDを取得
            SELECT id INTO referrer_id 
            FROM users 
            WHERE user_id = referrer_user_id 
            LIMIT 1;
            
            IF referrer_id IS NOT NULL THEN
                -- 紹介者を設定
                UPDATE users 
                SET referrer_id = referrer_id
                WHERE id = user_record.id;
                
                RAISE NOTICE 'Restored referrer for user %: %', user_record.user_id, referrer_user_id;
            END IF;
        END IF;
    END LOOP;
END $$;

-- 2. 登録時期による推測復元（同じ時間帯に登録されたユーザー）
DO $$
DECLARE
    user_record RECORD;
    potential_referrer_id UUID;
BEGIN
    -- 紹介者がいないユーザーを時系列で処理
    FOR user_record IN 
        SELECT id, user_id, created_at
        FROM users 
        WHERE referrer_id IS NULL 
          AND is_admin = false
          AND created_at > '2025-06-21 00:00:00'
        ORDER BY created_at
    LOOP
        -- 直前に登録されたユーザーを紹介者候補とする
        SELECT id INTO potential_referrer_id
        FROM users 
        WHERE created_at < user_record.created_at
          AND created_at > user_record.created_at - INTERVAL '1 hour'
          AND is_admin = false
        ORDER BY created_at DESC
        LIMIT 1;
        
        IF potential_referrer_id IS NOT NULL THEN
            UPDATE users 
            SET referrer_id = potential_referrer_id
            WHERE id = user_record.id;
            
            RAISE NOTICE 'Set potential referrer for user %', user_record.user_id;
        END IF;
    END LOOP;
END $$;

-- 3. 残りのユーザーに最初の有効なユーザーを紹介者として設定
DO $$
DECLARE
    first_valid_user_id UUID;
BEGIN
    -- 最初の有効なユーザーを取得
    SELECT id INTO first_valid_user_id
    FROM users 
    WHERE is_admin = false
      AND created_at < '2025-06-22 00:00:00'
    ORDER BY created_at
    LIMIT 1;
    
    IF first_valid_user_id IS NOT NULL THEN
        -- 残りの紹介者なしユーザーに設定
        UPDATE users 
        SET referrer_id = first_valid_user_id
        WHERE referrer_id IS NULL 
          AND is_admin = false;
          
        RAISE NOTICE 'Set default referrer for remaining users';
    END IF;
END $$;

-- 4. 復元結果の確認
SELECT 
  'Restoration Results' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
  COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as users_without_referrer,
  ROUND(COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as referrer_percentage
FROM users 
WHERE is_admin = false;
