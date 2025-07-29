-- 複利運用システムを実装

-- 1. 複利運用テーブルを作成
CREATE TABLE IF NOT EXISTS compound_investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  original_reward_amount DECIMAL(10,2) NOT NULL,
  compound_amount DECIMAL(10,2) NOT NULL,
  fee_rate DECIMAL(5,4) NOT NULL, -- 手数料率 (0.055 = 5.5%)
  fee_amount DECIMAL(10,2) NOT NULL,
  net_compound_amount DECIMAL(10,2) NOT NULL, -- 手数料差し引き後
  compound_date DATE NOT NULL DEFAULT CURRENT_DATE,
  week_start_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 複利運用履歴テーブル
CREATE TABLE IF NOT EXISTS compound_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  compound_investment_id UUID REFERENCES compound_investments(id),
  action_type VARCHAR(50) NOT NULL, -- 'AUTO_COMPOUND', 'MANUAL_COMPOUND'
  amount DECIMAL(10,2) NOT NULL,
  fee_amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 未申請報酬の複利運用関数
CREATE OR REPLACE FUNCTION process_compound_interest(
  target_week_start DATE DEFAULT CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1
)
RETURNS TABLE(
  user_id UUID,
  user_name VARCHAR(255),
  unclaimed_amount DECIMAL,
  fee_rate DECIMAL,
  fee_amount DECIMAL,
  compound_amount DECIMAL
) AS $$
DECLARE
  user_record RECORD;
  unclaimed_rewards DECIMAL;
  user_fee_rate DECIMAL;
  calculated_fee DECIMAL;
  net_compound DECIMAL;
BEGIN
  -- 各ユーザーの未申請報酬を処理
  FOR user_record IN 
    SELECT DISTINCT u.id, u.name, u.user_id
    FROM users u
    WHERE u.is_active = true
  LOOP
    -- 未申請報酬を計算
    SELECT COALESCE(total_amount, 0) INTO unclaimed_rewards
    FROM get_user_pending_rewards(user_record.id);
    
    -- 未申請報酬がない場合はスキップ
    IF unclaimed_rewards <= 0 THEN
      CONTINUE;
    END IF;
    
    -- 手数料率を決定（EVOカード保有者は5.5%、その他は8%）
    SELECT CASE 
      WHEN EXISTS (
        SELECT 1 FROM user_nfts un 
        JOIN nfts n ON un.nft_id = n.id 
        WHERE un.user_id = user_record.id 
          AND n.name ILIKE '%EVO%' 
          AND un.is_active = true
      ) THEN 0.055
      ELSE 0.08
    END INTO user_fee_rate;
    
    -- 手数料を計算
    calculated_fee := unclaimed_rewards * user_fee_rate;
    net_compound := unclaimed_rewards - calculated_fee;
    
    -- 複利投資記録を作成
    INSERT INTO compound_investments (
      user_id,
      original_reward_amount,
      compound_amount,
      fee_rate,
      fee_amount,
      net_compound_amount,
      week_start_date
    ) VALUES (
      user_record.id,
      unclaimed_rewards,
      unclaimed_rewards,
      user_fee_rate,
      calculated_fee,
      net_compound,
      target_week_start
    );
    
    -- 複利履歴を記録
    INSERT INTO compound_history (
      user_id,
      action_type,
      amount,
      fee_amount,
      description
    ) VALUES (
      user_record.id,
      'AUTO_COMPOUND',
      net_compound,
      calculated_fee,
      '週次自動複利運用: ' || target_week_start::TEXT
    );
    
    -- 未申請報酬をクリア（claimed状態にする）
    UPDATE daily_rewards 
    SET is_claimed = true 
    WHERE user_nft_id IN (
      SELECT id FROM user_nfts WHERE user_id = user_record.id
    ) AND is_claimed = false;
    
    -- 結果を返す
    user_id := user_record.id;
    user_name := user_record.name;
    unclaimed_amount := unclaimed_rewards;
    fee_rate := user_fee_rate;
    fee_amount := calculated_fee;
    compound_amount := net_compound;
    
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. ユーザーの複利投資額を取得する関数
CREATE OR REPLACE FUNCTION get_user_compound_investments(user_id_param UUID)
RETURNS TABLE(
  total_compound_amount DECIMAL,
  total_fee_paid DECIMAL,
  compound_count INTEGER,
  last_compound_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(ci.net_compound_amount), 0) as total_compound_amount,
    COALESCE(SUM(ci.fee_amount), 0) as total_fee_paid,
    COUNT(ci.id)::INTEGER as compound_count,
    MAX(ci.compound_date) as last_compound_date
  FROM compound_investments ci
  WHERE ci.user_id = user_id_param;
END;
$$ LANGUAGE plpgsql;

-- 5. 複利投資をユーザーの投資額に反映する関数
CREATE OR REPLACE FUNCTION apply_compound_to_investments()
RETURNS INTEGER AS $$
DECLARE
  compound_record RECORD;
  applied_count INTEGER := 0;
BEGIN
  -- 未適用の複利投資を取得
  FOR compound_record IN 
    SELECT ci.*, u.name as user_name
    FROM compound_investments ci
    JOIN users u ON ci.user_id = u.id
    WHERE ci.compound_date = CURRENT_DATE
      AND NOT EXISTS (
        SELECT 1 FROM compound_history ch 
        WHERE ch.compound_investment_id = ci.id 
          AND ch.action_type = 'APPLIED_TO_INVESTMENT'
      )
  LOOP
    -- 最新のアクティブNFTに複利額を追加
    UPDATE user_nfts 
    SET 
      current_investment = current_investment + compound_record.net_compound_amount,
      max_earning = (current_investment + compound_record.net_compound_amount) * 3,
      updated_at = CURRENT_TIMESTAMP
    WHERE user_id = compound_record.user_id 
      AND is_active = true
    ORDER BY purchase_date DESC
    LIMIT 1;
    
    -- 適用履歴を記録
    INSERT INTO compound_history (
      user_id,
      compound_investment_id,
      action_type,
      amount,
      fee_amount,
      description
    ) VALUES (
      compound_record.user_id,
      compound_record.id,
      'APPLIED_TO_INVESTMENT',
      compound_record.net_compound_amount,
      compound_record.fee_amount,
      '複利投資額をNFTに適用: $' || compound_record.net_compound_amount::TEXT
    );
    
    applied_count := applied_count + 1;
  END LOOP;
  
  RETURN applied_count;
END;
$$ LANGUAGE plpgsql;

-- インデックスを作成
CREATE INDEX IF NOT EXISTS idx_compound_investments_user_id ON compound_investments(user_id);
CREATE INDEX IF NOT EXISTS idx_compound_investments_date ON compound_investments(compound_date);
CREATE INDEX IF NOT EXISTS idx_compound_history_user_id ON compound_history(user_id);

SELECT 'Compound interest system created successfully' as status;
