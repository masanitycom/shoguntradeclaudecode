-- NFT完了システムの型エラーを修正

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS check_and_complete_nfts();

-- 2. 正しい型で関数を再作成
CREATE OR REPLACE FUNCTION check_and_complete_nfts()
RETURNS TABLE(
  completed_nft_id UUID,
  user_id UUID,
  nft_name VARCHAR(255),  -- TEXTからVARCHAR(255)に変更
  total_earned DECIMAL,
  completion_date TIMESTAMP
) AS $$
BEGIN
  -- 300%に達したNFTを特定し、非アクティブ化
  UPDATE user_nfts un
  SET 
    is_active = false,
    completion_date = CURRENT_TIMESTAMP
  WHERE 
    un.is_active = true 
    AND un.total_earned >= (un.current_investment * 3)
    AND un.completion_date IS NULL;

  -- 完了したNFTの情報を返す
  RETURN QUERY
  SELECT 
    un.id as completed_nft_id,
    un.user_id,
    n.name as nft_name,
    un.total_earned,
    un.completion_date
  FROM user_nfts un
  JOIN nfts n ON un.nft_id = n.id
  WHERE 
    un.is_active = false 
    AND un.completion_date IS NOT NULL
    AND un.completion_date >= CURRENT_TIMESTAMP - INTERVAL '1 minute';
END;
$$ LANGUAGE plpgsql;

-- 3. completion_dateカラムを追加（存在しない場合）
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_nfts' AND column_name = 'completion_date'
  ) THEN
    ALTER TABLE user_nfts ADD COLUMN completion_date TIMESTAMP;
  END IF;
END $$;

-- 4. 日利計算時に300%チェックを行うトリガー関数を更新
CREATE OR REPLACE FUNCTION update_nft_earnings_and_check_completion()
RETURNS TRIGGER AS $$
DECLARE
  user_nft_record RECORD;
  max_earning DECIMAL;
  new_total_earned DECIMAL;
BEGIN
  -- user_nftの情報を取得
  SELECT * INTO user_nft_record 
  FROM user_nfts 
  WHERE id = NEW.user_nft_id;
  
  IF NOT FOUND THEN
    RETURN NEW;
  END IF;
  
  -- 300%上限を計算
  max_earning := user_nft_record.current_investment * 3;
  
  -- 新しい総収益を計算
  SELECT COALESCE(SUM(reward_amount), 0) INTO new_total_earned
  FROM daily_rewards 
  WHERE user_nft_id = NEW.user_nft_id;
  
  -- user_nftsテーブルを更新
  UPDATE user_nfts un
  SET total_earned = new_total_earned
  WHERE un.id = NEW.user_nft_id;
  
  -- 300%に達した場合、NFTを非アクティブ化
  IF new_total_earned >= max_earning THEN
    UPDATE user_nfts un
    SET 
      is_active = false,
      completion_date = CURRENT_TIMESTAMP
    WHERE 
      un.id = NEW.user_nft_id 
      AND un.is_active = true;
  END IF;
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. トリガーを作成（存在しない場合）
DROP TRIGGER IF EXISTS trigger_update_nft_earnings ON daily_rewards;
CREATE TRIGGER trigger_update_nft_earnings
  AFTER INSERT OR UPDATE ON daily_rewards
  FOR EACH ROW
  EXECUTE FUNCTION update_nft_earnings_and_check_completion();

-- 6. 既存のNFTで300%に達しているものをチェック
SELECT * FROM check_and_complete_nfts();

SELECT 'NFT completion system implemented successfully (type fixed)' as status;
