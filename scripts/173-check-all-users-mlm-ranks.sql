-- 全ユーザーのMLMランク状況確認

-- 1. 現在のMLMランク分布
SELECT 
    mr.rank_name,
    mr.rank_level,
    COUNT(urh.user_id) as user_count
FROM mlm_ranks mr
LEFT JOIN user_rank_history urh ON mr.rank_level = urh.rank_level AND urh.is_current = true
GROUP BY mr.rank_level, mr.rank_name
ORDER BY mr.rank_level;

-- 2. 問題のあるユーザー（組織ボリューム0なのにランクありの場合）
WITH user_org_data AS (
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
    WHERE u.is_admin = false
    GROUP BY u.id, u.name, u.user_id
),
current_ranks AS (
    SELECT 
        urh.user_id,
        urh.rank_level,
        urh.rank_name
    FROM user_rank_history urh
    WHERE urh.is_current = true
)
SELECT 
    uod.name,
    uod.user_id,
    uod.nft_value,
    uod.organization_volume,
    uod.direct_referrals,
    cr.rank_level as current_rank_level,
    cr.rank_name as current_rank_name,
    CASE 
        WHEN uod.nft_value >= 1000 AND uod.organization_volume >= 1000 THEN 1
        ELSE 0
    END as should_be_rank_level,
    CASE 
        WHEN uod.nft_value >= 1000 AND uod.organization_volume >= 1000 THEN '足軽'
        ELSE 'なし'
    END as should_be_rank_name,
    CASE 
        WHEN cr.rank_level != CASE 
            WHEN uod.nft_value >= 1000 AND uod.organization_volume >= 1000 THEN 1
            ELSE 0
        END THEN 'INCORRECT'
        ELSE 'CORRECT'
    END as rank_status
FROM user_org_data uod
LEFT JOIN current_ranks cr ON uod.id = cr.user_id
ORDER BY rank_status DESC, uod.organization_volume DESC;

-- 3. 足軽ランクの詳細確認
SELECT 
    u.name,
    u.user_id,
    COALESCE(SUM(un.current_investment), 0) as nft_value,
    COUNT(ref.id) as direct_referrals,
    COALESCE(SUM(ref_nfts.current_investment), 0) as organization_volume,
    urh.rank_name,
    urh.qualified_date
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN users ref ON u.id = ref.referrer_id
LEFT JOIN user_nfts ref_nfts ON ref.id = ref_nfts.user_id AND ref_nfts.is_active = true
LEFT JOIN user_rank_history urh ON u.id = urh.user_id AND urh.is_current = true
WHERE urh.rank_level = 1
GROUP BY u.id, u.name, u.user_id, urh.rank_name, urh.qualified_date
ORDER BY organization_volume DESC;
