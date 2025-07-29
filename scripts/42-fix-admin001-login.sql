-- admin001ユーザーのログイン問題を修正

-- 現在のadmin001ユーザーの状態を確認
SELECT 'admin001_current_status' as step, 
       id, name, user_id, email, is_admin, created_at
FROM users 
WHERE user_id = 'admin001' OR is_admin = true;

-- admin001ユーザーが存在するが認証情報がない場合の修正
DO $$
DECLARE
    admin_user_record RECORD;
    auth_user_exists BOOLEAN := false;
BEGIN
    -- admin001ユーザーを取得
    SELECT * INTO admin_user_record 
    FROM users 
    WHERE user_id = 'admin001' AND is_admin = true
    LIMIT 1;
    
    IF admin_user_record.id IS NOT NULL THEN
        -- auth.usersテーブルに対応するレコードがあるかチェック
        SELECT EXISTS(
            SELECT 1 FROM auth.users WHERE id = admin_user_record.id
        ) INTO auth_user_exists;
        
        IF NOT auth_user_exists THEN
            -- auth.usersテーブルにレコードを作成
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
                admin_user_record.id,
                admin_user_record.email,
                crypt('admin123456', gen_salt('bf')), -- デフォルトパスワード
                NOW(),
                admin_user_record.created_at,
                NOW(),
                '{"provider": "email", "providers": ["email"]}',
                jsonb_build_object(
                    'name', admin_user_record.name,
                    'user_id', admin_user_record.user_id,
                    'is_admin', true
                ),
                false,
                'authenticated'
            )
            ON CONFLICT (id) DO UPDATE SET
                email = EXCLUDED.email,
                raw_user_meta_data = EXCLUDED.raw_user_meta_data,
                updated_at = NOW();
            
            RAISE NOTICE '✅ admin001の認証情報を作成しました';
            RAISE NOTICE 'ログイン情報:';
            RAISE NOTICE 'ユーザーID: admin001';
            RAISE NOTICE 'メール: %', admin_user_record.email;
            RAISE NOTICE 'パスワード: admin123456';
        ELSE
            RAISE NOTICE 'ℹ️ admin001の認証情報は既に存在します';
        END IF;
    ELSE
        RAISE NOTICE '❌ admin001ユーザーが見つかりません';
    END IF;
END
$$;

-- 最終確認
SELECT 'final_admin_check' as step,
       u.id, u.name, u.user_id, u.email, u.is_admin,
       CASE WHEN au.id IS NOT NULL THEN 'auth_exists' ELSE 'auth_missing' END as auth_status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'admin001' AND u.is_admin = true;

-- 完了メッセージ
SELECT 'admin001ログイン修正完了' AS result;
