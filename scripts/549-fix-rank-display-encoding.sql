-- ランク表示の文字化け修正

-- 1. calculate_user_mlm_rank関数を修正（文字化け対応）
DROP FUNCTION IF EXISTS calculate_user_mlm_rank(UUID);

CREATE OR REPLACE FUNCTION calculate_user_mlm_rank(target_user_id UUID)
RETURNS TABLE(
    user_id UUID,
    rank_name TEXT,
    rank_level INTEGER,
    user_nft_value DECIMAL(15,2),
    organization_volume DECIMAL(15,2),
    meets_nft_requirement BOOLEAN,
    meets_organization_requirement BOOLEAN
) AS $$
DECLARE
    user_nft_total DECIMAL(15,2) := 0;
    org_volume DECIMAL(15,2) := 0;
    current_rank TEXT := 'なし';
    current_level INTEGER := 0;
    nft_requirement_met BOOLEAN := false;
    org_requirement_met BOOLEAN := false;
BEGIN
    -- ユーザーのNFT価値を計算
    SELECT COALESCE(SUM(un.purchase_price), 0)
    INTO user_nft_total
    FROM user_nfts un
    WHERE un.user_id = target_user_id 
    AND un.is_active = true;
    
    -- 組織ボリュームを計算（簡易版）
    WITH RECURSIVE referral_tree AS (
        -- 直接の紹介者
        SELECT id, referrer_id, 1 as level
        FROM users 
        WHERE referrer_id = target_user_id
        
        UNION ALL
        
        -- 間接的な紹介者（最大5レベル）
        SELECT u.id, u.referrer_id, rt.level + 1
        FROM users u
        INNER JOIN referral_tree rt ON u.referrer_id = rt.id
        WHERE rt.level < 5
    )
    SELECT COALESCE(SUM(un.purchase_price), 0)
    INTO org_volume
    FROM referral_tree rt
    INNER JOIN user_nfts un ON rt.id = un.user_id
    WHERE un.is_active = true;
    
    -- NFT要件チェック（1000ドル以上）
    nft_requirement_met := user_nft_total >= 1000;
    
    -- ランク判定（文字化けしないように明示的に設定）
    IF user_nft_total >= 1000 THEN
        IF org_volume >= 600000 THEN
            current_rank := '将軍';
            current_level := 8;
            org_requirement_met := true;
        ELSIF org_volume >= 300000 THEN
            current_rank := '大名';
            current_level := 7;
            org_requirement_met := true;
        ELSIF org_volume >= 100000 THEN
            current_rank := '大老';
            current_level := 6;
            org_requirement_met := true;
        ELSIF org_volume >= 50000 THEN
            current_rank := '老中';
            current_level := 5;
            org_requirement_met := true;
        ELSIF org_volume >= 10000 THEN
            current_rank := '奉行';
            current_level := 4;
            org_requirement_met := true;
        ELSIF org_volume >= 5000 THEN
            current_rank := '代官';
            current_level := 3;
            org_requirement_met := true;
        ELSIF org_volume >= 3000 THEN
            current_rank := '武将';
            current_level := 2;
            org_requirement_met := true;
        ELSIF org_volume >= 1000 THEN
            current_rank := '足軽';
            current_level := 1;
            org_requirement_met := true;
        ELSE
            current_rank := 'なし';
            current_level := 0;
            org_requirement_met := false;
        END IF;
    ELSE
        current_rank := 'なし';
        current_level := 0;
        org_requirement_met := false;
    END IF;
    
    RETURN QUERY SELECT 
        target_user_id,
        current_rank,
        current_level,
        user_nft_total,
        org_volume,
        nft_requirement_met,
        org_requirement_met;
END;
$$ LANGUAGE plpgsql;

-- 2. ユーザーランク情報を更新
UPDATE users 
SET current_rank = (
    SELECT rank_name 
    FROM calculate_user_mlm_rank(users.id) 
    LIMIT 1
),
updated_at = NOW()
WHERE id IN (
    SELECT DISTINCT user_id 
    FROM user_nfts 
    WHERE is_active = true
);

-- 3. 文字エンコーディングの確認
SELECT 
    '🔤 文字エンコーディング確認' as info,
    u.name as user_name,
    u.current_rank,
    LENGTH(u.current_rank) as rank_length,
    ASCII(SUBSTRING(u.current_rank, 1, 1)) as first_char_ascii
FROM users u
WHERE u.current_rank IS NOT NULL
AND u.current_rank != 'なし'
ORDER BY u.current_rank
LIMIT 10;

-- 4. ランク統計
SELECT 
    '📊 ランク統計' as info,
    current_rank,
    COUNT(*) as user_count
FROM users 
WHERE current_rank IS NOT NULL
GROUP BY current_rank
ORDER BY 
    CASE current_rank
        WHEN '将軍' THEN 8
        WHEN '大名' THEN 7
        WHEN '大老' THEN 6
        WHEN '老中' THEN 5
        WHEN '奉行' THEN 4
        WHEN '代官' THEN 3
        WHEN '武将' THEN 2
        WHEN '足軽' THEN 1
        ELSE 0
    END DESC;

SELECT '✅ ランク表示の文字化け修正完了' as final_status;
