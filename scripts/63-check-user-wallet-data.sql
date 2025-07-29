-- ユーザーのウォレットデータを確認
SELECT 
  name,
  user_id,
  email,
  usdt_address,
  wallet_type,
  created_at
FROM users 
WHERE user_id = 'pigret10'
ORDER BY created_at DESC;

-- 全ユーザーのウォレット情報統計
SELECT 
  COUNT(*) as total_users,
  COUNT(usdt_address) as users_with_wallet,
  COUNT(CASE WHEN wallet_type = 'EVO' THEN 1 END) as evo_wallets,
  COUNT(CASE WHEN wallet_type = 'その他' THEN 1 END) as other_wallets
FROM users;

-- ウォレットアドレスが設定されているユーザー一覧（最初の5人）
SELECT 
  name,
  user_id,
  usdt_address,
  wallet_type
FROM users 
WHERE usdt_address IS NOT NULL
LIMIT 5;
