-- _authサフィックスユーザーの調査

SELECT '=== INVESTIGATING _AUTH SUFFIX USERS ===' as section;

-- 1. _authサフィックスを持つユーザーを全て確認
SELECT '_auth suffix users (ABNORMAL):' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.phone,
    u.created_at,
    u.total_investment,
    u.total_earned,
    u.active_nft_count,
    '異常：_authサフィックス' as issue_type
FROM users u
WHERE u.user_id LIKE '%_auth%'
ORDER BY u.created_at;

-- 2. 類似パターンの確認（その他の異常サフィックス）
SELECT 'Other abnormal suffix patterns:' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    CASE 
        WHEN u.user_id LIKE '%_auth%' THEN '_auth系'
        WHEN u.user_id LIKE '%_test%' THEN '_test系'
        WHEN u.user_id LIKE '%_temp%' THEN '_temp系'
        WHEN u.user_id LIKE '%_bak%' THEN '_backup系'
        ELSE 'その他異常'
    END as pattern_type
FROM users u
WHERE u.user_id LIKE '%_auth%'
   OR u.user_id LIKE '%_test%'
   OR u.user_id LIKE '%_temp%'
   OR u.user_id LIKE '%_bak%'
   OR u.user_id LIKE '%_backup%'
ORDER BY pattern_type, u.created_at;

-- 3. ハギワラサナエさんの詳細調査
SELECT 'ハギワラサナエ detailed analysis:' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.phone,
    u.created_at,
    u.updated_at,
    u.total_investment,
    u.total_earned,
    u.pending_rewards,
    u.active_nft_count,
    u.referrer_id,
    u.my_referral_code,
    u.is_admin
FROM users u
WHERE u.name = 'ハギワラサナエ';

-- 4. 同じ作成日時のユーザー確認（一括作成の可能性）
SELECT 'Users created at same time as ハギワラサナエ:' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    CASE 
        WHEN u.name LIKE 'ユーザー%' OR u.name LIKE '%UP' OR u.phone = '000-0000-0000' THEN 'テストユーザー'
        WHEN u.user_id LIKE '%_auth%' THEN '異常サフィックス'
        ELSE '要確認'
    END as user_type
FROM users u
WHERE DATE(u.created_at) = (
    SELECT DATE(created_at) 
    FROM users 
    WHERE name = 'ハギワラサナエ'
)
ORDER BY u.created_at, u.name;

-- 5. NFTや報酬データの有無確認
SELECT 'ハギワラサナエ NFT and reward check:' as info;
SELECT 
    'NFT保有状況' as data_type,
    COALESCE(nft_count.count, 0) as count,
    COALESCE(nft_count.details, 'NFTなし') as details
FROM (
    SELECT 
        COUNT(*) as count,
        STRING_AGG(n.name || '(' || CASE WHEN un.is_active THEN 'アクティブ' ELSE '非アクティブ' END || ')', ', ') as details
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id
    LEFT JOIN nfts n ON un.nft_id = n.id
    WHERE u.name = 'ハギワラサナエ'
) nft_count
UNION ALL
SELECT 
    '報酬履歴' as data_type,
    COALESCE(reward_count.count, 0) as count,
    COALESCE('総額: $' || reward_count.total::text, '報酬なし') as details
FROM (
    SELECT 
        COUNT(*) as count,
        SUM(dr.amount) as total
    FROM users u
    LEFT JOIN daily_rewards dr ON u.id = dr.user_id
    WHERE u.name = 'ハギワラサナエ'
) reward_count;

SELECT '=== _AUTH SUFFIX INVESTIGATION COMPLETE ===' as status;