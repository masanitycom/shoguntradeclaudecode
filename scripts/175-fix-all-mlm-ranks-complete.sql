-- 全MLMランクレベルを正しく計算・修正

-- 1. 現在のランク履歴を無効化
UPDATE user_rank_history SET is_current = false WHERE is_current = true;

-- 2. 各ユーザーの組織構造を詳細分析
WITH user_organization AS (
    SELECT 
        u.id as user_id,
        u.name,
        u.user_id as user_id_display,
        COALESCE(SUM(un.current_investment), 0) as nft_value,
        COUNT(DISTINCT ref.id) as direct_referrals,
        COALESCE(SUM(ref_nfts.current_investment), 0) as total_organization_volume
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    LEFT JOIN users ref ON u.id = ref.referrer_id
    LEFT JOIN user_nfts ref_nfts ON ref.id = ref_nfts.user_id AND ref_nfts.is_active = true
    WHERE u.is_admin = false
    GROUP BY u.id, u.name, u.user_id
),
-- 各ユーザーの系列別ボリューム計算
line_volumes AS (
    SELECT 
        u.id as user_id,
        ref.id as direct_referral_id,
        COALESCE(SUM(line_nfts.current_investment), 0) as line_volume
    FROM users u
    LEFT JOIN users ref ON u.id = ref.referrer_id
    LEFT JOIN user_nfts line_nfts ON ref.id = line_nfts.user_id AND line_nfts.is_active = true
    WHERE u.is_admin = false
    GROUP BY u.id, ref.id
),
-- 最大ライン・他系列ボリューム計算
max_line_calculation AS (
    SELECT 
        user_id,
        COALESCE(MAX(line_volume), 0) as max_line_volume,
        COALESCE(SUM(line_volume) - MAX(line_volume), 0) as other_lines_volume
    FROM line_volumes
    GROUP BY user_id
),
-- 全データ統合
user_complete_data AS (
    SELECT 
        uo.user_id,
        uo.name,
        uo.user_id_display,
        uo.nft_value,
        uo.direct_referrals,
        uo.total_organization_volume,
        COALESCE(mlc.max_line_volume, 0) as max_line_volume,
        COALESCE(mlc.other_lines_volume, 0) as other_lines_volume
    FROM user_organization uo
    LEFT JOIN max_line_calculation mlc ON uo.user_id = mlc.user_id
),
-- ランクレベル判定
rank_determination AS (
    SELECT 
        *,
        CASE 
            -- 将軍 (レベル8): NFT1000 + 最大ライン600,000 + 他系列500,000
            WHEN nft_value >= 1000 AND max_line_volume >= 600000 AND other_lines_volume >= 500000 THEN 8
            -- 大名 (レベル7): NFT1000 + 最大ライン300,000 + 他系列150,000
            WHEN nft_value >= 1000 AND max_line_volume >= 300000 AND other_lines_volume >= 150000 THEN 7
            -- 大老 (レベル6): NFT1000 + 最大ライン100,000 + 他系列50,000
            WHEN nft_value >= 1000 AND max_line_volume >= 100000 AND other_lines_volume >= 50000 THEN 6
            -- 老中 (レベル5): NFT1000 + 最大ライン50,000 + 他系列25,000
            WHEN nft_value >= 1000 AND max_line_volume >= 50000 AND other_lines_volume >= 25000 THEN 5
            -- 奉行 (レベル4): NFT1000 + 最大ライン10,000 + 他系列5,000
            WHEN nft_value >= 1000 AND max_line_volume >= 10000 AND other_lines_volume >= 5000 THEN 4
            -- 代官 (レベル3): NFT1000 + 最大ライン5,000 + 他系列2,500
            WHEN nft_value >= 1000 AND max_line_volume >= 5000 AND other_lines_volume >= 2500 THEN 3
            -- 武将 (レベル2): NFT1000 + 最大ライン3,000 + 他系列1,500
            WHEN nft_value >= 1000 AND max_line_volume >= 3000 AND other_lines_volume >= 1500 THEN 2
            -- 足軽 (レベル1): NFT1000 + 組織≥1,000
            WHEN nft_value >= 1000 AND total_organization_volume >= 1000 THEN 1
            -- なし (レベル0)
            ELSE 0
        END as rank_level,
        CASE 
            WHEN nft_value >= 1000 AND max_line_volume >= 600000 AND other_lines_volume >= 500000 THEN '将軍'
            WHEN nft_value >= 1000 AND max_line_volume >= 300000 AND other_lines_volume >= 150000 THEN '大名'
            WHEN nft_value >= 1000 AND max_line_volume >= 100000 AND other_lines_volume >= 50000 THEN '大老'
            WHEN nft_value >= 1000 AND max_line_volume >= 50000 AND other_lines_volume >= 25000 THEN '老中'
            WHEN nft_value >= 1000 AND max_line_volume >= 10000 AND other_lines_volume >= 5000 THEN '奉行'
            WHEN nft_value >= 1000 AND max_line_volume >= 5000 AND other_lines_volume >= 2500 THEN '代官'
            WHEN nft_value >= 1000 AND max_line_volume >= 3000 AND other_lines_volume >= 1500 THEN '武将'
            WHEN nft_value >= 1000 AND total_organization_volume >= 1000 THEN '足軽'
            ELSE 'なし'
        END as rank_name
    FROM user_complete_data
)
-- 3. 正しいランク履歴を挿入
INSERT INTO user_rank_history (
    user_id,
    rank_level,
    rank_name,
    organization_volume,
    max_line_volume,
    other_lines_volume,
    qualified_date,
    is_current,
    nft_value_at_time,
    organization_volume_at_time
)
SELECT 
    user_id,
    rank_level,
    rank_name,
    total_organization_volume,
    max_line_volume,
    other_lines_volume,
    CURRENT_DATE,
    true,
    nft_value,
    total_organization_volume
FROM rank_determination;

-- 4. 修正結果の確認
SELECT 
    '全ランク修正完了' as status,
    COUNT(*) as total_users,
    SUM(CASE WHEN rank_level = 0 THEN 1 ELSE 0 END) as rank_none,
    SUM(CASE WHEN rank_level = 1 THEN 1 ELSE 0 END) as rank_ashigaru,
    SUM(CASE WHEN rank_level = 2 THEN 1 ELSE 0 END) as rank_bushou,
    SUM(CASE WHEN rank_level = 3 THEN 1 ELSE 0 END) as rank_daikan,
    SUM(CASE WHEN rank_level = 4 THEN 1 ELSE 0 END) as rank_bugyou,
    SUM(CASE WHEN rank_level = 5 THEN 1 ELSE 0 END) as rank_rouchu,
    SUM(CASE WHEN rank_level = 6 THEN 1 ELSE 0 END) as rank_tairou,
    SUM(CASE WHEN rank_level = 7 THEN 1 ELSE 0 END) as rank_daimyou,
    SUM(CASE WHEN rank_level = 8 THEN 1 ELSE 0 END) as rank_shougun
FROM user_rank_history 
WHERE is_current = true;

-- 5. 各ランクレベルの詳細確認
SELECT 
    rank_level,
    rank_name,
    COUNT(*) as user_count,
    MIN(organization_volume) as min_org_volume,
    MAX(organization_volume) as max_org_volume,
    MIN(max_line_volume) as min_max_line,
    MAX(max_line_volume) as max_max_line,
    MIN(other_lines_volume) as min_other_lines,
    MAX(other_lines_volume) as max_other_lines
FROM user_rank_history 
WHERE is_current = true
GROUP BY rank_level, rank_name
ORDER BY rank_level DESC;

-- 6. 上位ランク保持者の詳細
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
ORDER BY urh.rank_level DESC, urh.organization_volume DESC
LIMIT 30;

-- 7. マツムラヒロエさんの最終確認
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
