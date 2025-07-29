-- image_urlカラムが存在しない場合のみ追加

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'nfts' AND column_name = 'image_url'
  ) THEN
    ALTER TABLE nfts ADD COLUMN image_url TEXT;
    RAISE NOTICE 'image_urlカラムを追加しました';
  ELSE
    RAISE NOTICE 'image_urlカラムは既に存在します';
  END IF;
END $$;

-- 確認
SELECT 'image_url column added successfully' as result;
