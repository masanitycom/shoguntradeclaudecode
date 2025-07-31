-- _lcサフィックス付き重複アカウントの一括削除

SELECT '=== _lcサフィックス重複アカウント削除 ===' as section;

-- 1. _lcサフィックス付きアカウントの確認
SELECT '_lcサフィックス付きアカウント確認:' as check_lc;
SELECT 
    COUNT(*) as total_lc_accounts
FROM users
WHERE user_id LIKE '%_lc';

-- 2. 対応する正規アカウントが存在する_lcアカウントのみ削除対象として特定
SELECT '削除対象の_lcアカウント:' as deletion_targets;
SELECT 
    lc.id,
    lc.name,
    lc.user_id as lc_user_id,
    lc.email as lc_email,
    reg.user_id as regular_user_id,
    reg.email as regular_email,
    '削除対象' as action
FROM users lc
JOIN users reg ON (
    lc.name = reg.name 
    AND reg.user_id = REPLACE(lc.user_id, '_lc', '')
)
WHERE lc.user_id LIKE '%_lc'
ORDER BY lc.name;

-- 3. _lcアカウントにNFTが付与されている場合の確認
SELECT '_lcアカウントのNFT確認:' as nft_check;
SELECT 
    u.name,
    u.user_id,
    COUNT(un.id) as nft_count
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.user_id LIKE '%_lc'
GROUP BY u.id, u.name, u.user_id
HAVING COUNT(un.id) > 0;

-- 4. 安全な削除実行（NFTを持たない_lcアカウントで、対応する正規アカウントが存在するもの）
SELECT '_lcアカウント削除実行中...' as deletion;
DELETE FROM users 
WHERE user_id LIKE '%_lc'
  AND id NOT IN (
    SELECT DISTINCT un.user_id 
    FROM user_nfts un 
    WHERE un.is_active = true
  )
  AND EXISTS (
    SELECT 1 FROM users reg 
    WHERE reg.name = users.name 
      AND reg.user_id = REPLACE(users.user_id, '_lc', '')
  );

-- 5. 削除結果確認
SELECT '削除後の確認:' as after_deletion;
SELECT 
    COUNT(*) as remaining_lc_accounts
FROM users
WHERE user_id LIKE '%_lc';

-- 6. 削除されなかった_lcアカウント（NFT所有者など）
SELECT '削除されなかった_lcアカウント:' as remaining_lc;
SELECT 
    u.name,
    u.user_id,
    u.email,
    CASE 
        WHEN un.id IS NOT NULL THEN 'NFT所有'
        ELSE '要確認'
    END as reason
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.user_id LIKE '%_lc'
ORDER BY u.name;

SELECT '=== _lcアカウント削除完了 ===' as completed;