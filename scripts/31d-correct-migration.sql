-- 【修正版】既存ユーザーのマイグレーション
-- 正しいuser_nftsテーブル構造に対応

-- まず、現在の状況を確認
SELECT 'マイグレーション前の状況確認' as step;

-- 総ユーザー数
SELECT 'ユーザー数' as type, COUNT(*) as count FROM users WHERE is_admin = false;

-- 既にNFTを持っているユーザー数
SELECT 'NFT保有済みユーザー数' as type, COUNT(DISTINCT user_id) as count 
FROM user_nfts WHERE is_active = true;

-- NFTを持っていないユーザー数
SELECT 'NFT未保有ユーザー数' as type, COUNT(*) as count 
FROM users u 
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true 
WHERE un.id IS NULL AND u.is_admin = false;

-- 利用可能なNFTを確認
SELECT '利用可能NFT' as type, id, name, price, is_special 
FROM nfts 
WHERE is_active = true 
ORDER BY price;

-- 実際のマイグレーション処理
DO $$
DECLARE
    user_record RECORD;
    default_nft_id UUID;
    default_nft_price DECIMAL(10,2);
    migration_count INTEGER := 0;
    total_users INTEGER;
BEGIN
    -- デフォルトNFTを選択（価格が1000ドルの通常NFTを優先）
    SELECT id, price INTO default_nft_id, default_nft_price
    FROM nfts 
    WHERE price = 1000 
    AND is_special = false 
    AND is_active = true
    LIMIT 1;
    
    -- 1000ドルNFTがない場合は、最も安い通常NFTを選択
    IF default_nft_id IS NULL THEN
        SELECT id, price INTO default_nft_id, default_nft_price
        FROM nfts 
        WHERE is_special = false 
        AND is_active = true
        ORDER BY price ASC
        LIMIT 1;
    END IF;
    
    -- それでもない場合は、最も安いNFTを選択
    IF default_nft_id IS NULL THEN
        SELECT id, price INTO default_nft_id, default_nft_price
        FROM nfts 
        WHERE is_active = true
        ORDER BY price ASC
        LIMIT 1;
    END IF;
    
    IF default_nft_id IS NULL THEN
        RAISE EXCEPTION 'アクティブなNFTが見つかりません。先にNFTを作成してください。';
    END IF;
    
    -- 選択されたNFTの情報を表示
    RAISE NOTICE '選択されたデフォルトNFT: % ($%)', (
        SELECT name FROM nfts WHERE id = default_nft_id
    ), default_nft_price;
    
    -- NFTを持っていないユーザーの総数を取得
    SELECT COUNT(*) INTO total_users
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    WHERE un.id IS NULL AND u.is_admin = false;
    
    RAISE NOTICE 'マイグレーション対象ユーザー数: %', total_users;
    
    -- 既存ユーザーでuser_nftsにレコードがないユーザーを処理
    FOR user_record IN 
        SELECT u.id, u.user_id, u.name, u.email
        FROM users u
        LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
        WHERE un.id IS NULL  -- NFTを持っていないユーザー
        AND u.is_admin = false  -- 管理者以外
        ORDER BY u.created_at ASC  -- 古いユーザーから順番に
    LOOP
        -- 正しいカラム名でNFTを付与
        INSERT INTO user_nfts (
            user_id,
            nft_id,
            purchase_price,
            current_investment,
            total_earned,
            max_earning,
            is_active,
            purchase_date,
            operation_start_date,
            created_at,
            updated_at
        ) VALUES (
            user_record.id,
            default_nft_id,
            default_nft_price,  -- purchase_price
            default_nft_price,  -- current_investment
            0.00,               -- total_earned（0からスタート）
            default_nft_price * 3,  -- max_earning（300%）
            true,               -- is_active
            CURRENT_DATE - INTERVAL '30 days',  -- purchase_date（30日前）
            CURRENT_DATE - INTERVAL '23 days',  -- operation_start_date（1週間後から運用開始）
            NOW(),              -- created_at
            NOW()               -- updated_at
        );
        
        migration_count := migration_count + 1;
        
        -- 進捗表示（50人ごと）
        IF migration_count % 50 = 0 THEN
            RAISE NOTICE '進捗: % / % 人完了 (%.1f%%)', 
                migration_count, 
                total_users, 
                (migration_count::DECIMAL / total_users * 100);
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ マイグレーション完了: % 人のユーザーにデフォルトNFTを付与しました', migration_count;
END
$$;

-- マイグレーション結果の確認
SELECT 'マイグレーション後の状況確認' as step;

-- 総ユーザー数（変更なし）
SELECT 'ユーザー数' as type, COUNT(*) as count FROM users WHERE is_admin = false;

-- NFT保有ユーザー数（増加しているはず）
SELECT 'NFT保有済みユーザー数' as type, COUNT(DISTINCT user_id) as count 
FROM user_nfts WHERE is_active = true;

-- NFTを持っていないユーザー数（0になっているはず）
SELECT 'NFT未保有ユーザー数' as type, COUNT(*) as count 
FROM users u 
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true 
WHERE un.id IS NULL AND u.is_admin = false;

-- NFT別の保有者数
SELECT 
    'NFT別保有者数' as type,
    n.name,
    n.price,
    COUNT(un.user_id) as holder_count
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
GROUP BY n.id, n.name, n.price
ORDER BY n.price;

-- 投資総額の確認
SELECT 
    '投資総額確認' as type,
    SUM(current_investment) as total_investment,
    SUM(total_earned) as total_earned,
    SUM(max_earning) as total_max_earning
FROM user_nfts 
WHERE is_active = true;

-- 完了メッセージ
SELECT '既存ユーザーマイグレーション完了 - 全ユーザーがNFTを保有しました' as result;
