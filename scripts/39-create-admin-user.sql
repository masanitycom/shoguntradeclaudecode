-- 管理者ユーザーの作成

-- 既存の管理者ユーザーを確認
SELECT 'existing_admin_check' as step, id, name, user_id, email, is_admin 
FROM users 
WHERE is_admin = true;

-- admin001ユーザーが存在するかチェック
DO $$
DECLARE
    admin_user_id UUID;
    admin_email TEXT := 'admin@shogun-trade.com';
    admin_password TEXT := 'admin123456'; -- 本番では強力なパスワードに変更
BEGIN
    -- admin001ユーザーが既に存在するかチェック
    SELECT id INTO admin_user_id 
    FROM users 
    WHERE user_id = 'admin001' OR email = admin_email;
    
    IF admin_user_id IS NOT NULL THEN
        -- 既存ユーザーを管理者に昇格
        UPDATE users 
        SET is_admin = true, updated_at = NOW()
        WHERE id = admin_user_id;
        
        RAISE NOTICE '✅ 既存ユーザー admin001 を管理者に昇格しました';
    ELSE
        -- 新しい管理者ユーザーを作成
        -- まずauth.usersテーブルに挿入（Supabase認証用）
        INSERT INTO auth.users (
            id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_app_meta_data,
            raw_user_meta_data,
            is_super_admin,
            role
        ) VALUES (
            gen_random_uuid(),
            admin_email,
            crypt(admin_password, gen_salt('bf')), -- パスワードハッシュ化
            NOW(),
            NOW(),
            NOW(),
            '{"provider": "email", "providers": ["email"]}',
            '{"name": "システム管理者", "user_id": "admin001"}',
            false,
            'authenticated'
        )
        ON CONFLICT (email) DO NOTHING;
        
        -- usersテーブルに管理者情報を挿入
        INSERT INTO users (
            id,
            name,
            email,
            user_id,
            my_referral_code,
            referral_link,
            is_admin,
            created_at,
            updated_at
        ) 
        SELECT 
            au.id,
            'システム管理者',
            admin_email,
            'admin001',
            'ADMIN001',
            'https://shogun-trade.com/register?ref=ADMIN001',
            true,
            NOW(),
            NOW()
        FROM auth.users au 
        WHERE au.email = admin_email
        ON CONFLICT (id) DO UPDATE SET
            is_admin = true,
            updated_at = NOW();
        
        RAISE NOTICE '✅ 新しい管理者ユーザー admin001 を作成しました';
        RAISE NOTICE 'ログイン情報:';
        RAISE NOTICE 'ユーザーID: admin001';
        RAISE NOTICE 'メール: %', admin_email;
        RAISE NOTICE 'パスワード: %', admin_password;
    END IF;
END
$$;

-- 管理者ユーザー作成後の確認
SELECT 'admin_user_created' as step, id, name, user_id, email, is_admin, created_at
FROM users 
WHERE is_admin = true;

-- 完了メッセージ
SELECT '管理者ユーザーの作成/更新が完了しました' AS result;
