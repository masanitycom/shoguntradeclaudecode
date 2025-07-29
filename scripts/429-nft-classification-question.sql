-- NFTの分類方法を確認するための質問

-- 現在の状況を表示
SELECT 
    '❓ 分類方法の確認' as question,
    '現在28個のNFTがあります。どのように分類しますか？' as message;

-- 現在の日利上限の種類
SELECT 
    '📊 現在の日利上限の種類' as current_rates,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 全NFTの名前と価格と現在の日利上限
SELECT 
    '📋 全NFTの現在の設定' as current_settings,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special
FROM nfts
WHERE is_active = true
ORDER BY price;

-- 質問
SELECT 
    '❓ 質問' as question_section,
    'どのNFTをどの日利上限にしたいですか？' as question1,
    '価格帯ではないとのことですが、何を基準に分類しますか？' as question2,
    'NFT名で指定しますか？' as question3,
    '特別NFTと通常NFTで分けますか？' as question4,
    'それとも別の基準がありますか？' as question5;
