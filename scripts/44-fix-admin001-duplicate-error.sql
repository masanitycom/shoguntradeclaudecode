-- admin001の重複エラーを修正

-- 現在の状況を確認
SELECT 'current_admin001_status' as step,
       id, name, user_id, email, is_admin, created_at
FROM users 
WHERE user_id = 'admin001' OR email LIKE '%admin%';

-- admin001が既に存在する場合の修正
DO $$
DECLARE
    existing_admin_record RECORD;
    auth_user_exists BOOLEAN := false;
BEGIN
    -- 既存のadmin001ユーザーを取得
    SELECT * INTO existing_admin_record 
    FROM users 
    WHERE user_id = 'admin001'
    LIMIT 1;
    
    IF existing_admin_record.id IS NOT NULL THEN
        -- 既に存在する場合は管理者権限を確実に付与
        UPDATE users 
        SET 
            is_admin = true,
            name = COALESCE(name, 'システム管理者'),
            updated_at = NOW()
        WHERE user_id = 'admin001';
        
        -- auth.usersテーブルに対応するレコードがあるかチェック
        SELECT EXISTS(
            SELECT 1 FROM auth.users WHERE id = existing_admin_record.id
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
                existing_admin_record.id,
                existing_admin_record.email,
                crypt('admin123456', gen_salt('bf')),
                NOW(),
                existing_admin_record.created_at,
                NOW(),
                '{"provider": "email", "providers": ["email"]}',
                jsonb_build_object(
                    'name', COALESCE(existing_admin_record.name, 'システム管理者'),
                    'user_id', existing_admin_record.user_id,
                    'is_admin', true
                ),
                false,
                'authenticated'
            )
            ON CONFLICT (id) DO UPDATE SET
                email = EXCLUDED.email,
                encrypted_password = EXCLUDED.encrypted_password,
                raw_user_meta_data = EXCLUDED.raw_user_meta_data,
                updated_at = NOW();
            
            RAISE NOTICE '✅ admin001の認証情報を作成しました';
        ELSE
            -- 既存の認証情報を更新
            UPDATE auth.users 
            SET 
                encrypted_password = crypt('admin123456', gen_salt('bf')),
                raw_user_meta_data = jsonb_build_object(
                    'name', COALESCE(existing_admin_record.name, 'システム管理者'),
                    'user_id', existing_admin_record.user_id,
                    'is_admin', true
                ),
                updated_at = NOW()
            WHERE id = existing_admin_record.id;
            
            RAISE NOTICE '✅ admin001の認証情報を更新しました';
        END IF;
        
        RAISE NOTICE 'ℹ️ admin001ユーザーの管理者権限を確認・更新しました';
        
    ELSE
        -- admin001が存在しない場合は新規作成
        INSERT INTO users (
            id,
            name,
            user_id,
            email,
            is_admin,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            'システム管理者',
            'admin001',
            'admin@shogun-trade.com',
            true,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ admin001ユーザーを新規作成しました';
    END IF;
END
$$;

-- 最終確認
SELECT 'final_verification' as step,
       u.id, u.name, u.user_id, u.email, u.is_admin,
       CASE WHEN au.id IS NOT NULL THEN 'auth_exists' ELSE 'auth_missing' END as auth_status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'admin001';

-- 完了メッセージ
SELECT '✅ admin001修正完了 - パスワード: admin123456' AS result;
