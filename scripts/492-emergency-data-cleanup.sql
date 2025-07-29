-- 🚨 緊急データクリーンアップ - 不正な利益データを全削除

-- 1. 現在の不正データ状況を記録（削除前のバックアップ）
CREATE TABLE IF NOT EXISTS emergency_cleanup_backup_20250704 AS
SELECT 
    'daily_rewards_backup' as table_name,
    dr.*,
    u.name as user_name,
    n.name as nft_name,
    NOW() as backup_created_at
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON dr.nft_id = n.id;

-- 2. user_nfts の不正な total_earned もバックアップ
INSERT INTO emergency_cleanup_backup_20250704
SELECT 
    'user_nfts_backup' as table_name,
    un.id::uuid as id,
    un.user_id,
    un.nft_id,
    NULL::date as reward_date,
    NULL::numeric as daily_rate,
    un.total_earned as reward_amount,
    NULL::date as week_start_date,
    un.current_investment as investment_amount,
    NULL::date as calculation_date,
    NULL::jsonb as calculation_details,
    NULL::boolean as is_claimed,
    un.created_at,
    un.updated_at,
    u.name as user_name,
    n.name as nft_name,
    NOW() as backup_created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.total_earned > 0;

-- 3. 削除前の状況確認
SELECT 
    '🚨 削除前の状況確認' as section,
    'daily_rewards: ' || COUNT(*) || '件、総額$' || SUM(reward_amount) as daily_rewards_status
FROM daily_rewards
UNION ALL
SELECT 
    '🚨 削除前の状況確認' as section,
    'user_nfts with earnings: ' || COUNT(*) || '件、総額$' || SUM(total_earned) as user_nfts_status
FROM user_nfts WHERE total_earned > 0;

-- 4. 不正な daily_rewards データを全削除
DELETE FROM daily_rewards;

-- 5. user_nfts の total_earned をリセット
UPDATE user_nfts 
SET 
    total_earned = 0,
    updated_at = NOW()
WHERE total_earned > 0;

-- 6. 削除後の確認
SELECT 
    '✅ クリーンアップ完了' as section,
    'daily_rewards: ' || COUNT(*) || '件' as daily_rewards_after,
    'user_nfts with earnings: ' || (SELECT COUNT(*) FROM user_nfts WHERE total_earned > 0) || '件' as user_nfts_after
FROM daily_rewards;

-- 7. バックアップ確認
SELECT 
    '💾 バックアップ確認' as section,
    table_name,
    COUNT(*) as backup_records,
    SUM(reward_amount) as backup_total_amount
FROM emergency_cleanup_backup_20250704
GROUP BY table_name;
