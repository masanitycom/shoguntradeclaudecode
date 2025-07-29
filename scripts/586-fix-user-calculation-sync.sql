-- ユーザー計算の同期修正

-- 1. user_nftsのtotal_earnedをdaily_rewardsから再計算
UPDATE user_nfts 
SET 
  total_earned = COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr
    WHERE dr.user_id = user_nfts.user_id 
      AND dr.user_nft_id = user_nfts.id
  ), 0),
  updated_at = NOW()
WHERE EXISTS (
  SELECT 1 FROM daily_rewards dr
  WHERE dr.user_id = user_nfts.user_id 
    AND dr.user_nft_id = user_nfts.id
);

-- 2. 300%達成チェックと完了処理
UPDATE user_nfts 
SET 
  is_active = false,
  completion_date = CURRENT_DATE,
  updated_at = NOW()
WHERE total_earned >= max_earning 
  AND is_active = true
  AND max_earning > 0;

-- 3. 今週の日利計算を強制実行（平日のみ）
DO $$
DECLARE
  current_day INTEGER;
  calculation_date DATE;
BEGIN
  -- 現在の曜日を取得（1=月曜日, 7=日曜日）
  current_day := EXTRACT(DOW FROM CURRENT_DATE);
  
  -- 平日（月〜金）の場合のみ実行
  IF current_day BETWEEN 1 AND 5 THEN
    calculation_date := CURRENT_DATE;
    
    -- 今日の日利計算を実行
    PERFORM calculate_daily_rewards_for_date(calculation_date);
    
    RAISE NOTICE '日利計算実行: %', calculation_date;
  ELSE
    RAISE NOTICE '週末のため日利計算をスキップ';
  END IF;
END $$;

-- 4. 計算結果の確認
SELECT 
  'Updated Calculation Results' as check_type,
  COUNT(*) as total_user_nfts,
  COUNT(CASE WHEN total_earned > 0 THEN 1 END) as nfts_with_earnings,
  SUM(total_earned) as total_all_earnings,
  AVG(total_earned) as avg_earnings,
  COUNT(CASE WHEN is_active = false AND completion_date IS NOT NULL THEN 1 END) as completed_nfts
FROM user_nfts
WHERE current_investment > 0;
