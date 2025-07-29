-- 全NFTにデフォルト画像URLを設定

UPDATE nfts 
SET image_url = '/placeholder.svg?height=200&width=200&text=' || REPLACE(name, ' ', '+')
WHERE image_url IS NULL;

-- 確認
SELECT 
  COUNT(*) as total_updated,
  COUNT(CASE WHEN image_url IS NOT NULL THEN 1 END) as now_with_images
FROM nfts;

-- サンプル確認（3件）
SELECT name, 
  CASE 
    WHEN LENGTH(image_url) > 50 THEN LEFT(image_url, 50) || '...'
    ELSE image_url 
  END as image_url_preview
FROM nfts 
ORDER BY price::numeric 
LIMIT 3;
