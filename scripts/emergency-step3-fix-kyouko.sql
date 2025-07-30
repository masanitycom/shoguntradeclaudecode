-- 緊急修復 Step 3: kyouko194045@gmail.com の修復
-- 投資額$100のユーザー

BEGIN;

-- Step 1: 関連データのuser_id更新
UPDATE user_nfts 
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- 日利報酬データ更新
UPDATE daily_rewards
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'  
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- NFT購入申請データ更新
UPDATE nft_purchase_applications
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- 報酬申請データ更新
UPDATE reward_applications  
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- 紹介関係の更新
UPDATE users
SET referrer_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE referrer_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- Step 2: 古いレコード削除
DELETE FROM users WHERE id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- Step 3: 新しいレコード作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'cf1d3983-6325-4d60-a15d-4677c08b0859',
    'ハセガワキョウコ',
    'kyouko194045@gmail.com',
    'Kyoko001', 
    NULL,
    NULL,
    NULL,
    'その他',
    false,
    'Kyoko001',
    'https://shogun-trade.vercel.app/register?ref=Kyoko001',
    NOW(),
    NOW()
);

COMMIT;

-- 修復検証
SELECT 'KYOUKO REPAIR VERIFICATION' as status;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED' ELSE 'ERROR' END as sync_status,
    pu.name,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'kyouko194045@gmail.com';