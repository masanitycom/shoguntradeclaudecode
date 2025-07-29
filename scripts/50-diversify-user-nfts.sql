-- ユーザーNFTの多様化と紹介関係の修正

-- 現在の状況確認
SELECT 'current_nft_distribution' as step;

SELECT 
    n.name,
    n.price,
    COUNT(un.user_id) as user_count
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
GROUP BY n.id, n.name, n.price
ORDER BY n.price;

-- 紹介関係の現状確認
SELECT 'referral_status' as step;

SELECT 
    COUNT(*) as total_users,
    COUNT(referral_code) as users_with_referral_code,
    COUNT(my_referral_code) as users_with_own_code
FROM users 
WHERE is_admin = false;

-- NFTの多様化処理
DO $$
DECLARE
    user_record RECORD;
    nft_options UUID[];
    selected_nft_id UUID;
    random_index INTEGER;
    counter INTEGER := 0;
BEGIN
    -- 利用可能な通常NFTのIDを配列に格納
    SELECT ARRAY(
        SELECT id FROM nfts 
        WHERE is_special = false 
        AND is_active = true 
        ORDER BY price
    ) INTO nft_options;
    
    RAISE NOTICE '利用可能NFT数: %', array_length(nft_options, 1);
    
    -- 各ユーザーのNFTをランダムに変更
    FOR user_record IN 
        SELECT DISTINCT un.user_id, un.id as user_nft_id
        FROM user_nfts un
        JOIN users u ON un.user_id = u.id
        WHERE un.is_active = true 
        AND u.is_admin = false
        ORDER BY RANDOM()
    LOOP
        -- ランダムなNFTを選択
        random_index := floor(random() * array_length(nft_options, 1)) + 1;
        selected_nft_id := nft_options[random_index];
        
        -- NFTを更新
        UPDATE user_nfts 
        SET 
            nft_id = selected_nft_id,
            purchase_price = (SELECT price FROM nfts WHERE id = selected_nft_id),
            current_investment = (SELECT price FROM nfts WHERE id = selected_nft_id),
            max_earning = (SELECT price FROM nfts WHERE id = selected_nft_id) * 3,
            updated_at = NOW()
        WHERE id = user_record.user_nft_id;
        
        counter := counter + 1;
        
        -- 進捗表示
        IF counter % 50 = 0 THEN
            RAISE NOTICE '進捗: % ユーザーのNFTを更新', counter;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ % 人のユーザーNFTを多様化しました', counter;
END
$$;

-- 更新後のNFT分布確認
SELECT 'updated_nft_distribution' as step;

SELECT 
    n.name,
    n.price,
    COUNT(un.user_id) as user_count,
    ROUND(COUNT(un.user_id) * 100.0 / SUM(COUNT(un.user_id)) OVER (), 1) as percentage
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
GROUP BY n.id, n.name, n.price
ORDER BY n.price;

SELECT 'NFT多様化完了' AS result;
