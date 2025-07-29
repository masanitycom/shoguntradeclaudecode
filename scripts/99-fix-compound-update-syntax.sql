-- 複利投資をユーザーの投資額に反映する関数（修正版）

CREATE OR REPLACE FUNCTION apply_compound_to_investments()
RETURNS INTEGER AS $$
DECLARE
  compound_record RECORD;
  target_nft_id UUID;
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
    -- 最新のアクティブNFTのIDを取得
    SELECT id INTO target_nft_id
    FROM user_nfts 
    WHERE user_id = compound_record.user_id 
      AND is_active = true
    ORDER BY purchase_date DESC
    LIMIT 1;
    
    -- 対象NFTが存在する場合のみ更新
    IF target_nft_id IS NOT NULL THEN
      -- 複利額を追加
      UPDATE user_nfts 
      SET 
        current_investment = current_investment + compound_record.net_compound_amount,
        max_earning = (current_investment + compound_record.net_compound_amount) * 3,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = target_nft_id;
      
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
    END IF;
  END LOOP;
  
  RETURN applied_count;
END;
$$ LANGUAGE plpgsql;

SELECT 'Compound update syntax fixed successfully' as status;
