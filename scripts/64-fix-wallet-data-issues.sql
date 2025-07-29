-- 1. wallet_typeの値を統一（"other" → "その他"）
UPDATE users 
SET wallet_type = 'その他' 
WHERE wallet_type = 'other';

-- 2. 不正なウォレットアドレスを確認
SELECT 
  name,
  user_id,
  usdt_address,
  LENGTH(usdt_address) as address_length,
  CASE 
    WHEN usdt_address ~ '^0x[a-fA-F0-9]{40}$' THEN 'Valid ETH/BEP20'
    WHEN usdt_address ~ '^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$' THEN 'Valid BTC'
    ELSE 'Invalid'
  END as address_status
FROM users 
WHERE usdt_address IS NOT NULL;

-- 3. 修正後の統計を確認
SELECT 
  COUNT(*) as total_users,
  COUNT(usdt_address) as users_with_wallet,
  COUNT(CASE WHEN wallet_type = 'EVO' THEN 1 END) as evo_wallets,
  COUNT(CASE WHEN wallet_type = 'その他' THEN 1 END) as other_wallets,
  COUNT(CASE WHEN usdt_address IS NULL THEN 1 END) as users_without_wallet
FROM users;
