-- 全ユーザーのメール同期問題を修正

-- 1. OHTAKIYOユーザーの修正（auth.usersテーブルを更新）
UPDATE auth.users 
SET 
    email = '2kiyoji1948@gmail.com',
    updated_at = now()
WHERE id = 'd8c1b7a2-20ea-4991-a296-00a090a36e41';

-- 2. 他の不整合ユーザーの確認と修正準備
DO $$
DECLARE
    user_record RECORD;
    missing_count INTEGER := 0;
BEGIN
    -- auth.usersに存在しないユーザーをカウント
    FOR user_record IN 
        SELECT u.id, u.name, u.user_id, u.email
        FROM users u
        LEFT JOIN auth.users au ON u.id = au.id
        WHERE au.id IS NULL
        AND u.user_id IN ('PINK', 'Eiko86', 'syake', 'ys0888', 'UUUUU5', 'rinn361', '0820KMP', 'FU3111', 'Pin', 'chantillyrushe')
    LOOP
        missing_count := missing_count + 1;
        RAISE NOTICE 'Missing auth user: % (%) - %', user_record.user_id, user_record.name, user_record.email;
    END LOOP;
    
    RAISE NOTICE 'Total missing auth users: %', missing_count;
END $$;

-- 3. 修正結果確認
SELECT 
    u.name,
    u.user_id,
    u.email as users_email,
    au.email as auth_email,
    CASE 
        WHEN u.email = au.email THEN '同期完了'
        WHEN au.email IS NULL THEN '認証情報なし'
        ELSE '不一致'
    END as sync_status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id IN ('OHTAKIYO', 'PINK', 'Eiko86', 'syake', 'ys0888', 'UUUUU5', 'rinn361', '0820KMP', 'FU3111', 'Pin', 'chantillyrushe')
ORDER BY u.user_id;
