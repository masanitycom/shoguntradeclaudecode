-- nftsテーブルの詳細構造を確認
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'nfts' 
ORDER BY ordinal_position;

-- nftsテーブルの制約を確認
SELECT 
  constraint_name,
  constraint_type,
  column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu 
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'nfts';

-- 実際のnftsテーブルのデータを直接確認（最初の5件）
SELECT 
    id,
    name,
    price,
    image_url,
    is_special,
    is_active,
    created_at
FROM nfts 
ORDER BY created_at DESC 
LIMIT 5;

-- image_urlカラムが存在するかどうかを確認
SELECT EXISTS (
  SELECT 1 
  FROM information_schema.columns 
  WHERE table_name = 'nfts' 
  AND column_name = 'image_url'
) as image_url_column_exists;

-- image_urlカラムの統計
SELECT 
    COUNT(*) as total_nfts,
    COUNT(image_url) as nfts_with_image_url,
    COUNT(*) - COUNT(image_url) as nfts_without_image_url,
    COUNT(CASE WHEN image_url IS NOT NULL AND image_url != '' THEN 1 END) as nfts_with_valid_image_url
FROM nfts;

-- RLSポリシーを確認
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'nfts';
