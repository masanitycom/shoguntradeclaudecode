-- auth.usersに存在するがpublic.usersに存在しないユーザーのpublic.usersレコードを作成（修正版）

-- 1. admin001のauth.usersレコードを作成（既存のpublic.usersレコードに合わせる）
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '87654321-4321-4321-4321-210987654321',
  'admin@shogun-trade.com',
  crypt('admin123456', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
) ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  encrypted_password = EXCLUDED.encrypted_password,
  updated_at = NOW();

-- 2. まず、重複するメールアドレスを確認
SELECT 
    'Duplicate emails in public.users' as issue,
    email,
    COUNT(*) as count
FROM public.users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- 3. auth.usersとpublic.usersの不一致を詳細確認
WITH auth_users_list AS (
    SELECT id, email FROM auth.users
),
public_users_list AS (
    SELECT id, email FROM public.users
),
missing_in_public AS (
    SELECT au.id, au.email
    FROM auth_users_list au
    LEFT JOIN public_users_list pu ON au.id = pu.id
    WHERE pu.id IS NULL
),
email_conflicts AS (
    SELECT 
        mip.id as auth_id,
        mip.email,
        pu.id as existing_public_id
    FROM missing_in_public mip
    INNER JOIN public_users_list pu ON mip.email = pu.email
)
SELECT 
    'Email conflicts' as issue,
    auth_id,
    email,
    existing_public_id
FROM email_conflicts;

-- 4. 重複メールアドレスの問題を解決するため、既存のpublic.usersレコードのIDを更新
DO $$
DECLARE
    auth_user RECORD;
    existing_public_user RECORD;
    user_counter INTEGER := 1;
    new_user_id TEXT;
BEGIN
    -- auth.usersに存在するがpublic.usersに存在しないユーザーを処理
    FOR auth_user IN 
        SELECT au.id, au.email, au.created_at
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.id
        WHERE pu.id IS NULL
    LOOP
        -- 同じメールアドレスのpublic.usersレコードが存在するかチェック
        SELECT * INTO existing_public_user
        FROM public.users 
        WHERE email = auth_user.email
        LIMIT 1;
        
        IF existing_public_user.id IS NOT NULL THEN
            -- 既存のpublic.usersレコードのIDをauth.usersのIDに更新
            RAISE NOTICE 'Updating existing public.users record for email: % from ID % to %', 
                auth_user.email, existing_public_user.id, auth_user.id;
            
            -- 関連テーブルのIDも更新
            UPDATE user_nfts SET user_id = auth_user.id WHERE user_id = existing_public_user.id;
            UPDATE daily_rewards SET user_id = auth_user.id WHERE user_id = existing_public_user.id;
            UPDATE reward_applications SET user_id = auth_user.id WHERE user_id = existing_public_user.id;
            UPDATE nft_purchase_applications SET user_id = auth_user.id WHERE user_id = existing_public_user.id;
            UPDATE user_rank_history SET user_id = auth_user.id WHERE user_id = existing_public_user.id;
            UPDATE tenka_bonus_distributions SET user_id = auth_user.id WHERE user_id = existing_public_user.id;
            
            -- 紹介関係も更新
            UPDATE users SET referrer_id = auth_user.id WHERE referrer_id = existing_public_user.id;
            
            -- 最後にpublic.usersのIDを更新
            UPDATE users SET id = auth_user.id WHERE id = existing_public_user.id;
            
        ELSE
            -- 新しいpublic.usersレコードを作成
            new_user_id := 'USER' || LPAD(user_counter::text, 3, '0');
            
            -- user_idの重複チェック
            WHILE EXISTS (SELECT 1 FROM users WHERE user_id = new_user_id) LOOP
                user_counter := user_counter + 1;
                new_user_id := 'USER' || LPAD(user_counter::text, 3, '0');
            END LOOP;
            
            INSERT INTO public.users (
                id,
                name,
                email,
                user_id,
                phone,
                my_referral_code,
                referral_link,
                created_at,
                updated_at,
                is_admin
            ) VALUES (
                auth_user.id,
                COALESCE(split_part(auth_user.email, '@', 1), 'User' || user_counter),
                auth_user.email,
                new_user_id,
                '',
                'REF' || UPPER(substring(md5(auth_user.id::text) from 1 for 8)),
                'https://shogun-trade.vercel.app/register?ref=' || 'REF' || UPPER(substring(md5(auth_user.id::text) from 1 for 8)),
                auth_user.created_at,
                NOW(),
                false
            );
            
            RAISE NOTICE 'Created new public.users record for: % with user_id: %', 
                auth_user.email, new_user_id;
        END IF;
        
        user_counter := user_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Processing completed';
END $$;

-- 5. 結果確認
SELECT 
    'auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'public.users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'matched_records' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id;

-- 6. 残りの不一致を確認
SELECT 
    'auth_only' as type,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
UNION ALL
SELECT 
    'public_only' as type,
    COUNT(*) as count
FROM public.users pu
LEFT JOIN auth.users au ON pu.id = au.id
WHERE au.id IS NULL;
