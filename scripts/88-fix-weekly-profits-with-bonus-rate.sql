-- weekly_profitsテーブルにカラム追加
ALTER TABLE weekly_profits 
ADD COLUMN IF NOT EXISTS tenka_bonus_pool DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS bonus_percentage DECIMAL(5,2) DEFAULT 20.00;

-- 既存レコードのデフォルト値設定
UPDATE weekly_profits 
SET 
  tenka_bonus_pool = total_profit * 0.20,
  bonus_percentage = 20.00
WHERE tenka_bonus_pool IS NULL OR tenka_bonus_pool = 0;

-- 確認
SELECT 
  week_start_date,
  total_profit,
  bonus_percentage,
  tenka_bonus_pool,
  (tenka_bonus_pool / total_profit * 100) as calculated_percentage
FROM weekly_profits
ORDER BY week_start_date DESC;

-- ボーナス率選択肢の確認
SELECT 
  'Available bonus rates:' as info,
  '20%, 22%, 25%, 30%' as options;
