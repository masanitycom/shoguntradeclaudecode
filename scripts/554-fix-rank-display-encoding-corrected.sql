-- ランク表示の文字化け修正とMLMランクシステムの完全修正

-- 1. MLMランクの日本語名を正しく設定
UPDATE mlm_ranks SET 
    rank_name = CASE 
        WHEN rank_level = 0 THEN 'なし'
        WHEN rank_level = 1 THEN '足軽'
        WHEN rank_level = 2 THEN '武将'
        WHEN rank_level = 3 THEN '代官'
        WHEN rank_level = 4 THEN '奉行'
        WHEN rank_level = 5 THEN '老中'
        WHEN rank_level = 6 THEN '大老'
        WHEN rank_level = 7 THEN '大名'
        WHEN rank_level = 8 THEN '将軍'
        ELSE 'なし'
    END,
    distribution_rate = CASE 
        WHEN rank_level = 1 THEN 0.45  -- 45%
        WHEN rank_level = 2 THEN 0.25  -- 25%
        WHEN rank_level = 3 THEN 0.10  -- 10%
        WHEN rank_level = 4 THEN 0.06  -- 6%
        WHEN rank_level = 5 THEN 0.05  -- 5%
        WHEN rank_level = 6 THEN 0.04  -- 4%
        WHEN rank_level = 7 THEN 0.03  -- 3%
        WHEN rank_level = 8 THEN 0.02  -- 2%
        ELSE 0
    END,
    bonus_rate = CASE 
        WHEN rank_level = 1 THEN 0.45  -- 45%
        WHEN rank_level = 2 THEN 0.25  -- 25%
        WHEN rank_level = 3 THEN 0.10  -- 10%
        WHEN rank_level = 4 THEN 0.06  -- 6%
        WHEN rank_level = 5 THEN 0.05  -- 5%
        WHEN rank_level = 6 THEN 0.04  -- 4%
        WHEN rank_level = 7 THEN 0.03  -- 3%
        WHEN rank_level = 8 THEN 0.02  -- 2%
        ELSE 0
    END;

-- 2. 全ユーザーのランクを初期化
UPDATE users SET 
    current_rank = 'なし',
    current_rank_level = 0
WHERE current_rank IS NULL OR current_rank_level IS NULL;

-- 3. ユーザーランク計算関数を修正
DROP FUNCTION IF EXISTS determine_user_rank(UUID);

CREATE OR REPLACE FUNCTION determine_user_rank(p_user_id UUID)
RETURNS TABLE(
    user_id UUID,
    rank_level INTEGER,
    rank_name TEXT,
    nft_investment DECIMAL,
    organization_size INTEGER,
    max_line_size INTEGER,
    other_lines_total INTEGER
) AS $$
DECLARE
    user_nft_investment DECIMAL := 0;
    user_org_size INTEGER := 0;
    user_max_line INTEGER := 0;
    user_other_lines INTEGER := 0;
    calculated_rank INTEGER := 0;
    calculated_rank_name TEXT := 'なし';
BEGIN
    -- ユーザーのNFT投資額を計算
    SELECT COALESCE(SUM(un.purchase_price), 0) INTO user_nft_investment
    FROM user_nfts un
    WHERE un.user_id = p_user_id 
    AND un.is_active = true;
    
    -- 組織サイズを計算（直接・間接の紹介者全て）
    WITH RECURSIVE referral_tree AS (
        -- 直接紹介者
        SELECT id, referrer_id, 1 as level
        FROM users 
        WHERE referrer_id = p_user_id
        
        UNION ALL
        
        -- 間接紹介者
        SELECT u.id, u.referrer_id, rt.level + 1
        FROM users u
        JOIN referral_tree rt ON u.referrer_id = rt.id
        WHERE rt.level < 10 -- 無限ループ防止
    )
    SELECT COUNT(*) INTO user_org_size
    FROM referral_tree;
    
    -- 最大系列のサイズを計算
    WITH direct_referrals AS (
        SELECT id FROM users WHERE referrer_id = p_user_id
    ),
    line_sizes AS (
        SELECT 
            dr.id,
            (
                WITH RECURSIVE line_tree AS (
                    SELECT id, referrer_id, 1 as level
                    FROM users 
                    WHERE referrer_id = dr.id
                    
                    UNION ALL
                    
                    SELECT u.id, u.referrer_id, lt.level + 1
                    FROM users u
                    JOIN line_tree lt ON u.referrer_id = lt.id
                    WHERE lt.level < 10
                )
                SELECT COUNT(*) FROM line_tree
            ) as line_size
        FROM direct_referrals dr
    )
    SELECT COALESCE(MAX(line_size), 0) INTO user_max_line
    FROM line_sizes;
    
    -- その他系列の合計を計算
    user_other_lines := user_org_size - user_max_line;
    
    -- ランクを決定
    IF user_nft_investment >= 1000 THEN
        IF user_org_size >= 600000 AND user_max_line <= 500000 THEN
            calculated_rank := 8; -- 将軍
        ELSIF user_org_size >= 300000 AND user_max_line <= 150000 THEN
            calculated_rank := 7; -- 大名
        ELSIF user_org_size >= 100000 AND user_max_line <= 50000 THEN
            calculated_rank := 6; -- 大老
        ELSIF user_org_size >= 50000 AND user_max_line <= 25000 THEN
            calculated_rank := 5; -- 老中
        ELSIF user_org_size >= 10000 AND user_max_line <= 5000 THEN
            calculated_rank := 4; -- 奉行
        ELSIF user_org_size >= 5000 AND user_max_line <= 2500 THEN
            calculated_rank := 3; -- 代官
        ELSIF user_org_size >= 3000 AND user_max_line <= 1500 THEN
            calculated_rank := 2; -- 武将
        ELSIF user_org_size >= 1000 THEN
            calculated_rank := 1; -- 足軽
        END IF;
    END IF;
    
    -- ランク名を取得
    SELECT mr.rank_name INTO calculated_rank_name
    FROM mlm_ranks mr
    WHERE mr.rank_level = calculated_rank;
    
    IF calculated_rank_name IS NULL THEN
        calculated_rank_name := 'なし';
    END IF;
    
    RETURN QUERY SELECT 
        p_user_id,
        calculated_rank,
        calculated_rank_name,
        user_nft_investment,
        user_org_size,
        user_max_line,
        user_other_lines;
END;
$$ LANGUAGE plpgsql;

-- 4. 全ユーザーのランクを再計算
DO $$
DECLARE
    user_record RECORD;
    rank_result RECORD;
BEGIN
    FOR user_record IN 
        SELECT id, name FROM users 
        WHERE name IS NOT NULL 
        ORDER BY name
    LOOP
        -- ランクを計算
        SELECT * INTO rank_result
        FROM determine_user_rank(user_record.id);
        
        -- ユーザーテーブルを更新
        UPDATE users 
        SET current_rank = rank_result.rank_name,
            current_rank_level = rank_result.rank_level,
            updated_at = NOW()
        WHERE id = user_record.id;
        
        RAISE NOTICE 'ユーザー % のランクを更新: % (レベル%)', 
            user_record.name, rank_result.rank_name, rank_result.rank_level;
    END LOOP;
END $$;

-- 5. ランク統計を表示
SELECT 
    '📊 ランク別統計' as info,
    current_rank,
    COUNT(*) as user_count,
    SUM(COALESCE(total_earned, 0)) as total_earnings,
    AVG(COALESCE(total_earned, 0)) as avg_earnings
FROM users 
WHERE name IS NOT NULL
GROUP BY current_rank, current_rank_level
ORDER BY current_rank_level DESC;

-- 6. 上位ランクユーザーを表示
SELECT 
    '🏆 上位ランクユーザー' as info,
    name,
    current_rank,
    current_rank_level,
    COALESCE(total_earned, 0) as total_earned,
    COALESCE(pending_rewards, 0) as pending_rewards
FROM users 
WHERE current_rank_level > 0
AND name IS NOT NULL
ORDER BY current_rank_level DESC, total_earned DESC
LIMIT 20;

-- 7. MLMランク設定確認
SELECT 
    '⚙️ MLMランク設定確認' as info,
    rank_level,
    rank_name,
    required_nft_investment,
    required_organization_size,
    max_line_size,
    distribution_rate,
    bonus_rate
FROM mlm_ranks 
ORDER BY rank_level;

SELECT '✅ ランク表示修正とMLMシステム完全修正完了' as final_status;
