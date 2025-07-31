-- 緊急データ保護・現状確認のみ（変更なし）

SELECT '=== EMERGENCY DATA PROTECTION - READ ONLY ===' as section;

-- 1. 手動登録されたと思われる実ユーザーの確認
SELECT 'REAL USERS (手動登録されたユーザー):' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.phone,
    u.created_at,
    CASE WHEN un.user_id IS NOT NULL THEN 'NFTあり' ELSE 'NFTなし' END as nft_status,
    CASE WHEN u.user_id LIKE '%_auth%' THEN '要調査：_authサフィックス' ELSE '正常' END as user_id_status
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.email LIKE '%@gmail.com%'
   OR u.email LIKE '%@yahoo.com%'
   OR u.email LIKE '%@yahoo.co.jp%'
   OR u.email LIKE '%@icloud.com%'
   OR (u.email NOT LIKE '%@shogun-trade.com%' AND u.name NOT LIKE 'ユーザー%' AND u.name NOT LIKE '%UP')
ORDER BY u.created_at;

-- 2. _authサフィックス問題の全体像
SELECT '_AUTH SUFFIX ISSUE ANALYSIS:' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    'スタッフ手動登録の可能性が高い' as assessment
FROM users u
WHERE u.user_id LIKE '%_auth%'
ORDER BY u.created_at;

-- 3. NFT付与状況の確認
SELECT 'NFT ASSIGNMENT STATUS:' as info;
SELECT 
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.total_earned,
    'スタッフが手動付与' as assignment_method
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
  AND (u.email LIKE '%@gmail.com%' OR u.email LIKE '%@yahoo.com%' OR u.user_id LIKE '%_auth%')
ORDER BY un.purchase_date;

-- 4. データ整合性チェック（変更なし）
SELECT 'DATA INTEGRITY CHECK:' as info;
SELECT 
    '総ユーザー数' as metric,
    COUNT(*) as value
FROM users
UNION ALL
SELECT 
    'アクティブNFT数' as metric,
    COUNT(*) as value
FROM user_nfts
WHERE is_active = true
UNION ALL
SELECT 
    '報酬レコード数' as metric,
    COUNT(*) as value
FROM daily_rewards;

SELECT '=== 現状確認完了 - データは一切変更していません ===' as status;