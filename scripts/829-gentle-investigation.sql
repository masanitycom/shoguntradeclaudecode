-- 優しい調査：何も変更せず、現状を理解する

SELECT '=== やさしい現状確認（変更なし） ===' as section;

-- 1. まず全体の数を把握
SELECT '全体の状況:' as info;
SELECT 
    '総ユーザー数' as 項目,
    COUNT(*) as 数
FROM users
UNION ALL
SELECT 
    'NFTを持っているユーザー数' as 項目,
    COUNT(DISTINCT user_id) as 数
FROM user_nfts 
WHERE is_active = true
UNION ALL
SELECT 
    'NFTを持っていないユーザー数' as 項目,
    (SELECT COUNT(*) FROM users) - COUNT(DISTINCT user_id) as 数
FROM user_nfts 
WHERE is_active = true;

-- 2. 明らかに実在する人の名前のユーザー（安全）
SELECT '実在する人名のユーザー（保護対象）:' as info;
SELECT 
    u.name,
    u.email,
    u.user_id,
    CASE WHEN un.user_id IS NOT NULL THEN 'NFTあり' ELSE 'NFTなし' END as nft_status,
    u.created_at
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.name ~ '^[ア-ン]{2,}[ア-ン]{2,}$'  -- 日本人の名前パターン
   OR u.name LIKE '%田%' 
   OR u.name LIKE '%山%'
   OR u.name LIKE '%川%'
   OR u.name LIKE '%井%'
   OR u.name LIKE '%木%'
ORDER BY u.created_at;

-- 3. 明らかにテストっぽい名前（慎重に確認）
SELECT '明らかにテストっぽい名前:' as info;
SELECT 
    u.name,
    u.email,
    u.user_id,
    u.phone,
    u.created_at
FROM users u
WHERE u.name LIKE 'ユーザー%'
   OR u.name LIKE '%UP'
   OR u.name LIKE 'テスト%'
   OR u.phone = '000-0000-0000'
ORDER BY u.created_at
LIMIT 5;  -- 少しだけ表示

-- 4. _authの問題を理解する
SELECT '_auth問題の詳細:' as info;
SELECT 
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    '実ユーザーの可能性がある' as 注意
FROM users u
WHERE u.user_id LIKE '%_auth%'
ORDER BY u.created_at;

SELECT '=== 現状確認完了（何も変更していません） ===' as status;