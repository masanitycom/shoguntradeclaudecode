-- シンプルな管理者ユーザー作成（Supabase用）

-- 既存ユーザーから管理者を作成する方法
DO $$
DECLARE
    target_user_id UUID;
BEGIN
    -- 最初に作成されたユーザーを管理者にする
    SELECT id INTO target_user_id 
    FROM users 
    WHERE is_admin = false 
    ORDER BY created_at ASC 
    LIMIT 1;
    
    IF target_user_id IS NOT NULL THEN
        -- 管理者権限を付与
        UPDATE users 
        SET 
            is_admin = true,
            user_id = 'admin001',
            name = 'システム管理者',
            updated_at = NOW()
        WHERE id = target_user_id;
        
        RAISE NOTICE '✅ ユーザーID % を管理者に昇格しました', target_user_id;
        RAISE NOTICE 'このユーザーのメールアドレスとパスワードで管理者としてログインできます';
    ELSE
        RAISE NOTICE '❌ 管理者に昇格できるユーザーが見つかりません';
    END IF;
END
$$;

-- 管理者ユーザーの確認
SELECT 
    'admin_users' as type,
    id, 
    name, 
    user_id, 
    email, 
    is_admin,
    created_at
FROM users 
WHERE is_admin = true;

-- 完了メッセージ
SELECT 'シンプル管理者作成完了' AS result;
