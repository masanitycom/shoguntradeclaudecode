-- マツムラヒロエさんの詳細情報確認（修正版）

-- 1. ユーザー基本情報
SELECT 
    id,
    name,
    user_id,
    email,
    created_at
FROM users 
WHERE user_id = 'm2332h';

-- 2. NFT保有状況
SELECT 
    u.name,
    u.user_id,
    un.current_investment,
    n.name as nft_name,
    n.price,
    un.is_active,
    un.purchase_date
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id = 'm2332h'
ORDER BY un.purchase_date DESC;

-- 3. 現在のMLMランク履歴
SELECT 
    u.name,
    u.user_id,
    urh.rank_level,
    urh.rank_name,
    urh.organization_volume,
    urh.max_line_volume,
    urh.other_lines_volume,
    urh.qualified_date,
    urh.is_current
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE u.user_id = 'm2332h'
ORDER BY urh.created_at DESC;

-- 4. 組織ボリューム詳細
SELECT 
    u.name,
    u.user_id,
    COUNT(ref.id) as direct_referrals,
    COALESCE(SUM(ref_nfts.current_investment), 0) as direct_referrals_investment,
    un.current_investment as total_nft_value
FROM users u
LEFT JOIN users ref ON u.id = ref.referrer_id
LEFT JOIN user_nfts ref_nfts ON ref.id = ref_nfts.user_id AND ref_nfts.is_active = true
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.user_id = 'm2332h'
GROUP BY u.name, u.user_id, un.current_investment;

-- 5. 直接紹介者リスト
SELECT 
    ref.name as referral_name,
    ref.user_id as referral_id,
    COALESCE(ref_nfts.current_investment, 0) as investment
FROM users u
LEFT JOIN users ref ON u.id = ref.referrer_id
LEFT JOIN user_nfts ref_nfts ON ref.id = ref_nfts.user_id AND ref_nfts.is_active = true
WHERE u.user_id = 'm2332h'
ORDER BY ref_nfts.current_investment DESC;

-- 6. MLMランク判定テスト
WITH user_data AS (
    SELECT 
        u.id,
        u.name,
        u.user_id,
        COALESCE(SUM(un.current_investment), 0) as nft_value,
        COUNT(ref.id) as direct_referrals,
        COALESCE(SUM(ref_nfts.current_investment), 0) as organization_volume
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    LEFT JOIN users ref ON u.id = ref.referrer_id
    LEFT JOIN user_nfts ref_nfts ON ref.id = ref_nfts.user_id AND ref_nfts.is_active = true
    WHERE u.user_id = 'm2332h'
    GROUP BY u.id, u.name, u.user_id
)
SELECT 
    name,
    user_id,
    nft_value,
    organization_volume,
    direct_referrals,
    CASE 
        WHEN nft_value >= 1000 AND organization_volume >= 1000 THEN '足軽'
        ELSE 'なし'
    END as correct_rank
FROM user_data;
