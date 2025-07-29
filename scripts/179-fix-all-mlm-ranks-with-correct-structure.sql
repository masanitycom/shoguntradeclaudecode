-- 全MLMランクレベルを正しく計算・修正（実際のテーブル構造に基づく）

-- 1. 現在のランク履歴を無効化
UPDATE user_rank_history SET is_current = false WHERE is_current = true;

-- 2. 各ユーザーの基本情報とNFT価値を取得
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
-- 3. 各ユーザーの直接紹介者とその投資額を取得
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
-- 4. 各ユーザーの組織全体のボリューム計算
organization_volume AS (
    SELECT 
        user_id,
        COALESCE(SUM(referral_investment), 0) as total_organization_volume,
        COUNT(CASE WHEN referral_investment > 0 THEN 1 END) as active_referrals
    FROM direct_referrals
    GROUP BY user_id
),
-- 5. 最大ライン・他系列ボリューム計算
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
-- 6. 全データを統合
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
-- 7. ランクレベル判定
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
-- 8. 正しいランク履歴を挿入
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
