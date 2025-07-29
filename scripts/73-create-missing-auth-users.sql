-- 認証情報が欠落しているユーザーの修正
-- 注意: これらのユーザーは管理者がパスワードリセットを行う必要があります

DO $$
DECLARE
    user_record RECORD;
    temp_password TEXT := 'TempPass123!';
BEGIN
    -- 認証情報が欠落しているユーザーに対して一時的な認証情報を作成
    FOR user_record IN 
        SELECT u.id, u.name, u.user_id, u.email
        FROM users u
        LEFT JOIN auth.users au ON u.id = au.id
        WHERE au.id IS NULL
        AND u.user_id IN ('PINK', 'Eiko86', 'syake', 'ys0888', 'UUUUU5', 'rinn361', '0820KMP', 'FU3111', 'Pin', 'chantillyrushe')
    LOOP
        -- auth.usersテーブルに挿入
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
            user_record.id,
            user_record.email,
            crypt(temp_password, gen_salt('bf')),
            now(),
            now(),
            now(),
            '',
            '',
            '',
            ''
        );
        
        RAISE NOTICE 'Created auth user for: % (%) - %', user_record.user_id, user_record.name, user_record.email;
    END LOOP;
END $$;

-- 最終確認
SELECT 
    u.name,
    u.user_id,
    u.email,
    CASE 
        WHEN au.id IS NOT NULL THEN '認証情報あり'
        ELSE '認証情報なし'
    END as auth_status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id IN ('OHTAKIYO', 'PINK', 'Eiko86', 'syake', 'ys0888', 'UUUUU5', 'rinn361', '0820KMP', 'FU3111', 'Pin', 'chantillyrushe')
ORDER BY u.user_id;
