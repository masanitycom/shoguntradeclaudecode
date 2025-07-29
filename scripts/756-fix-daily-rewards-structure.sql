-- daily_rewardsテーブルに不足しているカラムを追加

-- 1. daily_rewardsテーブルに必要なカラムを追加
ALTER TABLE daily_rewards 
ADD COLUMN IF NOT EXISTS daily_rate NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS weekly_rate NUMERIC DEFAULT 0;

-- 2. インデックスを追加（パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_daily_rewards_reward_date ON daily_rewards(reward_date);
CREATE INDEX IF NOT EXISTS idx_daily_rewards_user_id ON daily_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_rewards_user_nft_id ON daily_rewards(user_nft_id);

-- 3. テーブル構造の確認
SELECT 
    '=== 修正後 daily_rewards テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '✅ daily_rewardsテーブル構造修正完了' as status;
