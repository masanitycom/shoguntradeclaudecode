-- 全ユーザーのMLMランクを正しく修正

-- 1. 現在の間違ったランク履歴を無効化
UPDATE user_rank_history SET is_current = false WHERE is_current = true;

-- 2. 正しいMLMランクを計算して挿入
WITH user_org_data AS (
    SELECT 
        u.id as user_id,
        u.name,
        u.user_id as user_id_display,
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
rank_calculation AS (
    SELECT 
        user_id,
        name,
        user_id_display,
        nft_value,
        organization_volume,
        direct_referrals,
        CASE 
            WHEN nft_value >= 1000 AND organization_volume >= 1000 THEN 1
            ELSE 0
        END as correct_rank_level,
        CASE 
            WHEN nft_value >= 1000 AND organization_volume >= 1000 THEN '足軽'
            ELSE 'なし'
        END as correct_rank_name
    FROM user_org_data
)
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
    correct_rank_level,
    correct_rank_name,
    organization_volume,
    organization_volume, -- 簡略化：最大ライン = 組織ボリューム
    0, -- 他ライン（1ライン制の場合は0）
    CURRENT_DATE,
    true,
    nft_value,
    organization_volume
FROM rank_calculation;

-- 3. 修正結果の確認
SELECT 
    '修正完了' as status,
    COUNT(*) as total_users,
    SUM(CASE WHEN rank_level = 0 THEN 1 ELSE 0 END) as rank_none,
    SUM(CASE WHEN rank_level = 1 THEN 1 ELSE 0 END) as rank_ashigaru
FROM user_rank_history 
WHERE is_current = true;

-- 4. 修正後の詳細確認（上位20名）
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.organization_volume,
    urh.nft_value_at_time
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE urh.is_current = true AND u.is_admin = false
ORDER BY urh.rank_level DESC, urh.organization_volume DESC
LIMIT 20;

-- 5. マツムラヒロエさんの修正確認
SELECT 
    u.name,
    u.user_id,
    urh.rank_name,
    urh.rank_level,
    urh.organization_volume,
    urh.nft_value_at_time
FROM users u
JOIN user_rank_history urh ON u.id = urh.user_id
WHERE u.user_id = 'm2332h' AND urh.is_current = true;
