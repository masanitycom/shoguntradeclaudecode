-- SHOGUN NFT 1200を追加
-- 価格: $1,200
-- 日利上限: 1.0%
-- 種別: 通常NFT

INSERT INTO nfts (
    name,
    price,
    daily_rate_limit,
    description,
    image_url,
    is_active,
    is_special,
    created_at,
    updated_at
) VALUES (
    'SHOGUN NFT 1200',
    1200.00,
    1.0,  -- 1.0%の日利上限
    'SHOGUN TRADE 1200ドルNFT - 安定した収益を提供する中級者向けNFT',
    NULL,  -- 画像は後で管理画面から設定可能
    true,  -- アクティブ
    false, -- 通常NFT（特別NFTではない）
    NOW(),
    NOW()
);

-- 追加されたNFTを確認
SELECT 
    name,
    price,
    daily_rate_limit,
    is_special,
    is_active,
    created_at
FROM nfts 
WHERE name = 'SHOGUN NFT 1200';

-- 全NFTの価格順一覧を表示
SELECT 
    name,
    price,
    daily_rate_limit || '%' as daily_rate,
    CASE 
        WHEN is_special THEN '特別NFT'
        ELSE '通常NFT'
    END as type,
    CASE 
        WHEN is_active THEN 'アクティブ'
        ELSE '非アクティブ'
    END as status
FROM nfts 
ORDER BY price ASC;

-- 完了メッセージ
SELECT '✅ SHOGUN NFT 1200 (価格: $1,200, 日利上限: 1.0%) を追加しました' AS result;
