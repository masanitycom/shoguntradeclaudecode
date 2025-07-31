-- NFT復旧計画

SELECT '=== NFT復旧計画 ===' as section;

-- 1. 300%達成で正常終了したNFT（復旧不要）
SELECT '正常終了したNFT（復旧不要）:' as info;
SELECT 
    u.name,
    n.name as nft_name,
    un.total_earned,
    n.price,
    ROUND((un.total_earned / n.price) * 100, 2) as completion_percentage,
    '正常終了' as status
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = false
  AND un.total_earned >= (n.price * 3);

-- 2. 異常に非アクティブ化されたNFT（復旧検討）
SELECT '異常に非アクティブ化されたNFT（復旧検討）:' as recovery_needed;
SELECT 
    u.id as user_id,
    u.name,
    u.email,
    n.id as nft_id,
    n.name as nft_name,
    un.purchase_date,
    un.total_earned,
    n.price,
    ROUND((un.total_earned / n.price) * 100, 2) as completion_percentage,
    '復旧検討' as action_needed
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = false
  AND un.total_earned < (n.price * 3)
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND u.phone != '000-0000-0000';

-- 3. NFT復旧のSQLテンプレート（実行前に個別確認）
SELECT 'NFT復旧のSQLテンプレート:' as template;
SELECT '-- 個別確認後に実行
-- UPDATE user_nfts 
-- SET is_active = true, updated_at = NOW()
-- WHERE user_id = ''[user_id]'' AND nft_id = [nft_id];' as recovery_sql;

-- 4. テストユーザー削除の最終候補
SELECT 'テストユーザー削除の最終候補:' as final_deletion_list;
SELECT 
    u.id,
    u.name,
    u.email,
    u.user_id,
    u.phone,
    u.total_investment,
    u.total_earned,
    '削除推奨' as recommendation
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
WHERE un.user_id IS NULL  -- NFTなし
  AND u.total_investment = 0  -- 投資額0
  AND u.total_earned = 0  -- 報酬0
  AND (
    u.name LIKE 'ユーザー%'
    OR u.name LIKE '%UP'
    OR u.phone = '000-0000-0000'
  )
ORDER BY u.created_at
LIMIT 10;  -- まず10件で確認

SELECT '=== NFT復旧計画完了 ===' as status;