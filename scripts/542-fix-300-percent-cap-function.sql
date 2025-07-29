-- check_300_percent_cap関数を修正

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS check_300_percent_cap() CASCADE;

-- 2. 修正版の関数を作成
CREATE OR REPLACE FUNCTION check_300_percent_cap()
RETURNS TRIGGER AS $$
DECLARE
    current_total DECIMAL(10,2);
    max_earnings DECIMAL(10,2);
    purchase_price DECIMAL(10,2);
    user_nft_record RECORD;
BEGIN
    -- NEW.user_nft_idがNULLの場合はエラー
    IF NEW.user_nft_id IS NULL THEN
        RAISE EXCEPTION 'user_nft_id cannot be NULL';
    END IF;
    
    -- user_nftsレコードを取得
    SELECT 
        id,
        user_id,
        nft_id,
        purchase_price,
        total_earned
    INTO user_nft_record
    FROM user_nfts 
    WHERE id = NEW.user_nft_id;
    
    -- user_nftsレコードが見つからない場合
    IF NOT FOUND THEN
        RAISE EXCEPTION 'user_nft_id <%> が見つかりません', NEW.user_nft_id;
    END IF;
    
    -- purchase_priceを取得
    purchase_price := user_nft_record.purchase_price;
    
    -- purchase_priceがNULLまたは0の場合はスキップ
    IF purchase_price IS NULL OR purchase_price <= 0 THEN
        RAISE WARNING 'user_nft_id <%> の purchase_price が無効です: %', NEW.user_nft_id, purchase_price;
        RETURN NEW;
    END IF;
    
    -- 最大収益を計算（300%）
    max_earnings := purchase_price * 3;
    
    -- 現在の累計収益を取得
    current_total := COALESCE(user_nft_record.total_earned, 0);
    
    -- 新しい報酬を加えた場合の累計
    current_total := current_total + NEW.reward_amount;
    
    -- 300%を超える場合は調整
    IF current_total > max_earnings THEN
        -- 報酬額を調整
        NEW.reward_amount := max_earnings - COALESCE(user_nft_record.total_earned, 0);
        
        -- 調整後の報酬額が0以下の場合は挿入をキャンセル
        IF NEW.reward_amount <= 0 THEN
            RAISE NOTICE 'user_nft_id <%> は既に300%%に達しているため、報酬をスキップします', NEW.user_nft_id;
            RETURN NULL; -- 挿入をキャンセル
        END IF;
        
        RAISE NOTICE 'user_nft_id <%> の報酬を % に調整しました（300%%上限適用）', NEW.user_nft_id, NEW.reward_amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. トリガーを再作成
DROP TRIGGER IF EXISTS trigger_300_percent_cap ON daily_rewards;
CREATE TRIGGER trigger_300_percent_cap
    BEFORE INSERT OR UPDATE ON daily_rewards
    FOR EACH ROW
    EXECUTE FUNCTION check_300_percent_cap();

-- 4. 関数の動作確認
SELECT 
    '✅ check_300_percent_cap関数修正完了' as status,
    'トリガーも再作成されました' as message;
