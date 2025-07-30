-- 最終シンプル修正: 1つずつ確実に実行

-- Part 1: サトウチヨコ002を別の場所に移動
BEGIN;

-- 1. サトウチヨコ002用の新レコード作成（一意のuser_id使用）
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    'サトウチヨコ002',
    'phu55papa@gmail.com',
    'NYANKO002',  -- 一意にするため変更
    '09012345678',
    '8281b9aa-1c9e-4446-bc1f-dbaec25821ec',
    NULL,
    'その他',
    false,
    'NYANKO002',
    'https://shogun-trade.vercel.app/register?ref=NYANKO002',
    '2025-06-24 07:37:49.967+00',
    NOW()
);

-- 2. サトウチヨコ002のNFTデータを新IDに移動
UPDATE user_nfts 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 3. 関連データも移動
UPDATE daily_rewards SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';
UPDATE nft_purchase_applications SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';
UPDATE reward_applications SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 4. 紹介関係の更新
UPDATE users SET referrer_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 5. 古いサトウチヨコ002レコード削除
DELETE FROM users WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

COMMIT;

SELECT 'Part 1 completed: Sato moved to new location' as status;