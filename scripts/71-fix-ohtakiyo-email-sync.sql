-- OHTAKIYOユーザーのメールアドレス同期を修正

-- まず、OHTAKIYOユーザーの現在のメールアドレスを確認
DO $$
DECLARE
    user_record RECORD;
    auth_user_id UUID;
BEGIN
    -- usersテーブルからOHTAKIYOユーザーの情報を取得
    SELECT * INTO user_record FROM users WHERE user_id = 'OHTAKIYO';
    
    IF user_record IS NOT NULL THEN
        -- auth.usersテーブルでこのユーザーのIDを検索
        SELECT id INTO auth_user_id FROM auth.users WHERE id = user_record.id;
        
        IF auth_user_id IS NOT NULL THEN
            -- auth.usersテーブルのメールアドレスを更新
            UPDATE auth.users 
            SET 
                email = user_record.email,
                updated_at = now()
            WHERE id = user_record.id;
            
            RAISE NOTICE 'Updated auth.users email for OHTAKIYO to: %', user_record.email;
        ELSE
            RAISE NOTICE 'Auth user not found for OHTAKIYO';
        END IF;
    ELSE
        RAISE NOTICE 'OHTAKIYO user not found in users table';
    END IF;
END $$;

-- 結果確認
SELECT 
    u.name,
    u.user_id,
    u.email as users_email,
    au.email as auth_email,
    CASE 
        WHEN u.email = au.email THEN '同期完了'
        ELSE '同期失敗'
    END as sync_status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'OHTAKIYO';
