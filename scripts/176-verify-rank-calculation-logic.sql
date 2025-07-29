-- MLMランク計算ロジックの検証

-- 1. 各ランクの条件チェック
WITH rank_conditions AS (
    SELECT 
        rank_level,
        rank_name,
        CASE rank_level
            WHEN 8 THEN 'NFT≥1000 AND 最大ライン≥600,000 AND 他系列≥500,000'
            WHEN 7 THEN 'NFT≥1000 AND 最大ライン≥300,000 AND 他系列≥150,000'
            WHEN 6 THEN 'NFT≥1000 AND 最大ライン≥100,000 AND 他系列≥50,000'
            WHEN 5 THEN 'NFT≥1000 AND 最大ライン≥50,000 AND 他系列≥25,000'
            WHEN 4 THEN 'NFT≥1000 AND 最大ライン≥10,000 AND 他系列≥5,000'
            WHEN 3 THEN 'NFT≥1000 AND 最大ライン≥5,000 AND 他系列≥2,500'
            WHEN 2 THEN 'NFT≥1000 AND 最大ライン≥3,000 AND 他系列≥1,500'
            WHEN 1 THEN 'NFT≥1000 AND 組織≥1,000'
            ELSE 'NFT<1000 OR 組織<1,000'
        END as conditions,
        COUNT(*) as user_count
    FROM user_rank_history 
    WHERE is_current = true
    GROUP BY rank_level, rank_name
)
SELECT * FROM rank_conditions ORDER BY rank_level DESC;

-- 2. 条件を満たしているが低いランクになっているユーザーの確認
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.rank_level,
    urh.nft_value_at_time,
    urh.organization_volume,
    urh.max_line_volume,
    urh.other_lines_volume,
    CASE 
        WHEN urh.nft_value_at_time >= 1000 AND urh.max_line_volume >= 3000 AND urh.other_lines_volume >= 1500 THEN '武将以上の条件を満たす'
        WHEN urh.nft_value_at_time >= 1000 AND urh.organization_volume >= 1000 THEN '足軽条件を満たす'
        ELSE '条件不足'
    END as potential_rank
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE urh.is_current = true 
    AND urh.rank_level < 2 
    AND urh.nft_value_at_time >= 1000 
    AND urh.max_line_volume >= 3000 
    AND urh.other_lines_volume >= 1500
ORDER BY urh.max_line_volume DESC, urh.other_lines_volume DESC;

-- 3. 組織構造の詳細分析（上位10名）
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.organization_volume as total_org,
    urh.max_line_volume,
    urh.other_lines_volume,
    ROUND((urh.max_line_volume::numeric / NULLIF(urh.organization_volume, 0)) * 100, 2) as max_line_percentage,
    ROUND((urh.other_lines_volume::numeric / NULLIF(urh.organization_volume, 0)) * 100, 2) as other_lines_percentage
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE urh.is_current = true AND urh.organization_volume > 0
ORDER BY urh.organization_volume DESC
LIMIT 10;
