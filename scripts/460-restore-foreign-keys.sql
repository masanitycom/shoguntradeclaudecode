-- 外部キー制約を復元

-- user_nftsテーブルとの関係を復元
ALTER TABLE user_nfts 
ADD CONSTRAINT user_nfts_nft_id_fkey 
FOREIGN KEY (nft_id) REFERENCES nfts(id) ON DELETE CASCADE;

-- nft_purchase_applicationsテーブルとの関係を復元
ALTER TABLE nft_purchase_applications 
ADD CONSTRAINT nft_purchase_applications_nft_id_fkey 
FOREIGN KEY (nft_id) REFERENCES nfts(id) ON DELETE CASCADE;

-- daily_rewardsテーブルとの関係を復元（存在する場合）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_rewards') THEN
        ALTER TABLE daily_rewards 
        ADD CONSTRAINT daily_rewards_nft_id_fkey 
        FOREIGN KEY (nft_id) REFERENCES nfts(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 最終的な整合性チェック
SELECT 
    '🔍 整合性チェック' as section,
    'nfts' as table_name,
    COUNT(*) as record_count
FROM nfts
WHERE is_active = true

UNION ALL

SELECT 
    '🔍 整合性チェック' as section,
    'user_nfts' as table_name,
    COUNT(*) as record_count
FROM user_nfts

UNION ALL

SELECT 
    '🔍 整合性チェック' as section,
    'nft_purchase_applications' as table_name,
    COUNT(*) as record_count
FROM nft_purchase_applications;

-- グループ別週利設定を再確認
SELECT 
    '📊 グループ別週利設定' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as group_name,
    COUNT(*) as nft_count
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;
