-- admin001の認証情報を完全修正

-- 現在の状況確認
SELECT 'current_auth_status' as step;

SELECT 
    'users_table' as source,
    id, name, user_id, email, is_admin
FROM users 
WHERE user_id = 'admin001';

SELECT 
    'auth_users_table' as source,
    id, email, encrypted_password IS NOT NULL as has_password, email_confirmed_at
FROM auth.users 
WHERE email = 'admin@shogun-trade.com';

-- 認証情報の完全修正
DO $$
DECLARE
    admin_record RECORD;
BEGIN
    -- admin001ユーザー情報を取得
    SELECT * INTO admin_record 
    FROM users 
    WHERE user_id = 'admin001' 
    LIMIT 1;
    
    IF admin_record.id IS NOT NULL THEN
        RAISE NOTICE 'admin001ユーザー発見: %', admin_record.id;
        
        -- 既存の認証情報を削除（クリーンアップ）
        DELETE FROM auth.users WHERE email = 'admin@shogun-trade.com';
        RAISE NOTICE '既存の認証情報を削除しました';
        
        -- 新しい認証情報を作成
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            confirmation_sent_at,
            confirmation_token,
            recovery_sent_at,
            recovery_token,
            email_change_sent_at,
            email_change,
            email_change_token_new,
            email_change_token_current,
            created_at,
            updated_at,
            raw_app_meta_data,
            raw_user_meta_data,
            is_super_admin,
            role,
            aud,
            phone_confirmed_at,
            phone_change_sent_at,
            phone_change,
            phone_change_token,
            email_change_confirm_status,
            banned_until,
            reauthentication_sent_at,
            reauthentication_token,
            is_sso_user,
            deleted_at
        ) VALUES (
            admin_record.id,
            '00000000-0000-0000-0000-000000000000',
            admin_record.email,
            crypt('admin123456', gen_salt('bf')),
            NOW(),
            NOW(),
            '',
            NULL,
            '',
            NULL,
            '',
            '',
            '',
            admin_record.created_at,
            NOW(),
            '{"provider": "email", "providers": ["email"]}',
            jsonb_build_object(
                'name', admin_record.name,
                'user_id', admin_record.user_id,
                'is_admin', true
            ),
            false,
            'authenticated',
            'authenticated',
            NULL,
            NULL,
            '',
            '',
            0,
            NULL,
            NULL,
            '',
            false,
            NULL
        );
        
        RAISE NOTICE '✅ 新しい認証情報を作成しました';
        
        -- usersテーブルも確実に更新
        UPDATE users 
        SET 
            is_admin = true,
            name = COALESCE(name, 'システム管理者'),
            updated_at = NOW()
        WHERE id = admin_record.id;
        
        RAISE NOTICE '✅ ユーザー情報を更新しました';
        
    ELSE
        RAISE EXCEPTION 'admin001ユーザーが見つかりません';
    END IF;
END
$$;

-- 認証情報の検証
SELECT 'verification' as step;

SELECT 
    u.user_id,
    u.email,
    u.is_admin,
    au.email as auth_email,
    au.encrypted_password IS NOT NULL as has_encrypted_password,
    au.email_confirmed_at IS NOT NULL as email_confirmed,
    au.role as auth_role
FROM users u
JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'admin001';

-- パスワード検証テスト
SELECT 
    'password_test' as step,
    CASE 
        WHEN encrypted_password = crypt('admin123456', encrypted_password) 
        THEN '✅ パスワード正常'
        ELSE '❌ パスワード異常'
    END as password_status
FROM auth.users 
WHERE email = 'admin@shogun-trade.com';

SELECT '🎉 admin001認証修正完了 - ログイン可能' AS result;
