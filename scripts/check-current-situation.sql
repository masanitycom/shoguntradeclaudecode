-- 現在の状況を詳細確認

SELECT '=== CURRENT SITUATION ANALYSIS ===' as section;

-- 現在存在するusersレコード確認
SELECT 'Current users records:' as info;
SELECT 
    id, name, email, user_id, created_at
FROM users 
WHERE id IN (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    '53b6f22b-5348-4fe2-a969-b522655e8a4a',
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    '00000000-0000-0000-0000-000000000001'
)
ORDER BY created_at;

-- user_rank_historyで参照されているuser_id確認
SELECT 'user_rank_history references:' as rank_refs;
SELECT DISTINCT user_id, COUNT(*) as record_count
FROM user_rank_history 
WHERE user_id IN (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    '53b6f22b-5348-4fe2-a969-b522655e8a4a',
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    '00000000-0000-0000-0000-000000000001'
)
GROUP BY user_id;

-- NFTデータの現在の状況
SELECT 'Current NFT ownership:' as nft_status;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id IN (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    '53b6f22b-5348-4fe2-a969-b522655e8a4a',
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    '00000000-0000-0000-0000-000000000001'
)
ORDER BY un.user_id;

-- auth.usersの状況確認
SELECT 'auth.users status:' as auth_status;
SELECT 
    id, email, created_at
FROM auth.users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
ORDER BY email;