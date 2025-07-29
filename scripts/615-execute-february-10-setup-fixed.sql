-- 2025年2月10日週の設定実行（修正版）

-- 1. 事前バックアップ作成
SELECT 'Creating backup before February 10 setup...' as status;

SELECT create_weekly_rates_backup(
    '2025-02-10'::DATE,
    'Before February 10, 2025 setup'
);

-- 2. 既存設定削除（バックアップ付き）
SELECT 'Removing existing February 10 settings...' as status;

DELETE FROM group_weekly_rates 
WHERE week_start_date = '2025-02-10';

-- 3. グループ別週利設定実行
SELECT 'Setting up February 10 weekly rates...' as status;

-- 0.5%グループ: 1.5%
SELECT set_group_weekly_rate('2025-02-10', '0.5%グループ', 0.015);

-- 1.0%グループ: 2.0%
SELECT set_group_weekly_rate('2025-02-10', '1.0%グループ', 0.020);

-- 1.25%グループ: 2.3%
SELECT set_group_weekly_rate('2025-02-10', '1.25%グループ', 0.023);

-- 1.5%グループ: 2.6%
SELECT set_group_weekly_rate('2025-02-10', '1.5%グループ', 0.026);

-- 1.75%グループ: 2.9%
SELECT set_group_weekly_rate('2025-02-10', '1.75%グループ', 0.029);

-- 2.0%グループ: 3.2%
SELECT set_group_weekly_rate('2025-02-10', '2.0%グループ', 0.032);

-- 4. 設定結果確認
SELECT 'Verifying February 10 setup results...' as status;

SELECT 
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 2) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) as friday_percent,
    gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 5. 影響を受けるユーザー数確認
SELECT 'Checking affected users for February 10 week...' as status;

SELECT 
    drg.group_name,
    COUNT(DISTINCT un.user_id) as affected_users,
    COUNT(un.id) as active_nfts,
    SUM(un.purchase_amount) as total_investment
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE un.is_active = true
AND un.purchase_date <= '2025-02-14'  -- 金曜日まで
GROUP BY drg.id, drg.group_name
ORDER BY drg.daily_rate_limit;

-- 6. 週間予想報酬計算
SELECT 'Calculating estimated weekly rewards for February 10...' as status;

SELECT 
    drg.group_name,
    ROUND(SUM(un.purchase_amount * gwr.weekly_rate), 2) as estimated_weekly_rewards,
    ROUND(AVG(gwr.weekly_rate * 100), 2) as avg_weekly_rate_percent
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE un.is_active = true
AND un.purchase_date <= '2025-02-14'
AND gwr.week_start_date = '2025-02-10'
AND un.total_rewards_received < (un.purchase_amount * 3)
GROUP BY drg.id, drg.group_name
ORDER BY drg.daily_rate_limit;

-- 7. システム整合性チェック
SELECT 'Running system integrity check...' as status;

-- すべてのグループに設定があるかチェック
SELECT 
    drg.group_name,
    CASE WHEN gwr.id IS NOT NULL 
         THEN '✅ Configured' 
         ELSE '❌ Missing Configuration' 
    END as status
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
    AND gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

SELECT 'February 10, 2025 setup completed successfully!' as status;
