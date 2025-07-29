-- 段階的ランク計算（デバッグ版）

-- ステップ1: 現在のランク履歴を無効化
UPDATE user_rank_history SET is_current = false WHERE is_current = true;

-- ステップ2: 基本情報の確認
SELECT 'ステップ2: 基本情報確認' as step;

-- ステップ3: 各ユーザーの基本情報とNFT価値を取得（テスト）
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
)
SELECT 
    'ステップ3: 基本情報取得結果' as step,
    COUNT(*) as user_count,
    SUM(CASE WHEN nft_value > 0 THEN 1 ELSE 0 END) as users_with_nft,
    SUM(CASE WHEN nft_value >= 1000 THEN 1 ELSE 0 END) as users_nft_1000_plus
FROM user_basic_info;

-- ステップ4: 紹介関係の確認
WITH direct_referrals AS (
    SELECT 
        u.id as user_id,
        ref.id as referral_id,
        COALESCE(SUM(ref_nfts.current_investment), 0) as referral_investment
    FROM users u
    LEFT JOIN users ref ON u.id = ref.referrer_id
    LEFT JOIN user_nfts ref_nfts ON ref.id = ref_nfts.user_id AND ref_nfts.is_active = true
    WHERE u.is_admin = false
    GROUP BY u.id, ref.id
)
SELECT 
    'ステップ4: 紹介関係確認' as step,
    COUNT(*) as total_relationships,
    COUNT(CASE WHEN referral_investment > 0 THEN 1 END) as active_referrals,
    SUM(referral_investment) as total_referral_investment
FROM direct_referrals;

-- ステップ5: 組織ボリューム計算
WITH direct_referrals AS (
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
)
SELECT 
    'ステップ5: 組織ボリューム計算' as step,
    COUNT(*) as users_with_org,
    SUM(CASE WHEN total_organization_volume > 0 THEN 1 ELSE 0 END) as users_with_volume,
    SUM(CASE WHEN total_organization_volume >= 1000 THEN 1 ELSE 0 END) as users_volume_1000_plus,
    MAX(total_organization_volume) as max_org_volume
FROM organization_volume;
