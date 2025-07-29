-- 修正版ランク計算実行

-- 1. 現在のランク履歴を無効化
UPDATE user_rank_history SET is_current = false WHERE is_current = true;

-- 2. 実際のランク計算と挿入
WITH user_basic_info AS (
    SELECT 
        u.id as user_id,
        u.name,
        u.user_id as user_id_display,
        COALESCE(SUM(un.current_investment), 0) as nft_value
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    WHERE u.is_admin = false
    GROUP BY u.id, u.name, u.user_id
),
direct_referrals AS (
    SELECT 
        u.id as user_id,
        ref.id as referral_id,
        COALESCE(SUM(ref_nfts.current_investment), 0) as referral_investment
    FROM users u
    LEFT JOIN users ref ON u.id = ref.referrer_id
    LEFT JOIN user_nfts ref_nfts ON ref.id = ref_nfts.user_id AND ref_nfts.is_active = true
    WHERE u.is_admin = false
    GROUP BY u.id, ref.id
),
organization_volume AS (
    SELECT 
        user_id,
        COALESCE(SUM(referral_investment), 0) as total_organization_volume,
        COUNT(CASE WHEN referral_investment > 0 THEN 1 END) as active_referrals
    FROM direct_referrals
    GROUP BY user_id
),
line_analysis AS (
    SELECT 
        user_id,
        COALESCE(MAX(referral_investment), 0) as max_line_volume,
        CASE 
            WHEN COUNT(CASE WHEN referral_investment > 0 THEN 1 END) > 1 
            THEN COALESCE(SUM(referral_investment) - MAX(referral_investment), 0)
            ELSE 0
        END as other_lines_volume
    FROM direct_referrals
    GROUP BY user_id
),
user_complete_data AS (
    SELECT 
        ubi.user_id,
        ubi.name,
        ubi.user_id_display,
        ubi.nft_value,
        COALESCE(ov.total_organization_volume, 0) as total_organization_volume,
        COALESCE(ov.active_referrals, 0) as active_referrals,
        COALESCE(la.max_line_volume, 0) as max_line_volume,
        COALESCE(la.other_lines_volume, 0) as other_lines_volume
    FROM user_basic_info ubi
    LEFT JOIN organization_volume ov ON ubi.user_id = ov.user_id
    LEFT JOIN line_analysis la ON ubi.user_id = la.user_id
),
rank_determination AS (
    SELECT 
        *,
        CASE 
            WHEN nft_value >= 1000 AND max_line_volume >= 600000 AND other_lines_volume >= 500000 THEN 8
            WHEN nft_value >= 1000 AND max_line_volume >= 300000 AND other_lines_volume >= 150000 THEN 7
            WHEN nft_value >= 1000 AND max_line_volume >= 100000 AND other_lines_volume >= 50000 THEN 6
            WHEN nft_value >= 1000 AND max_line_volume >= 50000 AND other_lines_volume >= 25000 THEN 5
            WHEN nft_value >= 1000 AND max_line_volume >= 10000 AND other_lines_volume >= 5000 THEN 4
            WHEN nft_value >= 1000 AND max_line_volume >= 5000 AND other_lines_volume >= 2500 THEN 3
            WHEN nft_value >= 1000 AND max_line_volume >= 3000 AND other_lines_volume >= 1500 THEN 2
            WHEN nft_value >= 1000 AND total_organization_volume >= 1000 THEN 1
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

-- 3. 結果確認
SELECT 
    '修正完了' as status,
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
