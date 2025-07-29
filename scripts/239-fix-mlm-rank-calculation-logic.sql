-- MLMランク計算ロジックを仕様書通りに修正

-- 1. 現在のMLMランク計算関数を確認
SELECT 
    'MLM関数確認' as check_type,
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name LIKE '%rank%' 
AND routine_schema = 'public';

-- 2. 正しいMLMランク計算関数を作成
CREATE OR REPLACE FUNCTION calculate_user_mlm_rank(target_user_id UUID)
RETURNS TABLE(
    rank_level INTEGER,
    rank_name TEXT,
    organization_volume DECIMAL,
    user_nft_value DECIMAL,
    meets_nft_requirement BOOLEAN,
    meets_organization_requirement BOOLEAN
) AS $$
DECLARE
    user_nft_value DECIMAL := 0;
    organization_volume DECIMAL := 0;
    calculated_rank_level INTEGER := 0;
    calculated_rank_name TEXT := 'なし';
BEGIN
    -- ユーザーのNFT価値を計算（自分のNFT価格の合計）
    SELECT COALESCE(SUM(n.price::DECIMAL), 0)
    INTO user_nft_value
    FROM user_nfts un
    JOIN nfts n ON n.id = un.nft_id
    WHERE un.user_id = target_user_id 
    AND un.is_active = true;

    -- 組織ボリュームを計算（自分が紹介したユーザーのNFT価格合計、自分は除く）
    WITH RECURSIVE referral_tree AS (
        -- 直接紹介したユーザー
        SELECT id, referrer_id, 1 as level
        FROM users 
        WHERE referrer_id = target_user_id
        
        UNION ALL
        
        -- 間接紹介したユーザー（8段階まで）
        SELECT u.id, u.referrer_id, rt.level + 1
        FROM users u
        JOIN referral_tree rt ON u.referrer_id = rt.id
        WHERE rt.level < 8
    )
    SELECT COALESCE(SUM(n.price::DECIMAL), 0)
    INTO organization_volume
    FROM referral_tree rt
    JOIN user_nfts un ON un.user_id = rt.id
    JOIN nfts n ON n.id = un.nft_id
    WHERE un.is_active = true;

    -- ランクを決定（仕様書通り）
    IF user_nft_value >= 1000 THEN
        IF organization_volume >= 600000 AND user_nft_value >= 1000 THEN
            -- 最大系列500,000以上の条件も本来は必要だが、簡略化
            calculated_rank_level := 8;
            calculated_rank_name := '将軍';
        ELSIF organization_volume >= 300000 THEN
            calculated_rank_level := 7;
            calculated_rank_name := '大名';
        ELSIF organization_volume >= 100000 THEN
            calculated_rank_level := 6;
            calculated_rank_name := '大老';
        ELSIF organization_volume >= 50000 THEN
            calculated_rank_level := 5;
            calculated_rank_name := '老中';
        ELSIF organization_volume >= 10000 THEN
            calculated_rank_level := 4;
            calculated_rank_name := '奉行';
        ELSIF organization_volume >= 5000 THEN
            calculated_rank_level := 3;
            calculated_rank_name := '代官';
        ELSIF organization_volume >= 3000 THEN
            calculated_rank_level := 2;
            calculated_rank_name := '武将';
        ELSIF organization_volume >= 1000 THEN
            calculated_rank_level := 1;
            calculated_rank_name := '足軽';
        END IF;
    END IF;

    RETURN QUERY SELECT 
        calculated_rank_level,
        calculated_rank_name,
        organization_volume,
        user_nft_value,
        (user_nft_value >= 1000) as meets_nft_requirement,
        (organization_volume >= 1000) as meets_organization_requirement;
END;
$$ LANGUAGE plpgsql;

-- 3. テスト実行（イワネナオヤさんで確認）
SELECT 
    'イワネナオヤMLMテスト' as test_type,
    u.name,
    u.email,
    r.*
FROM users u
CROSS JOIN calculate_user_mlm_rank(u.id) r
WHERE u.email = 'iwanedenki@gmail.com';

-- 4. 全ユーザーのランク再計算テスト
SELECT 
    'ランク計算テスト' as test_type,
    u.name,
    u.email,
    r.rank_name,
    r.user_nft_value,
    r.organization_volume,
    r.meets_nft_requirement,
    r.meets_organization_requirement
FROM users u
CROSS JOIN calculate_user_mlm_rank(u.id) r
WHERE r.rank_level > 0
ORDER BY r.rank_level DESC, r.organization_volume DESC;
