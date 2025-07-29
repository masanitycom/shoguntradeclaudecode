-- より確実なプレースホルダー画像URLに更新
UPDATE nfts 
SET image_url = 'https://via.placeholder.com/200x200/374151/ffffff?text=' || REPLACE(REPLACE(name, ' ', '+'), 'NFT', 'NFT')
WHERE image_url LIKE '/placeholder.svg%';

-- 確認
SELECT 
  name,
  CASE 
    WHEN LENGTH(image_url) > 60 THEN LEFT(image_url, 60) || '...'
    ELSE image_url 
  END as image_url_preview
FROM nfts 
ORDER BY price::numeric 
LIMIT 5;

-- 統計確認
SELECT 
  COUNT(*) as total_nfts,
  COUNT(CASE WHEN image_url IS NOT NULL AND image_url != '' THEN 1 END) as with_valid_images
FROM nfts;
