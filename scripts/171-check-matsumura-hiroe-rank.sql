-- マツムラヒロエ（ID: m2332h）のMLMランク詳細確認

-- 1. ユーザー基本情報
SELECT 
    id,
    name,
    user_id,
    email,
    created_at
FROM users 
WHERE user_id = 'm2332h' OR name LIKE '%マツムラヒロエ%' OR name LIKE '%松村%';

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
WHERE u.user_id = 'm2332h' OR u.name LIKE '%マツムラヒロエ%'
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
LEFT JOIN user_rank_history urh ON u.id = urh.user_id
WHERE (u.user_id = 'm2332h' OR u.name LIKE '%マツムラヒロエ%')
  AND urh.is_current = true
ORDER BY urh.created_at DESC;

-- 4. 組織ボリューム詳細計算
WITH target_user AS (
    SELECT id, name, user_id 
    FROM users 
    WHERE user_id = 'm2332h' OR name LIKE '%マツムラヒロエ%'
    LIMIT 1
)
SELECT 
    tu.name,
    tu.user_id,
    -- 直接紹介者数
    (SELECT COUNT(*) FROM users WHERE referrer_id = tu.id) as direct_referrals,
    -- 直接紹介者の投資額合計
    (SELECT COALESCE(SUM(un.current_investment), 0) 
     FROM users u2 
     JOIN user_nfts un ON u2.id = un.user_id 
     WHERE u2.referrer_id = tu.id AND un.is_active = true) as direct_referrals_investment,
    -- 総NFT価値
    (SELECT COALESCE(SUM(un.current_investment), 0) 
     FROM user_nfts un 
     WHERE un.user_id = tu.id AND un.is_active = true) as total_nft_value
FROM target_user tu;

-- 5. 組織ツリー詳細（3段階まで）
WITH RECURSIVE target_user AS (
    SELECT id, name, user_id 
    FROM users 
    WHERE user_id = 'm2332h' OR name LIKE '%マツムラヒロエ%'
    LIMIT 1
),
organization_tree AS (
    -- 直接紹介者（レベル1）
    SELECT 
        u.id,
        u.name,
        u.user_id,
        u.referrer_id,
        COALESCE(SUM(un.current_investment), 0) as investment,
        1 as level,
        u.id as line_root
    FROM target_user tu
    JOIN users u ON u.referrer_id = tu.id
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    GROUP BY u.id, u.name, u.user_id, u.referrer_id
    
    UNION ALL
    
    -- 間接紹介者（レベル2-3）
    SELECT 
        u.id,
        u.name,
        u.user_id,
        u.referrer_id,
        COALESCE(SUM(un.current_investment), 0) as investment,
        ot.level + 1,
        ot.line_root
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    JOIN organization_tree ot ON u.referrer_id = ot.id
    WHERE ot.level < 3
    GROUP BY u.id, u.name, u.user_id, u.referrer_id, ot.level, ot.line_root
)
SELECT 
    level,
    COUNT(*) as members_count,
    SUM(investment) as total_investment,
    line_root,
    (SELECT name FROM users WHERE id = line_root) as line_leader_name
FROM organization_tree
GROUP BY level, line_root
ORDER BY level, total_investment DESC;

-- 6. ライン別ボリューム（上位5ライン）
WITH RECURSIVE target_user AS (
    SELECT id, name, user_id 
    FROM users 
    WHERE user_id = 'm2332h' OR name LIKE '%マツムラヒロエ%'
    LIMIT 1
),
organization_tree AS (
    -- 直接紹介者
    SELECT 
        u.id,
        u.referrer_id,
        COALESCE(SUM(un.current_investment), 0) as investment,
        1 as level,
        u.id as line_root
    FROM target_user tu
    JOIN users u ON u.referrer_id = tu.id
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    GROUP BY u.id, u.referrer_id
    
    UNION ALL
    
    -- 間接紹介者（8段階まで）
    SELECT 
        u.id,
        u.referrer_id,
        COALESCE(SUM(un.current_investment), 0) as investment,
        ot.level + 1,
        ot.line_root
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    JOIN organization_tree ot ON u.referrer_id = ot.id
    WHERE ot.level < 8
    GROUP BY u.id, u.referrer_id, ot.level, ot.line_root
),
line_volumes AS (
    SELECT 
        line_root,
        (SELECT name FROM users WHERE id = line_root) as line_leader_name,
        (SELECT user_id FROM users WHERE id = line_root) as line_leader_id,
        SUM(investment) as line_volume,
        COUNT(*) as line_members
    FROM organization_tree
    GROUP BY line_root
)
SELECT 
    line_leader_name,
    line_leader_id,
    line_volume,
    line_members,
    RANK() OVER (ORDER BY line_volume DESC) as rank
FROM line_volumes
ORDER BY line_volume DESC
LIMIT 5;

-- 7. MLMランク判定結果
WITH target_user AS (
    SELECT id, name, user_id 
    FROM users 
    WHERE user_id = 'm2332h' OR name LIKE '%マツムラヒロエ%'
    LIMIT 1
)
SELECT 
    tu.name,
    tu.user_id,
    result.*
FROM target_user tu
CROSS JOIN LATERAL (
    SELECT * FROM determine_user_rank(tu.id)
) result;
