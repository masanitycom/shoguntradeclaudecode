-- 🔧 NFT運用開始日の修復

-- 1. purchase_dateカラムが存在しない場合は追加
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'purchase_date'
    ) THEN
        ALTER TABLE user_nfts ADD COLUMN purchase_date DATE;
        RAISE NOTICE 'purchase_dateカラムを追加しました';
    END IF;
END $$;

-- 2. 既存のNFTにpurchase_dateを設定（created_atから）
UPDATE user_nfts 
SET purchase_date = created_at::DATE,
    updated_at = NOW()
WHERE purchase_date IS NULL 
AND created_at IS NOT NULL;

-- 3. created_atがNULLの場合は現在日付を設定
UPDATE user_nfts 
SET created_at = NOW(),
    purchase_date = CURRENT_DATE,
    updated_at = NOW()
WHERE created_at IS NULL;

-- 4. current_investmentがNULLまたは0の場合、NFT価格を設定
UPDATE user_nfts 
SET current_investment = n.price,
    updated_at = NOW()
FROM nfts n
WHERE user_nfts.nft_id = n.id
AND (user_nfts.current_investment IS NULL OR user_nfts.current_investment = 0);

-- 5. max_earningが設定されていない場合、300%ルールで設定
UPDATE user_nfts 
SET max_earning = n.price * 3,
    updated_at = NOW()
FROM nfts n
WHERE user_nfts.nft_id = n.id
AND (user_nfts.max_earning IS NULL OR user_nfts.max_earning = 0);

-- 6. 修復結果の確認
SELECT 
    '=== 修復結果確認 ===' as section,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN purchase_date IS NOT NULL THEN 1 END) as nfts_with_purchase_date,
    COUNT(CASE WHEN current_investment > 0 THEN 1 END) as nfts_with_investment,
    COUNT(CASE WHEN max_earning > 0 THEN 1 END) as nfts_with_max_earning,
    MIN(purchase_date) as earliest_purchase,
    MAX(purchase_date) as latest_purchase
FROM user_nfts 
WHERE is_active = true;

SELECT '🔧 NFT運用開始日修復完了' as status;
