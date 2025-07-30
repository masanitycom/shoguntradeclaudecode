-- サトウチヨコ002の正しいauth IDを特定

SELECT '=== FINDING SATO CHIYOKO AUTH ID ===' as section;

-- phu55papa@gmail.com のauth.users確認
SELECT 'phu55papa@gmail.com in auth.users' as search;
SELECT id, email, created_at, last_sign_in_at
FROM auth.users 
WHERE email = 'phu55papa@gmail.com';

-- もしauth.usersにない場合、類似メールを検索
SELECT 'Similar emails in auth.users' as search;
SELECT id, email, created_at
FROM auth.users 
WHERE email LIKE '%phu%' OR email LIKE '%papa%' OR email LIKE '%55%';

-- NYANKO（サトウチヨコのuser_id）で検索
SELECT 'Looking for NYANKO user_id' as search;
SELECT id, name, email, user_id, created_at
FROM users 
WHERE user_id = 'NYANKO';

-- auth.usersで孤立しているIDを確認（public.usersにないもの）
SELECT 'Orphaned auth.users (potential match for Sato)' as search;
SELECT au.id, au.email, au.created_at
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
  AND au.created_at BETWEEN '2025-06-20' AND '2025-06-30'
ORDER BY au.created_at;

-- 作成日時の近いauth.usersを確認
SELECT 'Auth users created around Sato creation date' as search;
SELECT id, email, created_at
FROM auth.users 
WHERE created_at BETWEEN '2025-06-20' AND '2025-06-30'
ORDER BY created_at;