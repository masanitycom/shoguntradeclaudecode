-- 失われた週利設定の調査と復元

-- 1. 現在の状況確認
SELECT 
    '📊 現在の週利設定状況' as section,
    COUNT(*) as total_settings,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 2. 現在残っている設定の詳細
SELECT 
    '🔍 残存設定の詳細' as section,
    week_start_date,
    week_end_date,
    group_name,
    weekly_rate * 100 as weekly_percent,
    distribution_method,
    created_at
FROM group_weekly_rates
ORDER BY week_start_date, group_name;

-- 3. バックアップテーブルの確認
SELECT 
    '💾 バックアップ状況確認' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates_backup')
        THEN 'バックアップテーブル存在'
        ELSE 'バックアップテーブル無し'
    END as backup_table_status;

-- 4. もしバックアップテーブルが存在する場合の内容確認
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates_backup') THEN
        RAISE NOTICE 'バックアップテーブルが存在します。内容を確認中...';
        
        -- バックアップの件数確認
        PERFORM (SELECT COUNT(*) FROM group_weekly_rates_backup);
    ELSE
        RAISE NOTICE 'バックアップテーブルが存在しません。';
    END IF;
END $$;

-- 5. 日利計算履歴から週利設定の痕跡を探す
SELECT 
    '🔍 日利計算履歴から週利の痕跡を調査' as section,
    reward_date,
    COUNT(*) as reward_count,
    AVG(reward_amount) as avg_reward,
    SUM(reward_amount) as total_reward
FROM daily_rewards
WHERE reward_date >= '2025-01-01'
GROUP BY reward_date
ORDER BY reward_date DESC
LIMIT 10;

-- 6. ユーザーNFTの分布確認（どの週利グループが必要か判断）
SELECT 
    '📈 NFT分布による必要週利グループの推定' as section,
    drg.group_name,
    COUNT(un.id) as nft_count,
    SUM(n.price) as total_investment
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE un.is_active = true
GROUP BY drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
