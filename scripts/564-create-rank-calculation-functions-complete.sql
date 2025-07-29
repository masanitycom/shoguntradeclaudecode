-- ランク計算関数を実際のテーブル構造に合わせて作成（完全版）

-- 1. ユーザーのランクを決定する関数
CREATE OR REPLACE FUNCTION determine_user_rank(p_user_id UUID)
RETURNS TABLE(
    new_rank_level INTEGER,
    new_rank_name VARCHAR,
    nft_value DECIMAL,
    organization_size DECIMAL,
    max_line_size DECIMAL,
    other_lines_volume DECIMAL
) AS $$
DECLARE
    user_nft_value DECIMAL := 0;
    user_org_size DECIMAL := 0;
    user_max_line DECIMAL := 0;
    user_other_lines DECIMAL := 0;
    rank_record RECORD;
BEGIN
    -- ユーザーのNFT価値を計算
    SELECT COALESCE(SUM(purchase_price), 0)
    INTO user_nft_value
    FROM user_nfts 
    WHERE user_id = p_user_id AND is_active = true;
    
    -- 組織サイズを計算（紹介者のNFT投資額の合計）
    WITH RECURSIVE referral_tree AS (
        SELECT id, referrer_id, 1 as level
        FROM users 
        WHERE referrer_id = p_user_id
        
        UNION ALL
        
        SELECT u.id, u.referrer_id, rt.level + 1
        FROM users u
        JOIN referral_tree rt ON u.referrer_id = rt.id
        WHERE rt.level < 10 -- 無限ループ防止
    )
    SELECT COALESCE(SUM(
        COALESCE((
            SELECT SUM(purchase_price) 
            FROM user_nfts 
            WHERE user_id = rt.id AND is_active = true
        ), 0)
    ), 0)
    INTO user_org_size
    FROM referral_tree rt;
    
    -- 最大ライン計算（直接紹介者の中で最大の組織）
    WITH direct_referrals AS (
        SELECT id FROM users WHERE referrer_id = p_user_id
    ),
    line_sizes AS (
        SELECT 
            dr.id,
            COALESCE((
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
                SELECT SUM(
                    COALESCE((
                        SELECT SUM(purchase_price) 
                        FROM user_nfts 
                        WHERE user_id = lt.id AND is_active = true
                    ), 0)
                )
                FROM line_tree lt
            ), 0) as line_size
        FROM direct_referrals dr
    )
    SELECT COALESCE(MAX(line_size), 0) INTO user_max_line
    FROM line_sizes;
    
    -- その他ライン計算
    user_other_lines := user_org_size - user_max_line;
    
    -- 条件に合う最高ランクを決定
    SELECT mr.rank_level, mr.rank_name
    INTO new_rank_level, new_rank_name
    FROM mlm_ranks mr
    WHERE mr.required_nft_value <= user_nft_value
    AND mr.required_organization_size <= user_org_size
    AND (mr.max_line_size = 0 OR user_max_line <= mr.max_line_size)
    AND (mr.other_lines_volume = 0 OR user_other_lines >= mr.other_lines_volume)
    ORDER BY mr.rank_level DESC
    LIMIT 1;
    
    -- デフォルト値設定
    IF new_rank_level IS NULL THEN
        new_rank_level := 0;
        new_rank_name := 'なし';
    END IF;
    
    -- 結果を返す
    nft_value := user_nft_value;
    organization_size := user_org_size;
    max_line_size := user_max_line;
    other_lines_volume := user_other_lines;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- 2. 全ユーザーのランクを更新する関数
CREATE OR REPLACE FUNCTION update_all_user_ranks()
RETURNS TABLE(
    user_id UUID,
    user_name VARCHAR,
    old_rank VARCHAR,
    new_rank VARCHAR,
    rank_changed BOOLEAN,
    nft_value DECIMAL,
    org_size DECIMAL
) AS $$
DECLARE
    user_record RECORD;
    rank_result RECORD;
BEGIN
    FOR user_record IN 
        SELECT id, name, current_rank, current_rank_level 
        FROM users 
        WHERE name IS NOT NULL
        ORDER BY name
    LOOP
        -- ランクを計算
        SELECT * INTO rank_result 
        FROM determine_user_rank(user_record.id);
        
        -- ランクが変更された場合のみ更新
        IF rank_result.new_rank_level != COALESCE(user_record.current_rank_level, 0) THEN
            -- usersテーブルを更新
            UPDATE users 
            SET 
                current_rank = rank_result.new_rank_name,
                current_rank_level = rank_result.new_rank_level,
                updated_at = NOW()
            WHERE id = user_record.id;
            
            -- user_rank_historyに記録
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
                organization_volume_at_time,
                created_at
            ) VALUES (
                user_record.id,
                rank_result.new_rank_level,
                rank_result.new_rank_name,
                rank_result.organization_size,
                rank_result.max_line_size,
                rank_result.other_lines_volume,
                CURRENT_DATE,
                true,
                rank_result.nft_value,
                rank_result.organization_size,
                NOW()
            );
            
            -- 結果を返す
            user_id := user_record.id;
            user_name := user_record.name;
            old_rank := user_record.current_rank;
            new_rank := rank_result.new_rank_name;
            rank_changed := true;
            nft_value := rank_result.nft_value;
            org_size := rank_result.organization_size;
            
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. 関数をテスト
SELECT '🧪 ランク計算関数テスト' as section;

SELECT * FROM update_all_user_ranks();

-- 4. ランク統計を表示
SELECT 
    '📊 ランク更新後統計' as section,
    current_rank,
    current_rank_level,
    COUNT(*) as user_count,
    SUM(COALESCE(total_earned, 0)) as total_earnings,
    AVG(COALESCE(total_earned, 0)) as avg_earnings
FROM users 
WHERE name IS NOT NULL
GROUP BY current_rank, current_rank_level
ORDER BY current_rank_level DESC;

SELECT '✅ ランク計算関数作成完了（完全版）' as final_status;
