-- 最終的な認証状況の確認

-- 1. 全体の認証状況
SELECT 
    'Total users' as category,
    COUNT(*) as count
FROM users;

SELECT 
    'Users with auth records' as category,
    COUNT(*) as count
FROM users u
INNER JOIN auth.users au ON u.email = au.email;

SELECT 
    'Users without auth records' as category,
    COUNT(*) as count
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE au.id IS NULL;

-- 2. OHTAKIYO ユーザーの詳細確認
SELECT 
    'OHTAKIYO User Details' as info,
    u.email,
    u.user_id,
    u.name,
    au.id IS NOT NULL as has_auth,
    au.email_confirmed_at IS NOT NULL as email_confirmed
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.user_id = 'OHTAKIYO';

-- 3. 最近作成された認証レコードの確認
SELECT 
    'Recently created auth records' as info,
    COUNT(*) as count
FROM auth.users 
WHERE created_at > NOW() - INTERVAL '1 hour';
