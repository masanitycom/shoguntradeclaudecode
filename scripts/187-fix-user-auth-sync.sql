-- auth.usersに存在するがpublic.usersに存在しないユーザーのpublic.usersレコードを作成

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

-- 2. auth.usersに存在するがpublic.usersに存在しないユーザーのpublic.usersレコードを作成
DO $$
DECLARE
    auth_user RECORD;
    user_counter INTEGER := 1;
BEGIN
    -- auth.usersに存在するがpublic.usersに存在しないユーザーを取得
    FOR auth_user IN 
        SELECT au.id, au.email, au.created_at
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.id
        WHERE pu.id IS NULL
    LOOP
        -- public.usersレコードを作成
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
            'USER' || LPAD(user_counter::text, 3, '0'),
            '',
            'REF' || UPPER(substring(md5(auth_user.id::text) from 1 for 8)),
            'https://shogun-trade.vercel.app/register?ref=' || 'REF' || UPPER(substring(md5(auth_user.id::text) from 1 for 8)),
            auth_user.created_at,
            NOW(),
            false
        ) ON CONFLICT (id) DO NOTHING;
        
        user_counter := user_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Created % public.users records', user_counter - 1;
END $$;

-- 3. 結果確認
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
