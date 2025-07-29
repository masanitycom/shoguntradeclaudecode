-- 最終ランク結果の詳細確認

-- 1. 各ランクレベルの統計
SELECT 
    'ランクレベル統計' as report_type,
    rank_level,
    rank_name,
    COUNT(*) as user_count,
    ROUND(AVG(organization_volume), 2) as avg_org_volume,
    ROUND(AVG(max_line_volume), 2) as avg_max_line,
    ROUND(AVG(other_lines_volume), 2) as avg_other_lines,
    ROUND(AVG(nft_value_at_time), 2) as avg_nft_value
FROM user_rank_history 
WHERE is_current = true
GROUP BY rank_level, rank_name
ORDER BY rank_level DESC;

-- 2. 上位ランク保持者の詳細（レベル1以上）
SELECT 
    'ランク保持者詳細' as report_type,
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
ORDER BY urh.rank_level DESC, urh.organization_volume DESC
LIMIT 20;

-- 3. マツムラヒロエさんの最終確認
SELECT 
    'マツムラヒロエ確認' as report_type,
    u.name,
    u.user_id,
    urh.rank_name,
    urh.rank_level,
    urh.organization_volume,
    urh.max_line_volume,
    urh.other_lines_volume,
    urh.nft_value_at_time,
    CASE 
        WHEN urh.nft_value_at_time >= 1000 AND urh.organization_volume >= 1000 
        THEN '足軽条件満たす' 
        ELSE '足軽条件満たさず' 
    END as ashigaru_qualification
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE u.user_id = 'm2332h' AND urh.is_current = true;

-- 4. NFT1000以上で足軽になれていないユーザー
SELECT 
    'NFT1000以上で足軽未達成' as report_type,
    u.name,
    u.user_id,
    urh.rank_name,
    urh.nft_value_at_time,
    urh.organization_volume,
    (1000 - urh.organization_volume) as needed_org_volume
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE urh.is_current = true 
    AND urh.rank_level = 0 
    AND urh.nft_value_at_time >= 1000
ORDER BY urh.nft_value_at_time DESC
LIMIT 10;

-- 5. 組織構造バランス分析（上位10名）
SELECT 
    '組織構造バランス' as report_type,
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
LIMIT 10;

-- 6. 全体サマリー
SELECT 
    '全体サマリー' as report_type,
    COUNT(*) as total_users,
    SUM(CASE WHEN rank_level = 0 THEN 1 ELSE 0 END) as no_rank,
    SUM(CASE WHEN rank_level >= 1 THEN 1 ELSE 0 END) as with_rank,
    SUM(CASE WHEN nft_value_at_time >= 1000 THEN 1 ELSE 0 END) as nft_1000_plus,
    SUM(CASE WHEN organization_volume >= 1000 THEN 1 ELSE 0 END) as org_1000_plus,
    ROUND(AVG(nft_value_at_time), 2) as avg_nft_value,
    ROUND(AVG(organization_volume), 2) as avg_org_volume
FROM user_rank_history 
WHERE is_current = true;
