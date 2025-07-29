-- 🚨 緊急データクリーンアップ - 修正版（一発で成功）

-- 1. バックアップテーブルを正しい構造で作成
DROP TABLE IF EXISTS emergency_cleanup_backup_20250704;
CREATE TABLE emergency_cleanup_backup_20250704 (
    backup_type TEXT,
    record_id UUID,
    user_id UUID,
    user_name TEXT,
    nft_id UUID,
    nft_name TEXT,
    amount NUMERIC,
    reward_date DATE,
    created_at TIMESTAMPTZ,
    backup_created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. daily_rewards データをバックアップ
INSERT INTO emergency_cleanup_backup_20250704 
    (backup_type, record_id, user_id, user_name, nft_id, nft_name, amount, reward_date, created_at)
SELECT 
    'daily_rewards' as backup_type,
    dr.id as record_id,
    dr.user_id,
    u.name as user_name,
    dr.nft_id,
    n.name as nft_name,
    dr.reward_amount as amount,
    dr.reward_date,
    dr.created_at
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON dr.nft_id = n.id;

-- 3. user_nfts の total_earned データをバックアップ
INSERT INTO emergency_cleanup_backup_20250704 
    (backup_type, record_id, user_id, user_name, nft_id, nft_name, amount, created_at)
SELECT 
    'user_nfts_earnings' as backup_type,
    un.id as record_id,
    un.user_id,
    u.name as user_name,
    un.nft_id,
    n.name as nft_name,
    un.total_earned as amount,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.total_earned > 0;

-- 4. 削除前の状況確認
SELECT 
    '🚨 削除前確認' as status,
    (SELECT COUNT(*) FROM daily_rewards) as daily_rewards_count,
    (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards) as daily_rewards_total,
    (SELECT COUNT(*) FROM user_nfts WHERE total_earned > 0) as user_nfts_with_earnings,
    (SELECT COALESCE(SUM(total_earned), 0) FROM user_nfts WHERE total_earned > 0) as user_nfts_earnings_total;

-- 5. 🚨 不正データを全削除
DELETE FROM daily_rewards;

-- 6. user_nfts の total_earned をリセット
UPDATE user_nfts 
SET 
    total_earned = 0,
    updated_at = NOW()
WHERE total_earned > 0;

-- 7. ✅ クリーンアップ完了確認
SELECT 
    '✅ クリーンアップ完了' as status,
    (SELECT COUNT(*) FROM daily_rewards) as daily_rewards_count,
    (SELECT COUNT(*) FROM user_nfts WHERE total_earned > 0) as user_nfts_with_earnings,
    (SELECT COUNT(*) FROM emergency_cleanup_backup_20250704) as backup_records_count,
    (SELECT SUM(amount) FROM emergency_cleanup_backup_20250704) as backup_total_amount;

-- 8. バックアップ詳細
SELECT 
    '💾 バックアップ詳細' as section,
    backup_type,
    COUNT(*) as records,
    SUM(amount) as total_amount
FROM emergency_cleanup_backup_20250704
GROUP BY backup_type;
