-- 何が起きたのか詳細確認

SELECT '=== WHAT HAPPENED INVESTIGATION ===' as section;

-- 現在のusersテーブルの状況
SELECT 'Current users table status:' as check_type;
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

-- kappystone.516@gmail.com のレコードを探す
SELECT 'Search for kappystone.516@gmail.com:' as search_kappystone;
SELECT 
    id, name, email, user_id, created_at
FROM users 
WHERE email LIKE '%kappystone%' 
   OR name LIKE '%イシジマ%' 
   OR user_id = 'PHULIKE';

-- NFTデータの現在の所有者
SELECT 'NFT ownership status:' as nft_status;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
  AND (un.current_investment::numeric = 4000 OR un.current_investment::numeric = 100)
ORDER BY un.current_investment DESC;

-- user_rank_historyの状況
SELECT 'user_rank_history status:' as rank_history;
SELECT DISTINCT 
    user_id,
    COUNT(*) as records
FROM user_rank_history
WHERE user_id IN (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    '53b6f22b-5348-4fe2-a969-b522655e8a4a',
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    '00000000-0000-0000-0000-000000000001'
)
GROUP BY user_id;

-- 一時レコードの詳細
SELECT 'Temporary records details:' as temp_details;
SELECT 
    id, name, email, user_id
FROM users 
WHERE email LIKE '%temp%' OR user_id LIKE '%TEMP%' OR name LIKE '%temp%';