-- 緊急ユーザーデータ同期

-- 1. 日利計算関数が存在するか確認し、なければ作成
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'calculate_daily_rewards_batch'
  ) THEN
    -- 日利計算関数を作成
    EXECUTE '
    CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch(
      p_calculation_date DATE DEFAULT CURRENT_DATE
    ) RETURNS TABLE(
      message TEXT,
      processed_count INTEGER,
      total_rewards DECIMAL,
      completed_nfts INTEGER,
      error_message TEXT
    ) AS $func$
    DECLARE
      calc_date DATE := p_calculation_date;
      day_of_week INTEGER;
      processed_count INTEGER := 0;
      total_amount DECIMAL := 0;
      completed_count INTEGER := 0;
      error_msg TEXT := NULL;
    BEGIN
      -- 曜日を取得（0=日曜、1=月曜、...、6=土曜）
      day_of_week := EXTRACT(DOW FROM calc_date);
      
      -- 平日のみ処理（月〜金：1-5）
      IF day_of_week NOT BETWEEN 1 AND 5 THEN
        RETURN QUERY SELECT 
          ''土日は日利計算を行いません''::TEXT,
          0::INTEGER,
          0::DECIMAL,
          0::INTEGER,
          NULL::TEXT;
        RETURN;
      END IF;

      BEGIN
        -- 今日の既存レコードを削除
        DELETE FROM daily_rewards WHERE reward_date = calc_date;
        
        -- 日利計算を実行
        WITH week_rates_check AS (
          SELECT 
            gwr.group_id,
            gwr.week_start_date,
            gwr.week_end_date,
            gwr.monday_rate,
            gwr.tuesday_rate,
            gwr.wednesday_rate,
            gwr.thursday_rate,
            gwr.friday_rate,
            drg.group_name,
            drg.daily_rate_limit
          FROM group_weekly_rates gwr
          JOIN daily_rate_groups drg ON gwr.group_id = drg.id
          WHERE calc_date BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
        ),
        user_nft_data AS (
          SELECT 
            un.user_id,
            un.nft_id,
            un.current_investment,
            n.name as nft_name,
            n.daily_rate_limit,
            wrc.group_id,
            wrc.group_name,
            CASE 
              WHEN day_of_week = 1 THEN wrc.monday_rate
              WHEN day_of_week = 2 THEN wrc.tuesday_rate
              WHEN day_of_week = 3 THEN wrc.wednesday_rate
              WHEN day_of_week = 4 THEN wrc.thursday_rate
              WHEN day_of_week = 5 THEN wrc.friday_rate
              ELSE 0
            END as daily_rate
          FROM user_nfts un
          JOIN nfts n ON un.nft_id = n.id
          JOIN week_rates_check wrc ON n.daily_rate_limit = wrc.daily_rate_limit
          WHERE un.is_active = true
            AND un.current_investment > 0
            AND n.is_active = true
        ),
        reward_calculation AS (
          SELECT 
            user_id,
            nft_id,
            current_investment,
            nft_name,
            daily_rate_limit,
            daily_rate,
            LEAST(daily_rate, daily_rate_limit) as effective_rate,
            current_investment * LEAST(daily_rate, daily_rate_limit) as reward_amount
          FROM user_nft_data
          WHERE daily_rate > 0
        )
        INSERT INTO daily_rewards (
          user_id,
          nft_id,
          reward_date,
          purchase_amount,
          daily_rate,
          reward_amount,
          is_claimed,
          created_at
        )
        SELECT 
          user_id,
          nft_id,
          calc_date,
          current_investment,
          effective_rate,
          reward_amount,
          false,
          NOW()
        FROM reward_calculation;
        
        -- 処理件数を取得
        GET DIAGNOSTICS processed_count = ROW_COUNT;
        
        -- 合計金額を計算
        SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
        FROM daily_rewards 
        WHERE reward_date = calc_date;
        
        -- 完了NFT数を計算（300%達成）
        SELECT COUNT(*) INTO completed_count
        FROM user_nfts un
        WHERE un.total_earned >= un.max_earning
          AND un.is_active = true;
        
      EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        processed_count := 0;
        total_amount := 0;
        completed_count := 0;
      END;
      
      RETURN QUERY SELECT 
        CASE 
          WHEN error_msg IS NOT NULL THEN format(''エラーが発生しました: %s'', error_msg)
          WHEN processed_count > 0 THEN format(''%s の日利計算が完了しました'', calc_date)
          ELSE ''処理対象のNFTがありませんでした''
        END::TEXT,
        processed_count::INTEGER,
        total_amount::DECIMAL,
        completed_count::INTEGER,
        error_msg::TEXT;
    END;
    $func$ LANGUAGE plpgsql;';
    
    RAISE NOTICE '日利計算関数を作成しました';
  END IF;
END $$;

-- 2. 今日の日利計算を強制実行
SELECT 'Executing Daily Calculation for Today' as status;
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 3. 過去1週間分の日利計算を実行（平日のみ）
DO $$
DECLARE
  calc_date DATE;
  day_of_week INTEGER;
  result_record RECORD;
BEGIN
  -- 過去7日間をチェック
  FOR i IN 0..6 LOOP
    calc_date := CURRENT_DATE - i;
    day_of_week := EXTRACT(DOW FROM calc_date);
    
    -- 平日のみ処理
    IF day_of_week BETWEEN 1 AND 5 THEN
      RAISE NOTICE '日利計算実行: %', calc_date;
      
      -- 日利計算を実行
      FOR result_record IN 
        SELECT * FROM calculate_daily_rewards_batch(calc_date)
      LOOP
        RAISE NOTICE '結果: % - 処理件数: %', calc_date, result_record.processed_count;
      END LOOP;
    END IF;
  END LOOP;
END $$;

-- 4. user_nftsのtotal_earnedを更新（claimed報酬のみ）
UPDATE user_nfts 
SET total_earned = (
  SELECT COALESCE(SUM(dr.reward_amount), 0)
  FROM daily_rewards dr
  WHERE dr.user_id = user_nfts.user_id
    AND dr.nft_id = user_nfts.nft_id
    AND dr.is_claimed = true
),
updated_at = NOW()
WHERE is_active = true;

-- 5. max_earningが正しく設定されているか確認・修正
UPDATE user_nfts 
SET 
  max_earning = current_investment * 3.0,
  updated_at = NOW()
WHERE is_active = true 
  AND (max_earning IS NULL OR max_earning = 0);

-- 6. 300%達成したNFTを非アクティブ化
UPDATE user_nfts 
SET 
  is_active = false,
  completion_date = CURRENT_DATE,
  updated_at = NOW()
WHERE is_active = true 
  AND total_earned >= max_earning;

-- 7. 同期結果を確認
SELECT 
  'Sync Results' as result_type,
  COUNT(*) as total_active_nfts,
  COUNT(CASE WHEN total_earned > 0 THEN 1 END) as nfts_with_earnings,
  COUNT(CASE WHEN total_earned >= max_earning THEN 1 END) as completed_nfts,
  SUM(total_earned) as total_all_earnings,
  AVG(total_earned) as avg_earnings
FROM user_nfts
WHERE current_investment > 0;

-- 8. 保留中報酬の確認
SELECT 
  'Pending Rewards Check' as check_type,
  u.id as user_id,
  COALESCE(u.name, u.email) as user_name,
  COUNT(dr.id) as pending_reward_records,
  SUM(dr.reward_amount) as total_pending_amount
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.is_claimed = false
WHERE EXISTS (
  SELECT 1 FROM user_nfts un 
  WHERE un.user_id = u.id AND un.is_active = true
)
GROUP BY u.id, u.name, u.email
HAVING COUNT(dr.id) > 0
ORDER BY SUM(dr.reward_amount) DESC
LIMIT 10;

-- 9. ユーザー別の報酬サマリー
SELECT 
  'User Reward Summary' as summary_type,
  COALESCE(u.name, u.email) as user_name,
  COUNT(dr.id) as daily_reward_count,
  COALESCE(SUM(dr.reward_amount), 0) as total_pending_rewards,
  COALESCE(SUM(un.total_earned), 0) as total_earned_from_nfts
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.is_claimed = false
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE EXISTS (
  SELECT 1 FROM user_nfts un2 
  WHERE un2.user_id = u.id AND un2.is_active = true
)
GROUP BY u.id, u.name, u.email
ORDER BY total_pending_rewards DESC
LIMIT 15;

-- 10. システム全体の健全性チェック
SELECT 
  'System Health Check' as check_type,
  'Active Users' as metric,
  COUNT(DISTINCT u.id) as value
FROM users u
WHERE EXISTS (
  SELECT 1 FROM user_nfts un 
  WHERE un.user_id = u.id AND un.is_active = true
)

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Total Active NFTs' as metric,
  COUNT(*) as value
FROM user_nfts
WHERE is_active = true

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Total Daily Rewards Records' as metric,
  COUNT(*) as value
FROM daily_rewards

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Unclaimed Rewards Records' as metric,
  COUNT(*) as value
FROM daily_rewards
WHERE is_claimed = false;

-- 11. システム状況の最終確認
SELECT 
  'Final System Status' as status_type,
  'Active User NFTs' as metric,
  COUNT(*) as value
FROM user_nfts 
WHERE is_active = true AND current_investment > 0

UNION ALL

SELECT 
  'Final System Status' as status_type,
  'Daily Rewards Records' as metric,
  COUNT(*) as value
FROM daily_rewards

UNION ALL

SELECT 
  'Final System Status' as status_type,
  'Unclaimed Rewards' as metric,
  COUNT(*) as value
FROM daily_rewards
WHERE is_claimed = false

UNION ALL

SELECT 
  'Final System Status' as status_type,
  'Total Pending Amount' as metric,
  COALESCE(SUM(reward_amount), 0) as value
FROM daily_rewards
WHERE is_claimed = false;

-- 12. 特定ユーザーの詳細確認（上位10名）
SELECT 
  'Top Users After Sync' as check_type,
  COALESCE(u.name, u.email) as user_name,
  COUNT(un.id) as nft_count,
  SUM(un.current_investment) as total_investment,
  SUM(un.total_earned) as total_earned,
  COUNT(dr.id) as pending_rewards_count,
  COALESCE(SUM(dr.reward_amount), 0) as pending_amount
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.is_claimed = false
WHERE EXISTS (
  SELECT 1 FROM user_nfts un2 
  WHERE un2.user_id = u.id AND un2.is_active = true
)
GROUP BY u.id, u.name, u.email
ORDER BY pending_amount DESC
LIMIT 10;
