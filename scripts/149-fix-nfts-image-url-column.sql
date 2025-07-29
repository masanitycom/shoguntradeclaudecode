-- image_urlカラムが存在しない場合は追加
DO $$ 
BEGIN
    -- image_urlカラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nfts' AND column_name = 'image_url'
    ) THEN
        -- image_urlカラムを追加
        ALTER TABLE nfts ADD COLUMN image_url TEXT;
        RAISE NOTICE 'image_urlカラムを追加しました';
    ELSE
        RAISE NOTICE 'image_urlカラムは既に存在します';
    END IF;
END $$;

-- テスト用のプレースホルダー画像URLを設定
UPDATE nfts 
SET image_url = '/placeholder.svg?height=200&width=200&query=' || REPLACE(name, ' ', '+')
WHERE image_url IS NULL OR image_url = '';

-- 更新結果を確認
SELECT 
    name,
    price,
    image_url,
    CASE 
        WHEN image_url IS NOT NULL AND image_url != '' THEN '画像URL設定済み'
        ELSE '画像URLなし'
    END as image_status
FROM nfts 
ORDER BY price::numeric;

-- 統計情報を再確認
SELECT 
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN image_url IS NOT NULL AND image_url != '' THEN 1 END) as nfts_with_image_url,
    COUNT(CASE WHEN image_url IS NULL OR image_url = '' THEN 1 END) as nfts_without_image_url
FROM nfts;
