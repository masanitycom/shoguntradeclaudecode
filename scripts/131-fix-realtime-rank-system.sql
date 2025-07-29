-- 1. 新規登録時の初期ランク設定関数
CREATE OR REPLACE FUNCTION set_initial_user_rank()
RETURNS TRIGGER AS $$
BEGIN
    -- 新規ユーザーに初期ランク（なし）を設定
    INSERT INTO user_rank_history (user_id, rank_level, rank_name, created_at)
    VALUES (NEW.id, 0, 'なし', NOW());
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. 新規登録時のトリガー作成
DROP TRIGGER IF EXISTS trigger_set_initial_rank ON users;
CREATE TRIGGER trigger_set_initial_rank
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_initial_user_rank();

-- 3. NFT購入時のリアルタイムランク更新関数
CREATE OR REPLACE FUNCTION update_user_rank_on_nft_purchase()
RETURNS TRIGGER AS $$
DECLARE
    user_nft_value NUMERIC;
    org_volume NUMERIC;
    max_line NUMERIC;
    other_lines NUMERIC;
    new_rank_level INTEGER;
    new_rank_name VARCHAR;
    current_rank_level INTEGER;
BEGIN
    -- ユーザーの現在のNFT価値を計算
    SELECT COALESCE(SUM(n.price), 0)
    INTO user_nft_value
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    WHERE un.user_id = NEW.user_id AND un.is_active = true;
    
    -- 組織ボリューム計算（簡略版）
    SELECT 
        COALESCE(SUM(total_volume), 0),
        COALESCE(MAX(total_volume), 0),
        COALESCE(SUM(total_volume) - MAX(total_volume), 0)
    INTO org_volume, max_line, other_lines
    FROM (
        SELECT 
            referrer_id,
            SUM(nft_value) as total_volume
        FROM (
            SELECT 
                u.referrer_id,
                COALESCE(SUM(n.price), 0) as nft_value
            FROM users u
            LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
            LEFT JOIN nfts n ON un.nft_id = n.id
            WHERE u.referrer_id = NEW.user_id
            GROUP BY u.id, u.referrer_id
        ) user_volumes
        GROUP BY referrer_id
    ) line_volumes;
    
    -- ランク判定
    SELECT rank_level, rank_name
    INTO new_rank_level, new_rank_name
    FROM mlm_ranks
    WHERE required_nft_value <= user_nft_value
      AND (max_organization_volume IS NULL OR org_volume >= max_organization_volume)
      AND (other_lines_volume IS NULL OR other_lines >= other_lines_volume)
    ORDER BY rank_level DESC
    LIMIT 1;
    
    -- 現在のランクを取得
    SELECT rank_level
    INTO current_rank_level
    FROM user_rank_history
    WHERE user_id = NEW.user_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- ランクが変更された場合のみ更新
    IF new_rank_level != current_rank_level THEN
        INSERT INTO user_rank_history (user_id, rank_level, rank_name, created_at)
        VALUES (NEW.user_id, new_rank_level, new_rank_name, NOW());
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. NFT購入時のトリガー作成
DROP TRIGGER IF EXISTS trigger_update_rank_on_nft_purchase ON user_nfts;
CREATE TRIGGER trigger_update_rank_on_nft_purchase
    AFTER INSERT OR UPDATE ON user_nfts
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rank_on_nft_purchase();

-- 5. 既存ユーザーの初期ランク設定
INSERT INTO user_rank_history (user_id, rank_level, rank_name, created_at)
SELECT 
    u.id,
    0,
    'なし',
    NOW()
FROM users u
WHERE u.id NOT IN (SELECT DISTINCT user_id FROM user_rank_history)
  AND u.is_admin = false;

-- 6. テスト用の新規ユーザー作成関数
CREATE OR REPLACE FUNCTION test_new_user_registration()
RETURNS TABLE(
    test_result TEXT,
    user_id UUID,
    initial_rank TEXT
) AS $$
DECLARE
    test_user_id UUID;
    test_rank TEXT;
BEGIN
    -- テスト用ユーザーID生成
    test_user_id := gen_random_uuid();
    
    -- テスト用ユーザー挿入（トリガーが動作）
    INSERT INTO users (
        id, name, email, user_id, phone, referrer_id, is_admin
    ) VALUES (
        test_user_id,
        'テストユーザー',
        'test@example.com',
        'testuser001',
        '090-0000-0000',
        (SELECT id FROM users WHERE user_id = 'ohtakiyo' LIMIT 1),
        false
    );
    
    -- 初期ランクを確認
    SELECT rank_name INTO test_rank
    FROM user_rank_history
    WHERE user_id = test_user_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    RETURN QUERY SELECT 
        'New user registration test'::TEXT,
        test_user_id,
        test_rank;
        
    -- テストユーザー削除
    DELETE FROM user_rank_history WHERE user_id = test_user_id;
    DELETE FROM users WHERE id = test_user_id;
END;
$$ LANGUAGE plpgsql;

-- 7. テスト実行
SELECT * FROM test_new_user_registration();

-- 8. 完了メッセージ
SELECT 'Realtime rank system implemented successfully' as status;
