-- ランク計算関数を実際のテーブル構造に合わせて作成

-- 1. ユーザーのランクを決定する関数（簡易版）
CREATE OR REPLACE FUNCTION determine_user_rank(p_user_id UUID)
RETURNS TABLE(
    new_rank_level INTEGER,
    new_rank_name VARCHAR,
    nft_value DECIMAL
) AS $$
DECLARE
    user_nft_value DECIMAL := 0;
    rank_record RECORD;
BEGIN
    -- ユーザーのNFT価値を計算
    SELECT COALESCE(SUM(purchase_price), 0)
    INTO user_nft_value
    FROM user_nfts 
    WHERE user_id = p_user_id AND is_active = true;
    
    -- 条件に合う最高ランクを決定（NFT価値のみで判定）
    SELECT mr.rank_level, mr.rank_name
    INTO new_rank_level, new_rank_name
    FROM mlm_ranks mr
    WHERE mr.required_nft_value <= user_nft_value
    ORDER BY mr.rank_level DESC
    LIMIT 1;
    
    -- デフォルト値設定
    IF new_rank_level IS NULL THEN
        new_rank_level := 0;
        new_rank_name := 'なし';
    END IF;
    
    -- 結果を返す
    nft_value := user_nft_value;
    
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
    rank_changed BOOLEAN
) AS $$
DECLARE
    user_record RECORD;
    rank_result RECORD;
BEGIN
    FOR user_record IN 
        SELECT id, name, current_rank, current_rank_level 
        FROM users 
        WHERE name IS NOT NULL
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
                0, -- 組織ボリューム（後で実装）
                0, -- 最大ライン（後で実装）
                0, -- その他ライン（後で実装）
                CURRENT_DATE,
                true,
                rank_result.nft_value,
                0, -- 組織ボリューム（後で実装）
                NOW()
            );
            
            -- 結果を返す
            user_id := user_record.id;
            user_name := user_record.name;
            old_rank := user_record.current_rank;
            new_rank := rank_result.new_rank_name;
            rank_changed := true;
            
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. 関数をテスト
SELECT '🧪 ランク計算関数テスト' as section;

SELECT * FROM update_all_user_ranks();

SELECT '✅ ランク計算関数作成完了' as final_status;
