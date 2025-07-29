-- 特別NFT「SHOGUN NFT 1000 (Special)」を追加
INSERT INTO nfts (
  name,
  price,
  daily_rate_limit,
  description,
  is_active,
  is_special,
  created_at,
  updated_at
) VALUES (
  'SHOGUN NFT 1000 (Special)',
  1000,
  1.25,
  '管理者付与専用の特別NFT - 日利上限1.25%',
  true,
  true,
  NOW(),
  NOW()
);

-- 作成されたNFTを確認
SELECT 
  id,
  name,
  price,
  daily_rate_limit,
  is_special,
  is_active,
  created_at
FROM nfts 
WHERE name LIKE '%Special%'
ORDER BY created_at DESC;
