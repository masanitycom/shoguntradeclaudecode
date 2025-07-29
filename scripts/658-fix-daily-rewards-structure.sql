-- 🚨 daily_rewards テーブル構造を修正

SELECT '=== daily_rewards テーブル構造修正開始 ===' as "修正開始";

-- daily_rate カラムの NOT NULL 制約を削除
ALTER TABLE daily_rewards 
ALTER COLUMN daily_rate DROP NOT NULL;

-- 既存のNULLデータにデフォルト値を設定
UPDATE daily_rewards 
SET daily_rate = 0.01 
WHERE daily_rate IS NULL;

-- 修正結果を確認
SELECT 
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND column_name = 'daily_rate'
AND table_schema = 'public';

SELECT 'daily_rewards テーブル構造が修正されました！' as "修正結果";
