-- NFT消失の原因調査

SELECT '=== NFT消失の原因調査 ===' as section;

-- 1. 非アクティブ化されたNFTの詳細
SELECT 'Deactivated NFTs (消失したNFT):' as info;
SELECT 
    u.name,
    u.email,
    u.user_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.total_earned,
    n.price,
    ROUND((un.total_earned / n.price) * 100, 2) as progress_percentage,
    un.is_active,
    un.updated_at as deactivated_time,
    CASE 
        WHEN un.total_earned >= (n.price * 3) THEN '300%達成による正常終了'
        WHEN un.total_earned = 0 THEN '報酬なしで非アクティブ化（異常）'
        ELSE '途中で非アクティブ化（要調査）'
    END as deactivation_reason
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = false
ORDER BY un.updated_at DESC;

-- 2. NFTがないユーザーの分類
SELECT 'NFTがないユーザーの分類:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.user_id,
    u.phone,
    u.created_at,
    u.total_investment,
    u.total_earned,
    CASE 
        WHEN u.name LIKE 'ユーザー%' OR u.name LIKE '%UP' THEN 'テストユーザー（削除候補）'
        WHEN u.phone = '000-0000-0000' THEN 'テストユーザー（削除候補）'
        WHEN u.email LIKE '%@shogun-trade.com%' AND u.name LIKE 'ユーザー%' THEN 'テストユーザー（削除候補）'
        WHEN u.total_investment = 0 AND u.total_earned = 0 THEN 'NFT未購入ユーザー（削除候補）'
        ELSE '要確認：実ユーザーの可能性'
    END as classification
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
ORDER BY 
    CASE 
        WHEN u.name LIKE 'ユーザー%' OR u.name LIKE '%UP' THEN 1
        WHEN u.phone = '000-0000-0000' THEN 2
        WHEN u.total_investment = 0 AND u.total_earned = 0 THEN 3
        ELSE 4
    END,
    u.created_at;

-- 3. NFT復旧が必要な可能性があるユーザー
SELECT 'NFT復旧が必要な可能性があるユーザー:' as critical;
SELECT 
    u.id,
    u.name,
    u.email,
    u.total_investment,
    u.total_earned,
    u.created_at,
    '要確認：投資額または報酬があるのにNFTなし' as issue
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
  AND (u.total_investment > 0 OR u.total_earned > 0)
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND u.phone != '000-0000-0000';

-- 4. 安全に削除できるテストユーザーの候補
SELECT '安全に削除できるテストユーザー候補:' as deletion_candidates;
SELECT 
    COUNT(*) as count,
    '明確なテストユーザー（NFTなし、投資額0、報酬0）' as category
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
  AND u.total_investment = 0
  AND u.total_earned = 0
  AND (
    u.name LIKE 'ユーザー%'
    OR u.name LIKE '%UP'
    OR u.phone = '000-0000-0000'
  );

SELECT '=== NFT消失調査完了 ===' as status;