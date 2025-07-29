-- 孤立した報酬データの緊急クリーンアップ

-- 1. バックアップテーブル作成
CREATE TABLE IF NOT EXISTS daily_rewards_backup_emergency AS 
SELECT * FROM daily_rewards;

-- 2. 週利設定が存在しない期間の報酬を特定
WITH orphaned_rewards AS (
    SELECT dr.id, dr.reward_date, dr.user_id, dr.reward_amount
    FROM daily_rewards dr
    LEFT JOIN group_weekly_rates gwr ON (
        dr.reward_date >= gwr.week_start_date 
        AND dr.reward_date < gwr.week_start_date + INTERVAL '7 days'
    )
    WHERE gwr.id IS NULL
)
SELECT 
    COUNT(*) as orphaned_count,
    SUM(reward_amount) as orphaned_amount,
    MIN(reward_date) as earliest_orphaned,
    MAX(reward_date) as latest_orphaned
FROM orphaned_rewards;

-- 3. 孤立した報酬データを削除
DELETE FROM daily_rewards 
WHERE id IN (
    SELECT dr.id
    FROM daily_rewards dr
    LEFT JOIN group_weekly_rates gwr ON (
        dr.reward_date >= gwr.week_start_date 
        AND dr.reward_date < gwr.week_start_date + INTERVAL '7 days'
    )
    WHERE gwr.id IS NULL
);

-- 4. user_nftsに対応しない報酬データを削除
DELETE FROM daily_rewards 
WHERE user_nft_id NOT IN (
    SELECT id FROM user_nfts WHERE is_active = true
);

-- 5. 削除後の状況確認
SELECT 
    COUNT(*) as remaining_rewards,
    SUM(reward_amount) as remaining_amount,
    MIN(reward_date) as earliest_remaining,
    MAX(reward_date) as latest_remaining
FROM daily_rewards;

-- 6. バックアップ情報表示
SELECT 
    COUNT(*) as backup_count,
    SUM(reward_amount) as backup_amount
FROM daily_rewards_backup_emergency;
