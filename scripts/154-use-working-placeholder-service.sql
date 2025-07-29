-- NFT画像のプレースホルダーサービスを修正

-- 1. より確実なプレースホルダーサービスを使用
UPDATE nfts SET image_url = CONCAT(
    'https://picsum.photos/200/200?random=', 
    id::text
) WHERE image_url IS NULL OR image_url = '';

-- 2. 更新結果を確認
SELECT 
    name,
    SUBSTRING(image_url, 1, 50) || '...' as image_url_preview
FROM nfts 
WHERE image_url IS NOT NULL
ORDER BY price::numeric
LIMIT 5;

-- 3. 統計確認
SELECT 
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN image_url IS NOT NULL AND image_url != '' THEN 1 END) as with_valid_images
FROM nfts;

SELECT 'NFT placeholder images updated successfully' as status;
