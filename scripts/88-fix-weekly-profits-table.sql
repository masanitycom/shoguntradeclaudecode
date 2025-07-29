-- weekly_profitsテーブルにtenka_bonus_poolカラムを追加

ALTER TABLE weekly_profits 
ADD COLUMN IF NOT EXISTS tenka_bonus_pool DECIMAL(15,2) DEFAULT 0;

-- 既存レコードのtenka_bonus_poolを計算（総利益の20%）
UPDATE weekly_profits 
SET tenka_bonus_pool = total_profit * 0.20 
WHERE tenka_bonus_pool IS NULL OR tenka_bonus_pool = 0;

-- 確認
SELECT 
  week_start_date,
  total_profit,
  tenka_bonus_pool,
  (tenka_bonus_pool / total_profit * 100) as bonus_percentage
FROM weekly_profits
ORDER BY week_start_date DESC;
