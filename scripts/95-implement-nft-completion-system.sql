-- NFT完了（300%達成）時の処理を実装

-- 1. NFT完了チェック関数
CREATE OR REPLACE FUNCTION check_and_complete_nfts()
RETURNS TABLE(
  completed_nft_id UUID,
  user_id UUID,
  nft_name TEXT,
  total_earned DECIMAL,
  completion_date TIMESTAMP
) AS $$
BEGIN
  -- 300%に達したNFTを特定し、非アクティブ化
  UPDATE user_nfts 
  SET 
    is_active = false,
    completion_date = CURRENT_TIMESTAMP
  WHERE 
    is_active = true 
    AND total_earned >= (current_investment * 3)
    AND completion_date IS NULL;

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

-- 2. completion_dateカラムを追加（存在しない場合）
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_nfts' AND column_name = 'completion_date'
  ) THEN
    ALTER TABLE user_nfts ADD COLUMN completion_date TIMESTAMP;
  END IF;
END $$;

-- 3. 日利計算時に300%チェックを行うトリガー関数を更新
CREATE OR REPLACE FUNCTION update_nft_earnings_and_check_completion()
RETURNS TRIGGER AS $$
DECLARE
  user_nft_record RECORD;
  max_earning DECIMAL;
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
  UPDATE user_nfts 
  SET total_earned = (
    SELECT COALESCE(SUM(reward_amount), 0)
    FROM daily_rewards 
    WHERE user_nft_id = NEW.user_nft_id
  )
  WHERE id = NEW.user_nft_id;
  
  -- 300%に達した場合、NFTを非アクティブ化
  UPDATE user_nfts 
  SET 
    is_active = false,
    completion_date = CURRENT_TIMESTAMP
  WHERE 
    id = NEW.user_nft_id 
    AND total_earned >= max_earning
    AND is_active = true;
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. トリガーを作成（存在しない場合）
DROP TRIGGER IF EXISTS trigger_update_nft_earnings ON daily_rewards;
CREATE TRIGGER trigger_update_nft_earnings
  AFTER INSERT OR UPDATE ON daily_rewards
  FOR EACH ROW
  EXECUTE FUNCTION update_nft_earnings_and_check_completion();

-- 5. 既存のNFTで300%に達しているものをチェック
SELECT check_and_complete_nfts();

SELECT 'NFT completion system implemented successfully' as status;
