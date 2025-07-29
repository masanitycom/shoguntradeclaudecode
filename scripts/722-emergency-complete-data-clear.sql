-- 緊急完全データクリア - 全ての報酬関連データを削除

-- 1. 全ての報酬データを完全削除
DO $$
DECLARE
    deleted_rewards INTEGER;
    deleted_applications INTEGER;
    deleted_tenka_bonus INTEGER;
BEGIN
    -- daily_rewards テーブルを完全クリア
    DELETE FROM daily_rewards;
    GET DIAGNOSTICS deleted_rewards = ROW_COUNT;
    
    -- reward_applications テーブルを完全クリア
    DELETE FROM reward_applications;
    GET DIAGNOSTICS deleted_applications = ROW_COUNT;
    
    -- tenka_bonus_distributions テーブルを完全クリア（存在する場合）
    DELETE FROM tenka_bonus_distributions WHERE true;
    GET DIAGNOSTICS deleted_tenka_bonus = ROW_COUNT;
    
    RAISE NOTICE '=== COMPLETE DATA CLEAR RESULTS ===';
    RAISE NOTICE 'Deleted daily_rewards records: %', deleted_rewards;
    RAISE NOTICE 'Deleted reward_applications records: %', deleted_applications;
    RAISE NOTICE 'Deleted tenka_bonus_distributions records: %', deleted_tenka_bonus;
    RAISE NOTICE '===================================';
END;
$$;

-- 2. user_nfts テーブルの報酬関連フィールドをリセット
UPDATE user_nfts SET
    total_earned = 0,
    current_investment = price,  -- 投資額を元の価格にリセット
    max_earning = price * 3      -- 300%キャップを再設定
FROM nfts
WHERE user_nfts.nft_id = nfts.id;

-- 3. users テーブルの報酬関連フィールドをリセット（存在する場合）
UPDATE users SET
    total_earned = 0,
    pending_rewards = 0
WHERE total_earned IS NOT NULL OR pending_rewards IS NOT NULL;

-- 4. 週利データも再度確認してクリア
DELETE FROM group_weekly_rates;
DELETE FROM group_weekly_rates_backup WHERE true;

-- 5. 結果確認
SELECT 
    'daily_rewards' as table_name,
    COUNT(*) as record_count,
    COALESCE(SUM(reward_amount), 0) as total_amount
FROM daily_rewards
UNION ALL
SELECT 
    'reward_applications' as table_name,
    COUNT(*) as record_count,
    COALESCE(SUM(reward_amount), 0) as total_amount
FROM reward_applications
UNION ALL
SELECT 
    'group_weekly_rates' as table_name,
    COUNT(*) as record_count,
    COALESCE(SUM(weekly_rate), 0) as total_amount
FROM group_weekly_rates;

-- 6. ユーザーNFT状況確認
SELECT 
    COUNT(*) as total_user_nfts,
    SUM(total_earned) as total_earned_sum,
    AVG(total_earned) as avg_earned
FROM user_nfts;

SELECT 'Complete data clear executed - System should now show $0 rewards' as status;
