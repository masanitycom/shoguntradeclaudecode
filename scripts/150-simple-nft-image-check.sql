-- 簡潔なNFT画像調査（結果を短くするため）

-- 1. image_urlカラムの存在確認
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns 
  WHERE table_name = 'nfts' AND column_name = 'image_url'
) as has_image_url_column;

-- 2. NFTテーブルの基本構造（重要カラムのみ）
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND column_name IN ('id', 'name', 'image_url', 'price', 'is_active')
ORDER BY column_name;

-- 3. 画像URL統計（簡潔版）
SELECT 
  COUNT(*) as total_nfts,
  COUNT(image_url) as with_image_url,
  COUNT(*) - COUNT(image_url) as without_image_url
FROM nfts;

-- 4. サンプルデータ（3件のみ）
SELECT name, price, 
  CASE 
    WHEN image_url IS NULL THEN 'NULL'
    WHEN image_url = '' THEN 'EMPTY'
    ELSE 'HAS_URL'
  END as image_status
FROM nfts 
ORDER BY price::numeric 
LIMIT 3;
