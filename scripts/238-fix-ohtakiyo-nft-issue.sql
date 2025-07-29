-- オオタキヨジにSHOGUN NFT 10000を付与

-- 1. まずSHOGUN NFT 10000のIDを確認
DO $$
DECLARE
    shogun_nft_id UUID;
    user_id UUID := 'd8c1b7a2-20ea-4991-a296-00a090a36e41';
BEGIN
    -- SHOGUN NFT 10000のIDを取得
    SELECT id INTO shogun_nft_id 
    FROM nfts 
    WHERE name LIKE '%SHOGUN%' 
    AND price = 10000 
    LIMIT 1;
    
    IF shogun_nft_id IS NULL THEN
        RAISE NOTICE 'SHOGUN NFT 10000が見つかりません';
        RETURN;
    END IF;
    
    RAISE NOTICE 'SHOGUN NFT 10000 ID: %', shogun_nft_id;
    
    -- 既存のuser_nftsレコードがあるかチェック
    IF EXISTS (
        SELECT 1 FROM user_nfts 
        WHERE user_id = user_id 
        AND nft_id = shogun_nft_id
    ) THEN
        -- 既存レコードをアクティブにする
        UPDATE user_nfts 
        SET is_active = true,
            updated_at = NOW()
        WHERE user_id = user_id 
        AND nft_id = shogun_nft_id;
        
        RAISE NOTICE 'オオタキヨジの既存SHOGUN NFT 10000をアクティブにしました';
    ELSE
        -- 新しいレコードを作成
        INSERT INTO user_nfts (
            id,
            user_id,
            nft_id,
            current_investment,
            total_earned,
            max_earning,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            user_id,
            shogun_nft_id,
            10000.00,  -- current_investment
            0.00,      -- total_earned
            30000.00,  -- max_earning (300%キャップ)
            true,      -- is_active
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'オオタキヨジに新しいSHOGUN NFT 10000を付与しました';
    END IF;
END $$;

-- 2. 結果を確認
SELECT 
    'Verification' as check_type,
    u.name as user_name,
    n.name as nft_name,
    n.price as nft_price,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    un.created_at
FROM user_nfts un
JOIN users u ON u.id = un.user_id
JOIN nfts n ON n.id = un.nft_id
WHERE u.email = 'kiyoji1948@gmail.com'
AND un.is_active = true;
