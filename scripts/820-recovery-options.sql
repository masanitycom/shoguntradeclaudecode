-- NFT消失ユーザーの復旧オプション

SELECT '=== NFT RECOVERY OPTIONS ===' as section;

-- 1. 実ユーザーでNFTが消失している可能性があるケース
SELECT 'Real users who may need NFT recovery:' as critical_cases;
SELECT 
    u.id,
    u.name,
    u.email,
    u.total_investment,
    u.total_rewards,
    u.created_at,
    'NFT復旧が必要な可能性' as action_needed
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
  AND u.total_investment > 0
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND u.phone != '000-0000-0000'
  AND u.email NOT LIKE '%@shogun-trade.com%'
ORDER BY u.total_investment DESC;

-- 2. 非アクティブ化されたNFTを持つ実ユーザー
SELECT 'Real users with deactivated NFTs:' as deactivated_cases;
SELECT 
    u.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.total_earned,
    un.deactivated_at,
    un.deactivation_reason,
    CASE 
        WHEN un.deactivation_reason = '300% cap reached' THEN 'NFT完了（正常）'
        ELSE 'NFT復旧検討が必要'
    END as recovery_assessment
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = false
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND u.phone != '000-0000-0000'
  AND u.email NOT LIKE '%@shogun-trade.com%'
ORDER BY un.deactivated_at DESC;

-- 3. テストユーザーの削除推奨リスト
SELECT 'Test users recommended for deletion:' as deletion_candidates;
SELECT 
    u.id,
    u.name,
    u.email,
    u.phone,
    u.created_at,
    CASE 
        WHEN u.name LIKE 'ユーザー%' THEN 'ユーザー系テスト'
        WHEN u.name LIKE '%UP' THEN 'UP系テスト'
        WHEN u.phone = '000-0000-0000' THEN 'テスト電話番号'
        WHEN u.email LIKE '%@shogun-trade.com%' AND u.email != 'admin@shogun-trade.com' THEN 'テストドメイン'
        ELSE 'その他'
    END as test_type,
    COALESCE(nft_count.count, 0) as nft_count,
    COALESCE(reward_count.count, 0) as reward_count
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM user_nfts 
    GROUP BY user_id
) nft_count ON u.id = nft_count.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM daily_rewards 
    GROUP BY user_id
) reward_count ON u.id = reward_count.user_id
WHERE (
    u.name LIKE 'ユーザー%'
    OR u.name LIKE '%UP'
    OR u.phone = '000-0000-0000'
    OR (u.email LIKE '%@shogun-trade.com%' AND u.email != 'admin@shogun-trade.com')
)
ORDER BY test_type, u.name;

-- 4. 復旧手順の提案
SELECT 'RECOVERY RECOMMENDATIONS:' as recommendations;
SELECT '1. テストユーザーは管理画面から削除してください' as step1;
SELECT '2. 実ユーザーでNFTが消失している場合は個別に復旧処理が必要です' as step2;
SELECT '3. 非アクティブ化されたNFTが正当な理由（300%達成）でない場合は復旧を検討してください' as step3;
SELECT '4. データ復旧前に必ずバックアップを取得してください' as step4;

SELECT '=== RECOVERY OPTIONS ANALYSIS COMPLETE ===' as status;