-- 🚨 300%キャップトリガー関数の変数名曖昧性を修正

-- 依存関係を考慮してトリガーを先に削除
DROP TRIGGER IF EXISTS trigger_check_300_percent_cap ON daily_rewards;
DROP TRIGGER IF EXISTS trigger_300_percent_cap ON daily_rewards;

-- 既存の関数を削除（CASCADE使用）
DROP FUNCTION IF EXISTS check_300_percent_cap() CASCADE;

-- 修正された300%キャップチェック関数
CREATE OR REPLACE FUNCTION check_300_percent_cap()
RETURNS TRIGGER AS $$
DECLARE
    user_nft_record RECORD;
    current_total DECIMAL(10,2);
    cap_amount DECIMAL(10,2);
BEGIN
    -- user_nftsテーブルから情報を取得（テーブル名を明示）
    SELECT 
        un.id,
        un.user_id,
        un.nft_id,
        un.purchase_price,
        un.total_earned
    INTO user_nft_record
    FROM user_nfts un
    WHERE un.id = NEW.user_nft_id;
    
    -- レコードが見つからない場合はそのまま挿入
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;
    
    -- 300%キャップ計算
    cap_amount := user_nft_record.purchase_price * 3.0;
    
    -- 現在の累計報酬を計算
    current_total := COALESCE(user_nft_record.total_earned, 0) + NEW.reward_amount;
    
    -- 300%を超える場合は調整
    IF current_total > cap_amount THEN
        -- 残り報酬額を計算
        NEW.reward_amount := GREATEST(0, cap_amount - COALESCE(user_nft_record.total_earned, 0));
        
        -- NFTを非アクティブ化
        UPDATE user_nfts 
        SET 
            is_active = false,
            total_earned = cap_amount,
            updated_at = NOW()
        WHERE id = NEW.user_nft_id;
        
        -- 報酬が0以下の場合は挿入をキャンセル
        IF NEW.reward_amount <= 0 THEN
            RETURN NULL;
        END IF;
    ELSE
        -- 累計報酬を更新
        UPDATE user_nfts 
        SET 
            total_earned = current_total,
            updated_at = NOW()
        WHERE id = NEW.user_nft_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガーを再作成
CREATE TRIGGER trigger_check_300_percent_cap
    BEFORE INSERT ON daily_rewards
    FOR EACH ROW
    EXECUTE FUNCTION check_300_percent_cap();

-- 修正完了メッセージ
SELECT '300%キャップトリガー関数が修正されました！' as "修正結果";
