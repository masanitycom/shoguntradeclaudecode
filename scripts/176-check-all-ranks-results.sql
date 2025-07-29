-- 全ランク修正結果の詳細確認

-- 1. 各ランクレベルの統計
SELECT 
    rank_level,
    rank_name,
    COUNT(*) as user_count,
    COALESCE(MIN(organization_volume), 0) as min_org_volume,
    COALESCE(MAX(organization_volume), 0) as max_org_volume,
    COALESCE(MIN(max_line_volume), 0) as min_max_line,
    COALESCE(MAX(max_line_volume), 0) as max_max_line,
    COALESCE(MIN(other_lines_volume), 0) as min_other_lines,
    COALESCE(MAX(other_lines_volume), 0) as max_other_lines
FROM user_rank_history 
WHERE is_current = true
GROUP BY rank_level, rank_name
ORDER BY rank_level DESC;

-- 2. 上位ランク保持者の詳細（レベル1以上）
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.rank_level,
    urh.organization_volume,
    urh.max_line_volume,
    urh.other_lines_volume,
    urh.nft_value_at_time
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE urh.is_current = true AND urh.rank_level > 0
ORDER BY urh.rank_level DESC, urh.organization_volume DESC;

-- 3. マツムラヒロエさんの最終確認
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.rank_level,
    urh.organization_volume,
    urh.max_line_volume,
    urh.other_lines_volume,
    urh.nft_value_at_time
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE u.user_id = 'm2332h' AND urh.is_current = true;

-- 4. 武将以上の条件を満たすが低いランクのユーザー確認
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.rank_level,
    urh.nft_value_at_time,
    urh.organization_volume,
    urh.max_line_volume,
    urh.other_lines_volume,
    '武将条件: NFT≥1000, 最大ライン≥3000, 他系列≥1500' as note
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE urh.is_current = true 
    AND urh.rank_level < 2 
    AND urh.nft_value_at_time >= 1000 
    AND urh.max_line_volume >= 3000 
    AND urh.other_lines_volume >= 1500
ORDER BY urh.max_line_volume DESC;

-- 5. 組織構造の健全性チェック（上位20名）
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.organization_volume as total_org,
    urh.max_line_volume,
    urh.other_lines_volume,
    CASE 
        WHEN urh.organization_volume > 0 
        THEN ROUND((urh.max_line_volume::numeric / urh.organization_volume) * 100, 1)
        ELSE 0
    END as max_line_percentage,
    CASE 
        WHEN urh.organization_volume > 0 
        THEN ROUND((urh.other_lines_volume::numeric / urh.organization_volume) * 100, 1)
        ELSE 0
    END as other_lines_percentage
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE urh.is_current = true AND urh.organization_volume > 0
ORDER BY urh.organization_volume DESC
LIMIT 20;
