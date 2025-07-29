-- NFTの画像URL状況を確認
SELECT 
  name,
  price,
  image_url,
  CASE 
    WHEN image_url IS NULL THEN '画像なし'
    WHEN image_url = '' THEN '空文字'
    ELSE '画像あり'
  END as image_status,
  is_special,
  is_active
FROM nfts 
ORDER BY price;

-- 画像URLが設定されているNFTの数
SELECT 
  COUNT(*) as total_nfts,
  COUNT(image_url) as nfts_with_image_url,
  COUNT(*) - COUNT(image_url) as nfts_without_image_url
FROM nfts;
