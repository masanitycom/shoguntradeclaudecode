-- admin001の安全な修正（重複エラー回避）

-- 現在の状況を詳細確認
SELECT 'current_situation' as step;

-- usersテーブルの状況
SELECT 'users_table' as type, id, name, user_id, email, is_admin 
FROM users 
WHERE user_id = 'admin001' OR email = 'admin@shogun-trade.com' OR is_admin = true;

-- auth.usersテーブルの状況
SELECT 'auth_users_table' as type, id, email, email_confirmed_at
FROM auth.users 
WHERE email = 'admin@shogun-trade.com';

-- 安全な修正処理
DO $$
DECLARE
    admin_user_record RECORD;
    auth_user_record RECORD;
BEGIN
    -- admin001ユーザーを取得
    SELECT * INTO admin_user_record 
    FROM users 
    WHERE user_id = 'admin001'
    LIMIT 1;
    
    -- admin@shogun-trade.comの認証情報を取得
    SELECT * INTO auth_user_record 
    FROM auth.users 
    WHERE email = 'admin@shogun-trade.com'
    LIMIT 1;
    
    IF admin_user_record.id IS NOT NULL THEN
        -- admin001ユーザーが存在する場合
        RAISE NOTICE 'admin001ユーザーが存在します: %', admin_user_record.id;
        
        -- 管理者権限を確実に付与
        UPDATE users 
        SET 
            is_admin = true,
            name = COALESCE(name, 'システム管理者'),
            updated_at = NOW()
        WHERE id = admin_user_record.id;
        
        IF auth_user_record.id IS NOT NULL THEN
            -- 認証情報が存在する場合
            IF auth_user_record.id = admin_user_record.id THEN
                -- 同じIDの場合は更新
                UPDATE auth.users 
                SET 
                    encrypted_password = crypt('admin123456', gen_salt('bf')),
                    raw_user_meta_data = jsonb_build_object(
                        'name', COALESCE(admin_user_record.name, 'システム管理者'),
                        'user_id', admin_user_record.user_id,
                        'is_admin', true
                    ),
                    updated_at = NOW()
                WHERE id = admin_user_record.id;
                
                RAISE NOTICE '✅ 既存の認証情報を更新しました';
            ELSE
                -- 異なるIDの場合は古い認証情報を削除して新規作成
                DELETE FROM auth.users WHERE email = 'admin@shogun-trade.com';
                
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
                    crypt('admin123456', gen_salt('bf')),
                    NOW(),
                    admin_user_record.created_at,
                    NOW(),
                    '{"provider": "email", "providers": ["email"]}',
                    jsonb_build_object(
                        'name', COALESCE(admin_user_record.name, 'システム管理者'),
                        'user_id', admin_user_record.user_id,
                        'is_admin', true
                    ),
                    false,
                    'authenticated'
                );
                
                RAISE NOTICE '✅ 古い認証情報を削除して新規作成しました';
            END IF;
        ELSE
            -- 認証情報が存在しない場合は新規作成
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
                crypt('admin123456', gen_salt('bf')),
                NOW(),
                admin_user_record.created_at,
                NOW(),
                '{"provider": "email", "providers": ["email"]}',
                jsonb_build_object(
                    'name', COALESCE(admin_user_record.name, 'システム管理者'),
                    'user_id', admin_user_record.user_id,
                    'is_admin', true
                ),
                false,
                'authenticated'
            );
            
            RAISE NOTICE '✅ 新しい認証情報を作成しました';
        END IF;
        
    ELSE
        -- admin001ユーザーが存在しない場合
        RAISE NOTICE 'admin001ユーザーが存在しません。最初のユーザーを管理者に昇格させます';
        
        -- 最初のユーザーを管理者に昇格
        UPDATE users 
        SET 
            is_admin = true,
            user_id = 'admin001',
            name = 'システム管理者',
            updated_at = NOW()
        WHERE id = (
            SELECT id FROM users 
            WHERE is_admin = false 
            ORDER BY created_at ASC 
            LIMIT 1
        );
        
        RAISE NOTICE '✅ 最初のユーザーをadmin001に昇格しました';
    END IF;
END
$$;

-- 最終確認
SELECT 'final_check' as step;

SELECT 
    'admin_user_final' as type,
    u.id, 
    u.name, 
    u.user_id, 
    u.email, 
    u.is_admin,
    CASE WHEN au.id IS NOT NULL THEN 'auth_exists' ELSE 'auth_missing' END as auth_status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'admin001' OR u.is_admin = true;

-- 完了メッセージ
SELECT '✅ admin001安全修正完了 - ログイン可能' AS result;
