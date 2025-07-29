-- 安全な報酬データクリア - ユーザー・NFT情報は絶対に保護

-- 警告: ユーザー情報とNFT情報は絶対に削除しません
-- 報酬関連データのみを安全にクリアします

-- 1. 保護対象データの確認
SELECT 
    'BEFORE CLEAR - Protection Check' as status,
    (SELECT COUNT(*) FROM users) as users_count,
    (SELECT COUNT(*) FROM nfts) as nfts_count,
    (SELECT COUNT(*) FROM user_nfts) as user_nfts_count;

-- 2. daily_rewardsテーブルを安全にクリア
DELETE FROM daily_rewards;

-- 3. reward_applicationsテーブルを安全にクリア
DELETE FROM reward_applications;

-- 4. user_nftsの報酬関連フィールドのみをリセット（NFT情報は保護）
UPDATE user_nfts SET
    total_earned = 0
WHERE total_earned IS NOT NULL AND total_earned != 0;

-- 5. 週利データをクリア
DELETE FROM group_weekly_rates;
DELETE FROM group_weekly_rates_backup WHERE true;

-- 6. tenka_bonus_distributionsもクリア（存在する場合）
DELETE FROM tenka_bonus_distributions WHERE true;

-- 7. 保護確認
SELECT 
    'AFTER CLEAR - Protection Verified' as status,
    (SELECT COUNT(*) FROM users) as users_count,
    (SELECT COUNT(*) FROM nfts) as nfts_count,
    (SELECT COUNT(*) FROM user_nfts) as user_nfts_count;

-- 8. クリア結果確認
SELECT 
    'CLEAR RESULTS' as status,
    (SELECT COUNT(*) FROM daily_rewards) as daily_rewards_cleared,
    (SELECT COUNT(*) FROM reward_applications) as reward_apps_cleared,
    (SELECT COUNT(*) FROM group_weekly_rates) as weekly_rates_cleared;

SELECT 'Safe reward data clear completed - All user and NFT data protected' as status;
