-- NFTsテーブルの詳細構造確認

SELECT '=== NFTs テーブル構造確認 ===' as section;

-- nftsテーブルの詳細構造
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== NFTs テーブルのサンプルデータ ===' as section;

-- nftsテーブルの実際のデータ確認
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    description,
    is_active,
    is_special,
    created_at,
    -- 画像関連のカラムがあるかチェック
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'nfts' 
            AND column_name IN ('image_url', 'image_path', 'image', 'thumbnail_url')
        ) 
        THEN '画像カラムあり' 
        ELSE '画像カラムなし' 
    END as image_status
FROM nfts 
ORDER BY price ASC;

SELECT '=== 画像関連カラムの詳細確認 ===' as section;

-- 画像関連のカラムがあるかチェック
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
AND column_name ILIKE '%image%'
ORDER BY ordinal_position;

SELECT '=== NFT統計情報 ===' as section;

-- NFT統計
SELECT 
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN is_special = true THEN 1 END) as special_nfts,
    COUNT(CASE WHEN is_special = false THEN 1 END) as normal_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
    MIN(price) as min_price,
    MAX(price) as max_price,
    AVG(price) as avg_price
FROM nfts;
